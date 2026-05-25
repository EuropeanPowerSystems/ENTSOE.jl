# Hand-written, named-argument convenience wrappers around the most
# heavily used generated query functions.
#
# Why these exist:
#
#   1. Codes pre-filled. The generated wrappers take `documentType`,
#      `processType`, etc. as raw strings — every caller has to remember
#      that day-ahead prices are `A44`, that "Realised" is `A16`, …. Each
#      function below pre-fills the constants of its operation, so users
#      don't need to.
#
#   2. Friendly date arguments. The generated layer accepts `period_start
#      :: Int64` only (yyyymmddHHMM). Each wrapper accepts any of
#      `DateTime`, `Date`, `ZonedDateTime`, or a raw `Integer` and
#      normalises via `entsoe_period`.
#
#   3. Acknowledgement detection. ENTSO-E returns a 200 with an
#      `<Acknowledgement_MarketDocument>` when there is no data; that
#      gets re-raised as an [`ENTSOEAcknowledgement`](@ref) (see
#      [`check_acknowledgement`](@ref)).
#
#   4. Format dispatch. Every wrapper accepts an optional trailing
#      [`ResponseFormat`](@ref) argument that picks the return shape:
#      [`Parsed()`](@ref) (the default) returns a typed `StructVector`
#      from the matching parser; [`Raw()`](@ref) returns the raw XML
#      `String`. Two methods, two return types — fully type-stable, no
#      `Union` widening.
#
# These wrappers live entirely outside `src/api/`, so re-running
# `gen/regenerate.jl` against a refreshed spec leaves them untouched.

using Dates: Dates, DateTime, Date, Period, Year
using TimeZones: TimeZones, ZonedDateTime, astimezone, @tz_str

"""
    ResponseFormat

Tag type that selects the return shape of every wrapper. Subtypes:
[`Parsed`](@ref) (the default — a typed `StructVector` from the matching
parser) and [`Raw`](@ref) (the raw `application/xml` `String`).

Pass an instance as the **last positional argument** to any wrapper:

```julia
prices_xml = day_ahead_prices(client, EIC.NL, t1, t2, Raw())     # ::String
prices     = day_ahead_prices(client, EIC.NL, t1, t2)            # ::StructVector
prices2    = day_ahead_prices(client, EIC.NL, t1, t2, Parsed())  # explicit
```
"""
abstract type ResponseFormat end

"""
    Parsed() <: ResponseFormat

Default response format — wrappers return a `StructVector` produced by
the matching parser (`parse_timeseries` for time-series documents,
`parse_installed_capacity` for capacity documents, …).
"""
struct Parsed <: ResponseFormat end

"""
    Raw() <: ResponseFormat

Pass as the trailing positional argument to any wrapper to skip parsing
and return the raw `application/xml` payload as a `String`. Useful for
debugging or for endpoints whose XML shape isn't covered by our parsers.
"""
struct Raw <: ResponseFormat end

"""
    LocalTime(tz) <: ResponseFormat
    LocalTime("Europe/Amsterdam")

Like [`Parsed()`](@ref) but converts the `time` column from UTC
`DateTime` to timezone-aware `ZonedDateTime` in `tz`. Mirrors entsoe-py's
`query_*_local` variants — useful when porting analyses that expect
local-time stamps.

```julia
prices_local = day_ahead_prices(client, EIC.NL, t1, t2,
    LocalTime("Europe/Amsterdam"))
prices_local[1].time   # ZonedDateTime in CET/CEST
```

Pass either a `TimeZones.TimeZone` instance or a string accepted by
`TimeZone(::String)`. For documents that don't carry a `time` column
(e.g. installed-capacity snapshots), `LocalTime` is a no-op and
returns the same shape as `Parsed()`.
"""
struct LocalTime <: ResponseFormat
    tz::TimeZones.TimeZone
end
LocalTime(tz::AbstractString) = LocalTime(
    TimeZones.TimeZone(
        String(tz),
        TimeZones.Class(:STANDARD) | TimeZones.Class(:LEGACY) |
            TimeZones.Class(:FIXED),
    ),
)

# Internal: normalise any of the accepted period inputs to the Int64
# yyyymmddHHMM expected by the generated layer. Identity for already-
# integer inputs.
_to_period(t::Integer)::Int64 = Int64(t)
_to_period(t::DateTime)::Int64 = entsoe_period(t)
_to_period(t::Date)::Int64 = entsoe_period(t)
_to_period(t::Dates.AbstractDateTime)::Int64 = entsoe_period(t)
# Catch-all: lets JET infer `_to_period(::Any) -> Int64` even though the
# wrapper signatures take `period_start::Any`. At runtime an unsupported
# type errors loudly here rather than silently propagating into the
# generated function as a mistyped `Int64` argument.
_to_period(t)::Int64 = throw(
    ArgumentError(
        "unsupported period type $(typeof(t)) — pass DateTime, Date, " *
            "ZonedDateTime, or an Int64 yyyymmddHHMM."
    )
)

# Internal: do the API call, surface HTTP errors as typed APIErrors,
# raise acknowledgement documents, return the raw XML body. Always
# returns `String` — used by both `Parsed()` and `Raw()` paths.
function _query_xml(
        api_call::Function;
        validate::Bool = false,
        eics = (),
        check_ack::Bool = true,
    )::String
    if validate
        for code in eics
            validate_eic(code; type = :BZN)
        end
    end
    xml, resp = api_call()
    # The OpenAPI client unconditionally sets `:throw => false` on the
    # underlying HTTP options, so non-2xx responses come back as
    # `(nothing, ApiResponse)` rather than throwing. Surface them as
    # the appropriate typed `APIError` here so callers don't see a
    # downstream `MethodError: check_acknowledgement(::Nothing)`.
    if xml === nothing
        raw = resp === nothing ? nothing : resp.raw
        if raw === nothing
            throw(
                NetworkError(
                    ErrorException(
                        "ENTSO-E request failed before a response was received",
                    )
                )
            )
        end
        body = String(copy(raw.body))
        headers = Dict{String, String}(string(k) => string(v) for (k, v) in raw.headers)
        check_response(raw.status, body, headers)
        # 2xx with no body / unparsable body — shouldn't happen, but
        # don't silently return `nothing`.
        throw(ServerError(Int(raw.status), body))
    end
    # Skip the acknowledgement check when the caller knows the body may
    # be binary (e.g. application/zip from balancing endpoints) —
    # `parsexml` would throw on the ZIP magic bytes. The zip-aware
    # wrappers run the check per-member after unzipping.
    check_ack && check_acknowledgement(xml)
    return xml
end

# Sniff the 4-byte ZIP local-file-header magic. ENTSO-E serves zip
# bodies on the balancing 17.1.x family and (less consistently) on
# outages and master-data when there are many notices to deliver.
_looks_like_zip(s::AbstractString) =
let cu = codeunits(s)
    length(cu) >= 4 &&
        cu[1] == 0x50 && cu[2] == 0x4B &&
        cu[3] == 0x03 && cu[4] == 0x04
end

# Internal dispatch on `ResponseFormat`. Two methods, each with a
# concrete return type — that's what makes the public wrappers
# type-stable. Both transparently unzip `application/zip` bodies:
# for `Parsed()`, every zip member is parsed individually and the
# StructVectors `vcat`-ed; for `Raw()`, members are concatenated with a
# `<!-- next zip member -->` sentinel.
# Parse one response body (zip-aware) into rows. Raises ENTSOEAcknowledgement
# if the body — or any zip member — is an acknowledgement document.
function _parse_one(xml::AbstractString, parser::F) where {F <: Function}
    if _looks_like_zip(xml)
        members = unzip_response(Vector{UInt8}(codeunits(xml)))
        isempty(members) && return parser("")
        parts = map(members) do (_name, bytes)
            inner = String(copy(bytes))
            check_acknowledgement(inner)
            parser(inner)
        end
        return reduce(vcat, parts)
    end
    check_acknowledgement(xml)
    return parser(xml)
end

# Raw escape hatch for one response body (zip-aware). Raises on acknowledgement.
function _raw_one(xml::AbstractString)
    if _looks_like_zip(xml)
        members = unzip_response(Vector{UInt8}(codeunits(xml)))
        return join(
            (String(copy(b)) for (_n, b) in members),
            "\n<!-- next zip member -->\n",
        )
    end
    check_acknowledgement(xml)
    return xml
end

function _query(api_call::Function, ::Parsed, parser::F; kw...) where {F <: Function}
    xml = _query_xml(api_call; check_ack = false, kw...)
    return _parse_one(xml, parser)
end

function _query(api_call::Function, fmt::LocalTime, parser::F; kw...) where {F <: Function}
    rows = _query(api_call, Parsed(), parser; kw...)
    return _to_local_time(rows, fmt.tz)
end

function _query(api_call::Function, ::Raw, ::F; kw...) where {F <: Function}
    xml = _query_xml(api_call; check_ack = false, kw...)
    return _raw_one(xml)
end

# Convert the `time` column of a StructVector from naive UTC DateTime
# to timezone-aware ZonedDateTime. Returns the input unchanged if the
# row shape doesn't include a `time::Vector{DateTime}` column.
function _to_local_time(rows, tz::TimeZones.TimeZone)
    :time in propertynames(rows) || return rows
    times = rows.time
    times isa AbstractVector{DateTime} || return rows
    zoned = ZonedDateTime[astimezone(ZonedDateTime(t, tz"UTC"), tz) for t in times]
    cols = (k => k === :time ? zoned : getproperty(rows, k) for k in propertynames(rows))
    return StructArrays.StructArray(NamedTuple(cols))
end

"""
    _split_query(api_call, format, parser;
                 period_start, period_end, window, validate=false, eics=())

Split `[period_start, period_end)` into `window`-sized chunks, call
`api_call(s::Int64, e::Int64)` per chunk (period bounds as `yyyymmddHHMM`),
and concatenate. A chunk that comes back as an acknowledgement ("no matching
data") is skipped; if every chunk is empty the acknowledgement is re-raised.
`Parsed`/`LocalTime` results are `vcat`-ed; `Raw` bodies are joined with a
`<!-- next window -->` sentinel.
"""
function _split_query(
        api_call::Function, format::ResponseFormat, parser::F;
        period_start, period_end, window::Period,
        validate::Bool = false, eics = (),
    ) where {F <: Function}
    if validate
        for code in eics
            validate_eic(code; type = :BZN)
        end
    end
    chunks = split_period(period_start, period_end; window = window)
    isempty(chunks) &&
        throw(ArgumentError("empty period: period_start == period_end"))

    fetch_xml(s, e) = _query_xml(
        () -> api_call(_to_period(s), _to_period(e)); check_ack = false,
    )

    if format isa Raw
        parts = String[]
        last_ack = nothing
        for (s, e) in chunks
            try
                push!(parts, _raw_one(fetch_xml(s, e)))
            catch err
                err isa ENTSOEAcknowledgement || rethrow()
                last_ack = err
            end
        end
        isempty(parts) && throw(last_ack)
        return join(parts, "\n<!-- next window -->\n")
    end

    rows_parts = Any[]
    last_ack = nothing
    for (s, e) in chunks
        try
            push!(rows_parts, _parse_one(fetch_xml(s, e), parser))
        catch err
            err isa ENTSOEAcknowledgement || rethrow()
            last_ack = err
        end
    end
    isempty(rows_parts) && throw(last_ack)
    rows = reduce(vcat, rows_parts)
    return format isa LocalTime ? _to_local_time(rows, format.tz) : rows
end

# ---------------------------------------------------------------------------
# Market

"""
    day_ahead_prices(client, area, period_start, period_end[, format]) -> StructVector | String

Day-ahead clearing prices (Market 12.1.D, `documentType=A44`).

`area` is used as both `in_Domain` and `out_Domain` (they're always the
same for an internal day-ahead price query). `period_start` /
`period_end` accept `DateTime`, `Date`, `ZonedDateTime`, or a raw
`Int64` `yyyymmddHHMM`.

Returns a Tables.jl-compatible `StructVector{(time, value)}` in EUR/MWh
by default; pass [`Raw()`](@ref) as the trailing argument to get the raw
XML `String` instead.

Throws an [`ENTSOEAcknowledgement`](@ref) if ENTSO-E reports no
matching data.

# Example
```julia
using Dates
client = ENTSOEClient(ENV["ENTSOE_API_TOKEN"])
prices = day_ahead_prices(client, EIC.NL,
    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"))

prices.value      # Vector{Float64} — column access
prices_xml = day_ahead_prices(client, EIC.NL,
    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"), Raw())
```
"""
function day_ahead_prices(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false, window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,)
    ) do s, e
        market121_d_energy_prices(
            apis.market, "A44",
            s, e,
            String(area), String(area),
        )
    end
end

"""
    intraday_prices(client, area, period_start, period_end[, format];
                    sequence=nothing) -> StructVector | String

Intraday clearing prices (Market 12.1.D, `documentType=A44`,
`contract_MarketAgreement.type=A07`). Same wire endpoint as
[`day_ahead_prices`](@ref) but flipped to the intraday contract type;
ENTSO-E returns one TimeSeries per intraday auction sequence (SIDC IDA
1/2/3 etc.).

Pass `sequence=1`/`2`/`3` to filter server-side to a single auction;
omit it to receive every sequence the publication exposes. Returns a
Tables.jl-compatible `StructVector{(time, value)}` in EUR/MWh.

Mirrors entsoe-py's `query_intraday_prices`.
"""
function intraday_prices(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        sequence::Union{Nothing, Integer} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,)
    ) do s, e
        market121_d_energy_prices(
            apis.market, "A44",
            s, e,
            String(area), String(area);
            contract_market_agreement_type = "A07",
            classification_sequence_attribute_instance_component_position =
                sequence === nothing ? nothing : Int(sequence),
        )
    end
end

# ---------------------------------------------------------------------------
# Market — auction & allocation endpoints (12.1.A/B/C/E)

"""
    total_nominated_capacity(client, in_area, out_area, period_start[, period_end][, format])
      -> StructVector | String

Total nominated capacity per direction (Market 12.1.B,
`documentType=A26`, `businessType=B08`). Quantities are the total
capacity nominated by market participants for the day-ahead schedule.
Returns `StructVector{(time, value)}` in MW.

`period_end` is optional — when omitted, ENTSO-E returns the single
publication snapshot at `period_start`.
"""
function total_nominated_capacity(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false, window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    # `period_end === nothing` asks ENTSO-E for the single publication
    # snapshot at `period_start` — there's no range to split, so issue one
    # request through the non-splitting path.
    if period_end === nothing
        return _query(
            format, parse_timeseries;
            validate = validate, eics = (in_area, out_area),
        ) do
            market121_b_total_nominated_capacity(
                apis.market, "A26", "B08",
                String(out_area), String(in_area),
                _to_period(period_start);
                period_end = nothing,
            )
        end
    end
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market121_b_total_nominated_capacity(
            apis.market, "A26", "B08",
            String(out_area), String(in_area),
            s;
            period_end = e,
        )
    end
end

"""
    congestion_income(client, in_area, out_area, period_start, period_end[, format];
                      contract_market_agreement_type="A01")
      -> StructVector | String

Congestion income from implicit + flow-based allocations (Market
12.1.E, `documentType=A25`, `businessType=B10`). Returns
`StructVector{(time, value)}` in the local currency. The wrapper's
`parse_timeseries` follows the `<*.amount>` convention so the value is
picked up regardless of whether the field is named `<settlement_Price.amount>`,
`<congestionIncome_Price.amount>`, etc.

`contract_market_agreement_type` defaults to `"A01"` (daily).
"""
function congestion_income(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        contract_market_agreement_type::AbstractString = "A01",
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market121_e_implicit_and_flow_based_allocations_congestion_income(
            apis.market, "A25", "B10",
            String(contract_market_agreement_type),
            String(out_area), String(in_area),
            s, e,
        )
    end
end

"""
    intraday_offered_capacity(client, in_area, out_area, period_start, period_end[, format];
                              implicit=true, id_type="IDCT") -> StructVector | String

Intraday cross-border offered transfer capacity. Thin router over the
three underlying allocation endpoints, mirroring entsoe-py's
`query_intraday_offered_capacity`:

  - `implicit=false` → `explicit_allocations_offered_transfer_capacity`
    with `auction_type="A02"` (used on the few explicit-ID borders
    like BE↔GB).
  - `implicit=true, id_type="IDCT"` →
    `continuous_allocations_offered_transfer_capacity`
    (SIDC continuous trading, `auction_type="A08"`).
  - `implicit=true, id_type="IDA1"`/`"IDA2"`/`"IDA3"` →
    `implicit_allocations_offered_transfer_capacity` with
    `contract_market_agreement_type="A07"` and `sequence=1`/`2`/`3`
    (SIDC pan-European IDA auctions).
"""
function intraday_offered_capacity(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        implicit::Bool = true,
        id_type::AbstractString = "IDCT",
        window::Period = Year(1),
    )
    if !implicit
        return explicit_allocations_offered_transfer_capacity(
            client, in_area, out_area, period_start, period_end, format;
            validate = validate,
            auction_type = "A02",
            contract_market_agreement_type = "A07",
            window = window,
        )
    end
    if id_type == "IDCT"
        return continuous_allocations_offered_transfer_capacity(
            client, in_area, out_area, period_start, period_end, format;
            validate = validate,
            auction_type = "A08",
            contract_market_agreement_type = "A07",
            window = window,
        )
    end
    sequence = if id_type == "IDA1"
        1
    elseif id_type == "IDA2"
        2
    elseif id_type == "IDA3"
        3
    else
        throw(
            ArgumentError(
                "Unknown id_type $(repr(String(id_type))). " *
                    "Expected one of: IDCT, IDA1, IDA2, IDA3.",
            ),
        )
    end
    return implicit_allocations_offered_transfer_capacity(
        client, in_area, out_area, period_start, period_end, format;
        validate = validate,
        auction_type = "A01",
        contract_market_agreement_type = "A07",
        sequence = sequence,
        window = window,
    )
end

"""
    explicit_allocations_offered_transfer_capacity(client, in_area, out_area, period_start, period_end[, format];
                                                   auction_type="A02",
                                                   contract_market_agreement_type="A01",
                                                   auction_category=nothing,
                                                   sequence=nothing)
      -> StructVector | String

Explicit allocations offered transfer capacity (Market 11.1.A,
`documentType=A31`). Returns the capacity offered to explicit-auction
participants per direction/timeframe.

Defaults match the Postman canonical example (`auction_type="A02"`
monthly, `contract_market_agreement_type="A01"` daily).
"""
function explicit_allocations_offered_transfer_capacity(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        auction_type::AbstractString = "A02",
        contract_market_agreement_type::AbstractString = "A01",
        auction_category::Union{Nothing, AbstractString} = nothing,
        sequence::Union{Nothing, Integer} = nothing,
        update_date_and_or_time::Union{Nothing, Integer} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market111_a_explicit_allocations_offered_transfer_capacity(
            apis.market, "A31",
            String(auction_type), String(contract_market_agreement_type),
            String(out_area), String(in_area),
            s, e;
            auction_category = auction_category === nothing ? nothing : String(auction_category),
            update_date_and_or_time = update_date_and_or_time === nothing ?
                nothing : Int(update_date_and_or_time),
            classification_sequence_attribute_instance_component_position =
                sequence === nothing ? nothing : Int(sequence),
        )
    end
end

"""
    flow_based_allocations(client, in_area, out_area, period_start, period_end[, format];
                           process_type="A44") -> StructVector | String

Flow-based allocation results (Market 11.1.B, `documentType=B09`).
`process_type` default `"A44"` (Intraday); pass `"A01"` for day-ahead.
For historical periods use [`flow_based_allocations_archives`](@ref).
"""
function flow_based_allocations(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A44",
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market111_b_flow_based_allocations(
            apis.market, "B09", String(process_type),
            String(out_area), String(in_area),
            s, e,
        )
    end
end

"""
    flow_based_allocations_archives(client, in_area, out_area, period_start, period_end[, format];
                                    process_type="A32",
                                    storage_type="archive") -> StructVector | String

Archived flow-based allocations (Market 11.1.B archive variant).
`process_type` default `"A32"` (Monthly); `storage_type` default
`"archive"` matches the published archive bucket.
"""
function flow_based_allocations_archives(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A32",
        storage_type::AbstractString = "archive",
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market111_b_flow_based_allocations_archives(
            apis.market, "B09", String(process_type),
            String(out_area), String(in_area),
            s, e,
            String(storage_type),
        )
    end
end

"""
    continuous_allocations_offered_transfer_capacity(client, in_area, out_area, period_start, period_end[, format];
                                                     auction_type="A08",
                                                     contract_market_agreement_type="A07")
      -> StructVector | String

Continuous-intraday offered transfer capacity (Market 11.1, SIDC IDCT),
`documentType=A31`. `auction_type="A08"` is the continuous-intraday
auction; `contract_market_agreement_type="A07"` is intraday.
"""
function continuous_allocations_offered_transfer_capacity(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        auction_type::AbstractString = "A08",
        contract_market_agreement_type::AbstractString = "A07",
        update_date_and_or_time::Union{Nothing, Integer} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market111_continuous_allocations_offered_transfer_capacity(
            apis.market, "A31", String(auction_type),
            String(out_area), String(in_area),
            s, e,
            String(contract_market_agreement_type);
            update_date_and_or_time = update_date_and_or_time === nothing ?
                nothing : Int(update_date_and_or_time),
        )
    end
end

"""
    implicit_allocations_offered_transfer_capacity(client, in_area, out_area, period_start, period_end[, format];
                                                   auction_type="A01",
                                                   contract_market_agreement_type="A01",
                                                   sequence=nothing)
      -> StructVector | String

Implicit-auction offered transfer capacity (Market 11.1, implicit
day-ahead), `documentType=A31`. Defaults to day-ahead implicit auction
(`auction_type="A01"`, `contract_market_agreement_type="A01"`).
Pass `sequence` to filter SIDC IDA1/2/3 results.
"""
function implicit_allocations_offered_transfer_capacity(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        auction_type::AbstractString = "A01",
        contract_market_agreement_type::AbstractString = "A01",
        sequence::Union{Nothing, Integer} = nothing,
        update_date_and_or_time::Union{Nothing, Integer} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market111_implicit_allocations_offered_transfer_capacity(
            apis.market, "A31",
            String(auction_type), String(contract_market_agreement_type),
            String(out_area), String(in_area),
            s, e;
            update_date_and_or_time = update_date_and_or_time === nothing ?
                nothing : Int(update_date_and_or_time),
            classification_sequence_attribute_instance_component_position =
                sequence === nothing ? nothing : Int(sequence),
        )
    end
end

"""
    explicit_allocations_auction_revenue(client, in_area, out_area, period_start, period_end[, format];
                                         business_type="B07",
                                         contract_market_agreement_type="A01")
      -> StructVector | String

Explicit-allocation auction revenue (Market 12.1.A, `documentType=A25`,
default `businessType=B07` — congestion revenue).
"""
function explicit_allocations_auction_revenue(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::AbstractString = "B07",
        contract_market_agreement_type::AbstractString = "A01",
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market121_a_explicit_allocations_auction_revenue(
            apis.market, "A25",
            String(business_type), String(contract_market_agreement_type),
            String(out_area), String(in_area),
            s, e,
        )
    end
end

"""
    explicit_allocations_use_of_transfer_capacity(client, in_area, out_area, period_start, period_end[, format];
                                                  business_type="B05",
                                                  contract_market_agreement_type="A07",
                                                  auction_category=nothing,
                                                  sequence=nothing)
      -> StructVector | String

Use of transfer capacity from explicit allocations (Market 12.1.A,
`documentType=A25`, default `businessType=B05` — already allocated).
"""
function explicit_allocations_use_of_transfer_capacity(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::AbstractString = "B05",
        contract_market_agreement_type::AbstractString = "A07",
        auction_category::Union{Nothing, AbstractString} = nothing,
        sequence::Union{Nothing, Integer} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market121_a_explicit_allocations_use_of_the_transfer_capacity(
            apis.market, "A25",
            String(business_type), String(contract_market_agreement_type),
            String(out_area), String(in_area),
            s, e;
            auction_category = auction_category === nothing ? nothing : String(auction_category),
            classification_sequence_attribute_instance_component_position =
                sequence === nothing ? nothing : Int(sequence),
        )
    end
end

"""
    total_capacity_already_allocated(client, in_area, out_area, period_start, period_end[, format];
                                     business_type="A29",
                                     contract_market_agreement_type="A01",
                                     auction_category=nothing)
      -> StructVector | String

Total capacity already allocated (Market 12.1.C, `documentType=A26`,
default `businessType=A29` — already allocated capacity).
"""
function total_capacity_already_allocated(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::AbstractString = "A29",
        contract_market_agreement_type::AbstractString = "A01",
        auction_category::Union{Nothing, AbstractString} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market121_c_total_capacity_already_allocated(
            apis.market, "A26",
            String(business_type), String(contract_market_agreement_type),
            String(out_area), String(in_area),
            s, e;
            auction_category = auction_category === nothing ? nothing : String(auction_category),
        )
    end
end

"""
    transfer_capacities_with_third_countries(client, in_area, out_area, period_start, period_end[, format];
                                             auction_type="A02",
                                             contract_market_agreement_type="A07",
                                             auction_category=nothing,
                                             sequence=nothing)
      -> StructVector | String

Transfer capacities allocated with third countries (Market 12.1.H,
`documentType=A94`).
"""
function transfer_capacities_with_third_countries(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        auction_type::AbstractString = "A02",
        contract_market_agreement_type::AbstractString = "A07",
        auction_category::Union{Nothing, AbstractString} = nothing,
        sequence::Union{Nothing, Integer} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (in_area, out_area),
    ) do s, e
        market121_h_transfer_capacities_allocated_with_third_countries121_h_explicit(
            apis.market, "A94",
            String(auction_type), String(contract_market_agreement_type),
            String(out_area), String(in_area),
            s, e;
            auction_category = auction_category === nothing ? nothing : String(auction_category),
            classification_sequence_attribute_instance_component_position =
                sequence === nothing ? nothing : Int(sequence),
        )
    end
end

"""
    implicit_auction_net_positions(client, area, period_start, period_end[, format];
                                   contract_market_agreement_type="A07")
      -> StructVector | String

Net positions from implicit auctions (Market 12.1.E variant,
`documentType=A25`, `businessType=B09` — Net position). Single-zone —
`in_Domain` and `out_Domain` are both set to `area`, matching how
ENTSO-E publishes the self-loop net position. Returns
`StructVector{(time, value)}` in MW (positive = net export).

`contract_market_agreement_type` defaults to `"A07"` (intraday — the
typical use case for implicit auctions); pass `"A01"` for daily.
"""
function implicit_auction_net_positions(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        contract_market_agreement_type::AbstractString = "A07",
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,),
    ) do s, e
        market121_e_implicit_auction_net_positions(
            apis.market, "A25", "B09",
            String(contract_market_agreement_type),
            String(area), String(area),
            s, e,
        )
    end
end

# ---------------------------------------------------------------------------
# Load

# Single helper — every Load 6.1.* shares the same shape, only
# `processType` differs.
function _load_query(
        client::Client, process::AbstractString, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool, window::Period,
        api_fn::Function,
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,)
    ) do s, e
        api_fn(
            apis.load, "A65", String(process), String(area),
            s, e,
        )
    end
end

"""
    actual_total_load(client, area, start, stop[, format]) -> StructVector | String

Realised total system load (Load 6.1.A, `documentType=A65`,
`processType=A16`). Quarter-hour resolution. Returns
`StructVector{(time, value)}` with `value` in MW; pass [`Raw()`](@ref)
for the XML body.
"""
actual_total_load(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false, window::Period = Year(1),
) = _load_query(
    client, "A16", area, start, stop, format;
    validate = validate, window = window, api_fn = load61_a_actual_total_load,
)

"""
    day_ahead_load_forecast(client, area, start, stop[, format]) -> StructVector | String

Day-ahead total load forecast (Load 6.1.B, `processType=A01`).
"""
day_ahead_load_forecast(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false, window::Period = Year(1),
) = _load_query(
    client, "A01", area, start, stop, format;
    validate = validate, window = window, api_fn = load61_b_day_ahead_total_load_forecast,
)

"""
    week_ahead_load_forecast(client, area, start, stop[, format]) -> StructVector | String

Week-ahead total load forecast (Load 6.1.C, `processType=A31`).
"""
week_ahead_load_forecast(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false, window::Period = Year(1),
) = _load_query(
    client, "A31", area, start, stop, format;
    validate = validate, window = window, api_fn = load61_c_week_ahead_total_load_forecast,
)

"""
    month_ahead_load_forecast(client, area, start, stop[, format]) -> StructVector | String

Month-ahead total load forecast (Load 6.1.D, `processType=A32`).
"""
month_ahead_load_forecast(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false, window::Period = Year(1),
) = _load_query(
    client, "A32", area, start, stop, format;
    validate = validate, window = window, api_fn = load61_d_month_ahead_total_load_forecast,
)

"""
    year_ahead_load_forecast(client, area, start, stop[, format]) -> StructVector | String

Year-ahead total load forecast (Load 6.1.E, `processType=A33`).
"""
year_ahead_load_forecast(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false, window::Period = Year(1),
) = _load_query(
    client, "A33", area, start, stop, format;
    validate = validate, window = window, api_fn = load61_e_year_ahead_total_load_forecast,
)

"""
    year_ahead_forecast_margin(client, area, start, stop[, format]) -> StructVector | String

Year-ahead generation-adequacy forecast margin (Load 8.1,
`documentType=A70`, `processType=A33`). The surplus of forecasted
available capacity over forecasted peak load for the year ahead;
one row per published period (`StructVector{(time, value)}` in MW).

Distinct from [`year_ahead_load_forecast`](@ref): that's the *demand*
forecast (documentType A65), whereas this is the *margin* —
margin = available capacity − peak load.
"""
function year_ahead_forecast_margin(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,)
    ) do s, e
        load81_year_ahead_forecast_margin(
            apis.load, "A70", "A33", String(area),
            s, e,
        )
    end
end

# ---------------------------------------------------------------------------
# Generation

"""
    installed_capacity_per_production_type(client, area, start, stop[, format]) -> StructVector | String

Year-ahead installed capacity per production type (Generation 14.1.A,
`documentType=A68`, `processType=A33`). For a calendar-year window
spanning Dec 31 23:00 → Dec 31 23:00. Returns
`StructVector{(psr_type::String, capacity_mw::Float64)}`.

Map `psr_type` codes to labels via [`PSR_TYPE`](@ref) /
[`describe`](@ref): `describe(PSR_TYPE, "B16") == "Solar"`.
"""
function installed_capacity_per_production_type(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_installed_capacity;
        validate = validate, eics = (area,),
    ) do
        generation141_a_installed_capacity_per_production_type(
            apis.generation, "A68", "A33", String(area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

"""
    installed_capacity_per_production_unit(client, area, period_start, period_end[, format];
                                           psr_type=nothing) -> StructVector | String

Year-ahead installed capacity broken out per *generating unit* (rather
than aggregated per production type) — Generation 14.1.B,
`documentType=A71`, `processType=A33`. Returns
`StructVector{(unit_mrid, unit_name, psr_type, capacity_mw)}`.

Pass `psr_type="B19"` (Wind Onshore) etc. to filter to a single
technology. Mirrors entsoe-py's
`query_installed_generation_capacity_per_unit`.
"""
function installed_capacity_per_production_unit(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        psr_type::Union{Nothing, AbstractString} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_installed_capacity_per_unit;
        validate = validate, eics = (area,),
    ) do
        generation141_b_installed_capacity_per_production_unit(
            apis.generation, "A71", "A33", String(area),
            _to_period(period_start), _to_period(period_end);
            psr_type = psr_type === nothing ? nothing : String(psr_type),
        )
    end
end

"""
    generation_forecast_day_ahead(client, area, start, stop[, format]) -> StructVector | String

Day-ahead total generation forecast (Generation 14.1.C,
`documentType=A71`, `processType=A01`). Returns
`StructVector{(time, value)}` in MW.
"""
function generation_forecast_day_ahead(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,),
    ) do s, e
        generation141_c_generation_forecast_day_ahead(
            apis.generation, "A71", "A01", String(area),
            s, e,
        )
    end
end

"""
    wind_solar_forecast(client, area, start, stop[, format]; psr_type=nothing)
      -> StructVector | String

Wind & solar forecast, day-ahead (Generation 14.1.D,
`documentType=A69`, `processType=A01`). The returned document carries
one TimeSeries per technology — we parse with
[`parse_timeseries_per_psr`](@ref), so each row is tagged with its
`psr_type` (`B16` Solar, `B18` Wind Offshore, `B19` Wind Onshore).

Pass `psr_type="B19"` to filter at the API level (returns just that
technology).
"""
function wind_solar_forecast(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        psr_type::Union{Nothing, AbstractString} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries_per_psr;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,),
    ) do s, e
        generation141_d_generation_forecasts_for_wind_and_solar(
            apis.generation, "A69", "A01", String(area),
            s, e;
            psr_type = psr_type === nothing ? nothing : String(psr_type),
        )
    end
end

"""
    intraday_wind_solar_forecast(client, area, period_start, period_end[, format];
                                 psr_type=nothing) -> StructVector | String

Intraday wind & solar generation forecast (Generation 14.1.D,
`documentType=A69`, `processType=A40`). Same endpoint as
[`wind_solar_forecast`](@ref) but with the intraday process type — gives
the latest published forecast as auctions clear through the day, rather
than the day-ahead snapshot.

Returns a `StructVector{(time, psr_type, value)}` in MW. Pass
`psr_type="B16"` (Solar), `"B18"` (Wind Offshore), or `"B19"` (Wind
Onshore) to filter server-side. Mirrors entsoe-py's
`query_intraday_wind_and_solar_forecast`.
"""
function intraday_wind_solar_forecast(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        psr_type::Union{Nothing, AbstractString} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries_per_psr;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,),
    ) do s, e
        generation141_d_generation_forecasts_for_wind_and_solar(
            apis.generation, "A69", "A40", String(area),
            s, e;
            psr_type = psr_type === nothing ? nothing : String(psr_type),
        )
    end
end

"""
    actual_generation_per_production_type(client, area, start, stop[, format];
                                          psr_type=nothing) -> StructVector | String

Realised generation broken down by production type (Generation
16.1.B/C, `documentType=A75`, `processType=A16`). One TimeSeries per
technology — parse rows are `(time, psr_type, value)` with `value` in
MW.

Pass `psr_type="B16"` to fetch a single technology server-side.
"""
function actual_generation_per_production_type(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        psr_type::Union{Nothing, AbstractString} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries_per_psr;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,),
    ) do s, e
        generation161_b_c_actual_generation_per_production_type(
            apis.generation, "A75", "A16", String(area),
            s, e;
            psr_type = psr_type === nothing ? nothing : String(psr_type),
        )
    end
end

"""
    actual_generation_per_generation_unit(client, area, period_start, period_end[, format];
                                          psr_type=nothing, registered_resource=nothing)
      -> StructVector | String

Realised generation broken down per *generating unit* (Generation
16.1.A, `documentType=A73`, `processType=A16`). One row per
`<Point>` per unit; fields are
`(time, unit_mrid, unit_name, psr_type, value)` with `value` in MW.

Pass `psr_type="B16"` to filter to one technology; pass
`registered_resource` to filter to a single generating unit by mRID.
Mirrors entsoe-py's `query_generation_per_plant`.
"""
function actual_generation_per_generation_unit(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        psr_type::Union{Nothing, AbstractString} = nothing,
        registered_resource::Union{Nothing, AbstractString} = nothing,
        window::Period = Year(1),
    )
    apis = entsoe_apis(client)
    return _split_query(
        format, parse_timeseries_per_unit;
        period_start = period_start, period_end = period_end, window = window,
        validate = validate, eics = (area,),
    ) do s, e
        generation161_a_actual_generation_per_generation_unit(
            apis.generation, "A73", "A16", String(area),
            s, e;
            psr_type = psr_type === nothing ? nothing : String(psr_type),
            registered_resource = registered_resource === nothing ?
                nothing : String(registered_resource),
        )
    end
end

# ---------------------------------------------------------------------------
# Transmission

"""
    cross_border_physical_flows(client, in_area, out_area, start, stop[, format])
      -> StructVector | String

Cross-border physical flows between two bidding zones (Transmission
12.1.G, `documentType=A11`). Returns hourly `StructVector{(time, value)}`
in MW.

Note ENTSO-E's ordering: `in_area` is the receiving zone, `out_area`
is the sending zone — flows are positive when they go *from* `out_area`
*into* `in_area`.
"""
function cross_border_physical_flows(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    ) do
        transmission121_g_cross_border_physical_flows(
            apis.transmission, "A11",
            String(out_area), String(in_area),  # generated layer takes (out, in) — see api/apis/api_TransmissionApi.jl
            _to_period(period_start), _to_period(period_end),
        )
    end
end

"""
    cross_border_physical_flows_all(client, area, period_start, period_end[, format];
                                    export_=true,
                                    neighbours=NEIGHBOURS[area])
      -> StructVector | String

Aggregate cross-border physical flows for a zone across every
configured border. Calls [`cross_border_physical_flows`](@ref) once
per neighbour and concatenates the results, tagging each row with
a `border` column (the neighbouring EIC).

`export_=true` (default) sums flows leaving `area`; `export_=false`
sums flows arriving in `area`. Pass `neighbours` explicitly to
restrict / extend the default list from [`NEIGHBOURS`](@ref).

Mirrors entsoe-py's `query_physical_crossborder_allborders`.
`ENTSOEAcknowledgement`s on individual borders are caught per-border
and dropped — partial coverage is normal when ENTSO-E hasn't published
flows on every link.
"""
function cross_border_physical_flows_all(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        export_::Bool = true,
        neighbours::AbstractVector{<:AbstractString} = get(
            NEIGHBOURS, String(area), String[],
        ),
    )
    if isempty(neighbours)
        throw(
            ArgumentError(
                "No neighbours configured for $(repr(String(area))). " *
                    "Pass `neighbours = [...]` explicitly or extend `NEIGHBOURS`.",
            ),
        )
    end
    parts = StructArrays.StructArray{
        @NamedTuple{time::DateTime, border::String, value::Float64}
    }[]
    raw_parts = String[]
    for n in neighbours
        in_area, out_area = export_ ? (n, area) : (area, n)
        try
            rows = cross_border_physical_flows(
                client, in_area, out_area, period_start, period_end, format;
                validate = validate,
            )
            if format isa Raw
                push!(raw_parts, rows)
            else
                push!(
                    parts,
                    StructArrays.StructArray(
                        (
                            time = rows.time,
                            border = fill(String(n), length(rows)),
                            value = rows.value,
                        ),
                    ),
                )
            end
        catch err
            err isa ENTSOEAcknowledgement || rethrow()
            # No flow published on this border for the window — skip.
        end
    end
    if format isa Raw
        return join(raw_parts, "\n<!-- next border -->\n")
    end
    return isempty(parts) ?
        StructArrays.StructArray(
            (time = DateTime[], border = String[], value = Float64[]),
        ) :
        reduce(vcat, parts)
end

"""
    commercial_schedules(client, in_area, out_area, start, stop[, format];
                         contract_market_agreement_type="A01") -> StructVector | String

Total scheduled commercial exchanges between two bidding zones
(Transmission 12.1.F, `documentType=A09`). Returns
`StructVector{(time, value)}` in MW — quantities are scheduled flows
*from* `out_area` *into* `in_area*, mirroring the same convention as
[`cross_border_physical_flows`](@ref).

`contract_market_agreement_type` defaults to `"A01"` (daily) — set to
`"A05"` for total, `"A07"` for intraday, etc.
"""
function commercial_schedules(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        contract_market_agreement_type::AbstractString = "A01",
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    ) do
        transmission121_f_commercial_schedules(
            apis.transmission, "A09",
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end);
            contract_market_agreement_type = String(contract_market_agreement_type),
        )
    end
end

"""
    scheduled_exchanges(client, in_area, out_area, period_start, period_end[, format];
                        dayahead=false) -> StructVector | String

Scheduled cross-border exchanges (Transmission 12.1.F, `documentType=A09`).
Same endpoint as [`commercial_schedules`](@ref); this alias preserves
the entsoe-py call shape — `dayahead=true` selects A01 (day-ahead),
`dayahead=false` (default) selects A05 (total).

Use `commercial_schedules(...; contract_market_agreement_type=...)`
directly for finer control (e.g. A07 intraday).
"""
function scheduled_exchanges(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false, dayahead::Bool = false,
    )
    return commercial_schedules(
        client, in_area, out_area, period_start, period_end, format;
        validate = validate,
        contract_market_agreement_type = dayahead ? "A01" : "A05",
    )
end

"""
    commercial_schedules_net_positions(client, area, start, stop[, format];
                                       contract_market_agreement_type="A01")
      -> StructVector | String

Net position from total scheduled commercial exchanges (Transmission
12.1.F, `documentType=A09`). Same endpoint as
[`commercial_schedules`](@ref) but exposed via the
`*_net_positions` codegen variant that ENTSO-E publishes for the
self-loop case (where `in_area == out_area`).

Pass a single `area` — it's used for both `in_Domain` and `out_Domain`,
matching the platform's own net-position calculation.
"""
function commercial_schedules_net_positions(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        contract_market_agreement_type::AbstractString = "A01",
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (area,),
    ) do
        transmission121_f_commercial_schedules_net_positions(
            apis.transmission, "A09",
            String(area), String(area),
            _to_period(period_start), _to_period(period_end);
            contract_market_agreement_type = String(contract_market_agreement_type),
        )
    end
end

"""
    forecasted_transfer_capacities(client, in_area, out_area, start, stop[, format];
                                   contract_market_agreement_type="A01")
      -> StructVector | String

Forecasted transfer capacities between two bidding zones (Transmission
11.1.A, `documentType=A61` — Estimated Net Transfer Capacity).
`contract_market_agreement_type` defaults to `"A01"` (daily); pass
`"A02"` for weekly, `"A03"` monthly, `"A04"` yearly, `"A07"` intraday.

Returns `StructVector{(time, value)}` in MW, representing forecasted
capacity *from* `out_area` *into* `in_area`.
"""
function forecasted_transfer_capacities(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        contract_market_agreement_type::AbstractString = "A01",
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    ) do
        transmission111_a_forecasted_transfer_capacities(
            apis.transmission, "A61",
            String(contract_market_agreement_type),
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

"""
    net_transfer_capacity_day_ahead(client, in_area, out_area, period_start, period_end[, format])
      -> StructVector | String

Day-ahead forecasted net transfer capacity (`contract_marketagreement_type=A01`).
Thin wrapper over [`forecasted_transfer_capacities`](@ref); mirrors
entsoe-py's `query_net_transfer_capacity_dayahead`.
"""
net_transfer_capacity_day_ahead(
    client::Client, in_area, out_area, start, stop, format::ResponseFormat = Parsed();
    validate = false,
) = forecasted_transfer_capacities(
    client, in_area, out_area, start, stop, format;
    validate = validate, contract_market_agreement_type = "A01",
)

"""
    net_transfer_capacity_week_ahead(client, in_area, out_area, period_start, period_end[, format])
      -> StructVector | String

Week-ahead forecasted net transfer capacity (`contract_marketagreement_type=A02`).
"""
net_transfer_capacity_week_ahead(
    client::Client, in_area, out_area, start, stop, format::ResponseFormat = Parsed();
    validate = false,
) = forecasted_transfer_capacities(
    client, in_area, out_area, start, stop, format;
    validate = validate, contract_market_agreement_type = "A02",
)

"""
    net_transfer_capacity_month_ahead(client, in_area, out_area, period_start, period_end[, format])
      -> StructVector | String

Month-ahead forecasted net transfer capacity (`contract_marketagreement_type=A03`).
"""
net_transfer_capacity_month_ahead(
    client::Client, in_area, out_area, start, stop, format::ResponseFormat = Parsed();
    validate = false,
) = forecasted_transfer_capacities(
    client, in_area, out_area, start, stop, format;
    validate = validate, contract_market_agreement_type = "A03",
)

"""
    net_transfer_capacity_year_ahead(client, in_area, out_area, period_start, period_end[, format])
      -> StructVector | String

Year-ahead forecasted net transfer capacity (`contract_marketagreement_type=A04`).
"""
net_transfer_capacity_year_ahead(
    client::Client, in_area, out_area, start, stop, format::ResponseFormat = Parsed();
    validate = false,
) = forecasted_transfer_capacities(
    client, in_area, out_area, start, stop, format;
    validate = validate, contract_market_agreement_type = "A04",
)

"""
    expansion_and_dismantling_project(client, in_area, out_area, period_start, period_end[, format];
                                      business_type=nothing, doc_status=nothing)
      -> StructVector | String

Interconnector network expansion and dismantling projects (Transmission
9.1, `documentType=A90`). TYNDP-related project announcements.
`StructVector{(time, value)}` per project — passing `Raw()` exposes
the full project metadata for richer consumers.
"""
function expansion_and_dismantling_project(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::Union{Nothing, AbstractString} = nothing,
        doc_status::Union{Nothing, AbstractString} = nothing,
        withdrawn::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    ) do
        transmission91_expansion_and_dismantling_project(
            apis.transmission, "A90",
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
            doc_status = withdrawn ? "A13" :
                (doc_status === nothing ? nothing : String(doc_status)),
        )
    end
end

"""
    redispatching_internal(client, area, start, stop[, format]) -> StructVector | String

Internal redispatching activations (Transmission 13.1.A,
`documentType=A63`, `businessType=A85` — Internal redispatch).
Single-zone query — `in_Domain` and `out_Domain` are both set to
`area`. Returns `StructVector{(time, value)}` in MW.
"""
function redispatching_internal(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (area,),
    ) do
        transmission131_a_redispatching_internal(
            apis.transmission, "A63", "A85",
            String(area), String(area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

"""
    redispatching_cross_border(client, in_area, out_area, start, stop[, format])
      -> StructVector | String

Cross-border redispatching activations (Transmission 13.1.A,
`documentType=A63`, `businessType=A46` — Cross-border redispatch).
Returns `StructVector{(time, value)}` in MW representing energy
redispatched between the two zones.
"""
function redispatching_cross_border(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    ) do
        transmission131_a_redispatching_cross_border(
            apis.transmission, "A63", "A46",
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

"""
    costs_of_congestion_management(client, area, start, stop[, format])
      -> StructVector | String

Costs paid by the TSO for congestion-management actions (Transmission
13.1.C, `documentType=A92`). Single-zone query — both `in_Domain` and
`out_Domain` are set to `area`. Returns `StructVector{(time, value)}`;
values are the cost amount per period (units depend on the TSO's
reporting — typically EUR, sometimes the local currency).

`parse_timeseries` picks the cost amount out of
`<congestionCost_Price.amount>` automatically (any element ending in
`.amount` is recognised).
"""
function costs_of_congestion_management(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (area,),
    ) do
        transmission131_c_costs_of_congestion_management(
            apis.transmission, "A92",
            String(area), String(area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

"""
    countertrading(client, in_area, out_area, start, stop[, format])
      -> StructVector | String

Cross-border countertrading activations (Transmission 13.1.B,
`documentType=A91`). Returns `StructVector{(time, value)}` in MW —
volumes traded between the two zones to relieve congestion.
"""
function countertrading(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    ) do
        transmission131_b_countertrading(
            apis.transmission, "A91",
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

# ---------------------------------------------------------------------------
# Generation — hydro state

# ---------------------------------------------------------------------------
# Outages — all four endpoints return Unavailability_MarketDocument and
# share `parse_unavailability` (one row per outage; window + resource +
# nominal MW + business_type). Each wrapper exposes the most common
# server-side filters as kwargs; the per-15-minute curtailment curve is
# accessible by passing `Raw()`.

"""
    unavailability_of_generation_units(client, area, start, stop[, format];
                                       business_type=nothing,
                                       registered_resource=nothing,
                                       m_r_i_d=nothing, offset=nothing)
      -> StructVector | String

Outage notices for individual generation units in `area` (Outages
15.1.A/B, `documentType=A80`). Pass `business_type="A53"` for planned
outages only, `"A54"` for unplanned. Filter to one unit with
`registered_resource = "22WCOOX6X000064W"`.

Returns the [`parse_unavailability`](@ref) shape — one row per outage
notice, with `resource_name`, `psr_type`, `nominal_mw`, and the time
bounds.
"""
function unavailability_of_generation_units(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::Union{Nothing, AbstractString} = nothing,
        doc_status::Union{Nothing, AbstractString} = nothing,
        withdrawn::Bool = false,
        period_start_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        period_end_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        registered_resource::Union{Nothing, AbstractString} = nothing,
        m_r_i_d::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_unavailability;
        validate = validate, eics = (area,),
    ) do
        outages151_a_b_unavailability_of_generation_units(
            apis.outages, "A80", String(area),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
            doc_status = withdrawn ? "A13" :
                (doc_status === nothing ? nothing : String(doc_status)),
            period_start_update = period_start_update === nothing ?
                nothing : _to_period(period_start_update),
            period_end_update = period_end_update === nothing ?
                nothing : _to_period(period_end_update),
            registered_resource = registered_resource === nothing ?
                nothing : String(registered_resource),
            m_r_i_d = m_r_i_d === nothing ? nothing : String(m_r_i_d),
            offset = offset === nothing ? nothing : Int(offset),
        )
    end
end

"""
    unavailability_of_production_units(client, area, start, stop[, format];
                                       business_type=nothing,
                                       registered_resource=nothing,
                                       m_r_i_d=nothing, offset=nothing)
      -> StructVector | String

Outage notices for whole production units (Outages 15.1.C/D,
`documentType=A77`). Same shape as
[`unavailability_of_generation_units`](@ref) — production units
aggregate one or more generation units under a single mRID.
"""
function unavailability_of_production_units(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::Union{Nothing, AbstractString} = nothing,
        doc_status::Union{Nothing, AbstractString} = nothing,
        withdrawn::Bool = false,
        period_start_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        period_end_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        registered_resource::Union{Nothing, AbstractString} = nothing,
        m_r_i_d::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_unavailability;
        validate = validate, eics = (area,),
    ) do
        outages151_c_d_unavailability_of_production_units(
            apis.outages, "A77", String(area),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
            doc_status = withdrawn ? "A13" :
                (doc_status === nothing ? nothing : String(doc_status)),
            period_start_update = period_start_update === nothing ?
                nothing : _to_period(period_start_update),
            period_end_update = period_end_update === nothing ?
                nothing : _to_period(period_end_update),
            registered_resource = registered_resource === nothing ?
                nothing : String(registered_resource),
            m_r_i_d = m_r_i_d === nothing ? nothing : String(m_r_i_d),
            offset = offset === nothing ? nothing : Int(offset),
        )
    end
end

"""
    unavailability_of_transmission_infrastructure(client, in_area, out_area,
                                                  start, stop[, format];
                                                  business_type=nothing,
                                                  m_r_i_d=nothing,
                                                  offset=nothing)
      -> StructVector | String

Outage notices for cross-border transmission infrastructure (Outages
10.1.A/B, `documentType=A78`). Pass `business_type="A53"` for planned
outages only. Returns `parse_unavailability` rows.
"""
function unavailability_of_transmission_infrastructure(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::Union{Nothing, AbstractString} = nothing,
        doc_status::Union{Nothing, AbstractString} = nothing,
        withdrawn::Bool = false,
        period_start_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        period_end_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        m_r_i_d::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_unavailability;
        validate = validate, eics = (in_area, out_area),
    ) do
        outages101_a_b_unavailability_of_transmission_infrastructure(
            apis.outages, "A78",
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
            doc_status = withdrawn ? "A13" :
                (doc_status === nothing ? nothing : String(doc_status)),
            period_start_update = period_start_update === nothing ?
                nothing : _to_period(period_start_update),
            period_end_update = period_end_update === nothing ?
                nothing : _to_period(period_end_update),
            m_r_i_d = m_r_i_d === nothing ? nothing : String(m_r_i_d),
            offset = offset === nothing ? nothing : Int(offset),
        )
    end
end

"""
    outages_fall_backs(client, bidding_zone, period_start, period_end[, format];
                       process_type="A47", business_type="A53",
                       doc_status=nothing, m_r_i_d=nothing,
                       offset=nothing) -> StructVector | String

Fall-back outage notices on the IF platforms (Outages IFs IN 7.2 /
mFRR 3.11 / aFRR 3.10, `documentType=A53`). `process_type` default
`"A47"` (mFRR); pass `"A51"` (aFRR) or `"A63"` (Imbalance Netting).
`business_type` default `"A53"` (Planned maintenance); pass `"A54"`
(Unplanned) etc.

Returns [`parse_unavailability`](@ref) rows.
"""
function outages_fall_backs(
        client::Client, bidding_zone::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A47",
        business_type::AbstractString = "A53",
        doc_status::Union{Nothing, AbstractString} = nothing,
        withdrawn::Bool = false,
        m_r_i_d::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_unavailability;
        validate = validate, eics = (bidding_zone,),
    ) do
        outages_fall_backs_ifs_in72_mfrr311_afrr310(
            apis.outages, "A53",
            String(process_type), String(business_type),
            String(bidding_zone),
            _to_period(period_start), _to_period(period_end);
            doc_status = withdrawn ? "A13" :
                (doc_status === nothing ? nothing : String(doc_status)),
            m_r_i_d = m_r_i_d === nothing ? nothing : String(m_r_i_d),
            offset = offset === nothing ? nothing : Int(offset),
        )
    end
end

"""
    unavailability_of_transmission_infrastructure_available_capacity(
        client, control_area, period_start, period_end[, format];
        business_type=nothing, asset_registered_resource_m_r_i_d=nothing,
        doc_status=nothing, period_start_update=nothing,
        period_end_update=nothing, m_r_i_d=nothing,
        offset=nothing) -> StructVector | String

Available-capacity sub-view of transmission-infrastructure outage
notices (Outages 10.1.A/B variant, `documentType=A78`). Single
`control_area` query (no `in`/`out` split). Returns
[`parse_unavailability`](@ref) rows.
"""
function unavailability_of_transmission_infrastructure_available_capacity(
        client::Client, control_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::Union{Nothing, AbstractString} = nothing,
        asset_registered_resource_m_r_i_d::Union{Nothing, AbstractString} = nothing,
        doc_status::Union{Nothing, AbstractString} = nothing,
        withdrawn::Bool = false,
        period_start_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        period_end_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        m_r_i_d::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_unavailability;
        validate = validate, eics = (control_area,),
    ) do
        outages101_a_b_unavailability_of_transmission_infrastructure_available_capacity(
            apis.outages, "A78", String(control_area),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
            asset_registered_resource_m_r_i_d = asset_registered_resource_m_r_i_d === nothing ?
                nothing : String(asset_registered_resource_m_r_i_d),
            doc_status = withdrawn ? "A13" :
                (doc_status === nothing ? nothing : String(doc_status)),
            period_start_update = period_start_update === nothing ?
                nothing : _to_period(period_start_update),
            period_end_update = period_end_update === nothing ?
                nothing : _to_period(period_end_update),
            m_r_i_d = m_r_i_d === nothing ? nothing : String(m_r_i_d),
            offset = offset === nothing ? nothing : Int(offset),
        )
    end
end

"""
    unavailability_of_transmission_infrastructure_net_position_impact(
        client, ptdf_domain, period_start, period_end[, format];
        business_type=nothing, asset_registered_resource_m_r_i_d=nothing,
        doc_status=nothing, period_start_update=nothing,
        period_end_update=nothing, m_r_i_d=nothing,
        offset=nothing) -> StructVector | String

Net-position-impact sub-view of transmission-infrastructure outage
notices (Outages 10.1.A/B variant, `documentType=A78`). Takes a single
PTDF domain mRID (`ptdf_domain`); returns [`parse_unavailability`](@ref)
rows describing how each outage shifts NTC at that node.
"""
function unavailability_of_transmission_infrastructure_net_position_impact(
        client::Client, ptdf_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::Union{Nothing, AbstractString} = nothing,
        asset_registered_resource_m_r_i_d::Union{Nothing, AbstractString} = nothing,
        doc_status::Union{Nothing, AbstractString} = nothing,
        withdrawn::Bool = false,
        period_start_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        period_end_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        m_r_i_d::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_unavailability;
        validate = validate, eics = (ptdf_domain,),
    ) do
        outages101_a_b_unavailability_of_transmission_infrastructure_net_position_impact(
            apis.outages, "A78", String(ptdf_domain),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
            asset_registered_resource_m_r_i_d = asset_registered_resource_m_r_i_d === nothing ?
                nothing : String(asset_registered_resource_m_r_i_d),
            doc_status = withdrawn ? "A13" :
                (doc_status === nothing ? nothing : String(doc_status)),
            period_start_update = period_start_update === nothing ?
                nothing : _to_period(period_start_update),
            period_end_update = period_end_update === nothing ?
                nothing : _to_period(period_end_update),
            m_r_i_d = m_r_i_d === nothing ? nothing : String(m_r_i_d),
            offset = offset === nothing ? nothing : Int(offset),
        )
    end
end

"""
    unavailability_of_offshore_grid(client, bidding_zone, period_start, period_end[, format];
                                    doc_status=nothing, m_r_i_d=nothing,
                                    period_start_update=nothing,
                                    period_end_update=nothing,
                                    offset=nothing) -> StructVector | String

Outage notices for offshore-grid infrastructure (Outages 10.1.C,
`documentType=A79`). Unlike the 10.1.A/B variant for onshore
transmission, this one takes a single `bidding_zone` (no `in_Domain` /
`out_Domain` split) and has **no `businessType` parameter** — ENTSO-E
treats offshore-grid outages as a single document family.

Returns [`parse_unavailability`](@ref) rows (one row per outage event).
Pass `doc_status="A09"` for withdrawn notices, or the `*_update` pair
to slice by publication-update window. Mirrors entsoe-py's
`query_unavailability_of_offshore_grid`.
"""
function unavailability_of_offshore_grid(
        client::Client, bidding_zone::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        doc_status::Union{Nothing, AbstractString} = nothing,
        withdrawn::Bool = false,
        period_start_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        period_end_update::Union{Nothing, Integer, Dates.AbstractDateTime} = nothing,
        m_r_i_d::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_unavailability;
        validate = validate, eics = (bidding_zone,),
    ) do
        outages101_c_unavailability_of_offshore_grid_infrastructure(
            apis.outages, "A79", String(bidding_zone),
            _to_period(period_start), _to_period(period_end);
            doc_status = withdrawn ? "A13" :
                (doc_status === nothing ? nothing : String(doc_status)),
            period_start_update = period_start_update === nothing ?
                nothing : _to_period(period_start_update),
            period_end_update = period_end_update === nothing ?
                nothing : _to_period(period_end_update),
            m_r_i_d = m_r_i_d === nothing ? nothing : String(m_r_i_d),
            offset = offset === nothing ? nothing : Int(offset),
        )
    end
end

# ---------------------------------------------------------------------------
# Master data — registry of production + generation units.
# Different shape from every other endpoint: no period_start/period_end,
# just a single `implementation_date` snapshot. We accept either a `Date`
# or a `String` ("YYYY-MM-DD") for the date.

"""
    production_and_generation_units(client, area[, format];
        implementation_date::Union{Date,AbstractString} = Date(2017, 1, 1),
        business_type = "B11",
        psr_type = nothing) -> StructVector | String

Registry snapshot of production + generation units (Master Data
`master_data_production_and_generation_units`, `documentType=A95`).
Unlike every other endpoint this one takes a **single date**, not a
period window — pass `Date(2024, 1, 1)` to get the registry as it was
on that day.

`business_type` defaults to `"B11"` (production unit); pass `"B12"` for
generation unit. `psr_type` filters to one technology (e.g. `"B16"` for
solar, `"B14"` for nuclear) server-side.

Returns the [`parse_master_data`](@ref) shape: one row per generating
unit with parent production-unit context, rated MW, location, etc. Pass
[`Raw()`](@ref) to get the raw `Configuration_MarketDocument` XML.
"""
function production_and_generation_units(
        client::Client, area::AbstractString,
        format::ResponseFormat = Parsed();
        validate::Bool = false,
        implementation_date::Union{Date, AbstractString} = Date(2017, 1, 1),
        business_type::AbstractString = "B11",
        psr_type::Union{Nothing, AbstractString} = nothing,
    )
    apis = entsoe_apis(client)
    impl = implementation_date isa Date ?
        Dates.format(implementation_date, "yyyy-mm-dd") :
        String(implementation_date)
    return _query(
        format, parse_master_data;
        validate = validate, eics = (area,),
    ) do
        master_data_production_and_generation_units(
            apis.master_data, "A95", String(business_type),
            String(area), impl;
            psr_type = psr_type === nothing ? nothing : String(psr_type),
        )
    end
end

"""
    aggregated_unavailability_of_consumption_units(client, area, start, stop[, format];
                                                   business_type=nothing)
      -> StructVector | String

Aggregated consumption-side unavailability (Outages 7.1.A/B,
`documentType=A76`). Returns `parse_unavailability` rows — the
`resource_*` fields are usually empty (the notice is aggregated for the
bidding zone, not tied to a single facility).
"""
function aggregated_unavailability_of_consumption_units(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::Union{Nothing, AbstractString} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_unavailability;
        validate = validate, eics = (area,),
    ) do
        outages71_a_b_aggregated_unavailability_of_consumption_units(
            apis.outages, "A76", String(area),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
        )
    end
end

"""
    water_reservoirs_and_hydro_storage_plants(client, area, start, stop[, format])
      -> StructVector | String

Filling rate of hydro reservoirs and pumped-storage plants (Generation
16.1.D, `documentType=A72`, `processType=A16` — Realised). Quantities
in MWh of stored energy. Returns `StructVector{(time, value)}`.
"""
function water_reservoirs_and_hydro_storage_plants(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (area,),
    ) do
        generation161_d_water_reservoirs_and_hydro_storage_plants(
            apis.generation, "A72", "A16", String(area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

# ---------------------------------------------------------------------------
# Balancing

"""
    current_balancing_state(client, area, start, stop[, format];
                            business_type="B33") -> StructVector | String

Real-time area-control-error / imbalance state (Balancing 1.2.3.A,
`documentType=A86`). `business_type` defaults to `"B33"` (Area control
error). Returns `StructVector{(time, value)}` in MW — the cleared
imbalance for the area.
"""
function current_balancing_state(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::AbstractString = "B33",
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (area,),
    ) do
        balancing123_a_current_balancing_state_gl_eb(
            apis.balancing, "A86", String(business_type), String(area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

"""
    imbalance_prices(client, area, start, stop[, format]; psr_type=nothing)
      -> StructVector | String

Imbalance prices per imbalance settlement period (Balancing 17.1.G,
`documentType=A85`). The endpoint returns `application/zip`; the
wrapper unzips transparently and concatenates the XML members through
[`parse_timeseries`](@ref). Returns `StructVector{(time, value)}` in
EUR/MWh.

`psr_type` defaults to `nothing` (no filter); pass `"A04"` for
generation only.
"""
function imbalance_prices(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        psr_type::Union{Nothing, AbstractString} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing171_g_imbalance_prices(
            apis.balancing, "A85", String(area),
            _to_period(period_start), _to_period(period_end);
            psr_type = psr_type === nothing ? nothing : String(psr_type),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    cross_border_marginal_prices_for_afrr(client, control_area, period_start, period_end[, format];
                                          standard_market_product="A01")
      -> StructVector | String

Cross-border marginal prices (CBMPs) for aFRR central selection
(Balancing IF aFRR 3.1.6, `documentType=A84`, `processType=A67`,
`businessType=A96`). Returns the PICASSO clearing prices per control
area.
"""
function cross_border_marginal_prices_for_afrr(
        client::Client, control_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        standard_market_product::AbstractString = "A01",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing_if_afrr316_cross_border_marginal_prices_cbmps_for_afrr_central_selection_cs(
            apis.balancing, "A84", "A67", "A96",
            String(standard_market_product), String(control_area),
            _to_period(period_start), _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (control_area,),
    )
end

"""
    netted_and_exchanged_volumes(client, acquiring_domain, connecting_domain, period_start, period_end[, format];
                                 process_type="A63")
      -> StructVector | String

Netted and exchanged volumes between platforms (Balancing IF
3.10/3.16/3.17, `documentType=B17`). `process_type` default `"A63"`
(Imbalance Netting); pass `"A60"` (mFRR scheduled), `"A61"` (mFRR
direct), `"A67"` (aFRR central selection), etc.
"""
function netted_and_exchanged_volumes(
        client::Client,
        acquiring_domain::AbstractString, connecting_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A63",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing_ifs310316317_netted_and_exchanged_volumes(
            apis.balancing, "B17", String(process_type),
            String(acquiring_domain), String(connecting_domain),
            _to_period(period_start), _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (acquiring_domain, connecting_domain),
    )
end

"""
    netted_and_exchanged_volumes_per_border(client, acquiring_domain, connecting_domain, period_start, period_end[, format];
                                            process_type="A60")
      -> StructVector | String

Same data as [`netted_and_exchanged_volumes`](@ref) but published per
border (Balancing IF 3.10/3.16/3.17, `documentType=A30`). `process_type`
default `"A60"` (mFRR scheduled).
"""
function netted_and_exchanged_volumes_per_border(
        client::Client,
        acquiring_domain::AbstractString, connecting_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A60",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing_ifs310316317_netted_and_exchanged_volumes_per_border(
            apis.balancing, "A30", String(process_type),
            String(acquiring_domain), String(connecting_domain),
            _to_period(period_start), _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (acquiring_domain, connecting_domain),
    )
end

"""
    balancing_border_capacity_limitations(client, in_area, out_area, period_start, period_end[, format];
                                          business_type="A26", process_type="A47",
                                          registered_resource=nothing)
      -> StructVector | String

Balancing border capacity limitations (Balancing IF 4.3/4.4,
`documentType=A31`). `business_type` default `"A26"`; `process_type`
default `"A47"` (mFRR); pass `"A51"` (aFRR) or `"A63"` (Imbalance
Netting).
"""
function balancing_border_capacity_limitations(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::AbstractString = "A26",
        process_type::AbstractString = "A47",
        registered_resource::Union{Nothing, AbstractString} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing_ifs4344_balancing_border_capacity_limitations(
            apis.balancing, "A31",
            String(business_type), String(process_type),
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end);
            registered_resource = registered_resource === nothing ?
                nothing : String(registered_resource),
        ),
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    )
end

"""
    permanent_allocation_limitations_to_HVDC(client, in_area, out_area, period_start, period_end[, format];
                                             process_type="A63", business_type="B06",
                                             registered_resource=nothing)
      -> StructVector | String

Permanent allocation limitations on HVDC cross-border capacity
(Balancing IF 4.5, `documentType=A99`). `process_type` default `"A63"`
(Imbalance Netting); `business_type` default `"B06"`.
"""
function permanent_allocation_limitations_to_HVDC(
        client::Client,
        in_area::AbstractString, out_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A63",
        business_type::AbstractString = "B06",
        registered_resource::Union{Nothing, AbstractString} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing_ifs45_permanent_allocation_limitations_to_cross_border_capacity_on_hvdc_lines(
            apis.balancing, "A99",
            String(process_type), String(business_type),
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end);
            registered_resource = registered_resource === nothing ?
                nothing : String(registered_resource),
        ),
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    )
end

"""
    elastic_demands(client, acquiring_domain, period_start, period_end[, format];
                    process_type="A47") -> StructVector | String

Elastic-demand curves from IF platforms (Balancing IF aFRR 3.4 /
mFRR 3.4, `documentType=A37`, `businessType=B75`). `process_type`
default `"A47"` (mFRR); pass `"A51"` (aFRR).
"""
function elastic_demands(
        client::Client, acquiring_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A47",
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing_ifs_afrr34_mfrr34_elastic_demands(
            apis.balancing, "A37", "B75", String(process_type),
            String(acquiring_domain),
            _to_period(period_start), _to_period(period_end);
            offset = offset === nothing ? nothing : Int(offset),
        ),
        format, parse_timeseries;
        validate = validate, eics = (acquiring_domain,),
    )
end

"""
    changes_to_bid_availability(client, domain, period_start, period_end[, format];
                                process_type="A47", business_type=nothing,
                                offset=nothing) -> StructVector | String

Changes to bid availability published by IF platforms (Balancing IF
mFRR 9.9 / aFRR 9.6/9.8, `documentType=B45`). `process_type` default
`"A47"` (mFRR). Pass `business_type` like `"C46"` (Conditional bid),
`"C40"` (Thermal limit), etc.

For historical periods use [`changes_to_bid_availability_archives`](@ref).
"""
function changes_to_bid_availability(
        client::Client, domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A47",
        business_type::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing_ifs_mfrr99_afrr9698_changes_to_bid_availability(
            apis.balancing, "B45", String(process_type), String(domain),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
            offset = offset === nothing ? nothing : Int(offset),
        ),
        format, parse_timeseries;
        validate = validate, eics = (domain,),
    )
end

"""
    changes_to_bid_availability_archives(client, domain, period_start, period_end[, format];
                                         process_type="A47",
                                         storage_type="archive",
                                         business_type=nothing,
                                         offset=nothing) -> StructVector | String

Archived bid-availability changes (Balancing IF mFRR 9.9 / aFRR 9.6/9.8
archive variant).
"""
function changes_to_bid_availability_archives(
        client::Client, domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A47",
        storage_type::AbstractString = "archive",
        business_type::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing_ifs_mfrr99_afrr9698_changes_to_bid_availability_archives(
            apis.balancing, "B45", String(process_type), String(domain),
            _to_period(period_start), _to_period(period_end),
            String(storage_type);
            business_type = business_type === nothing ? nothing : String(business_type),
            offset = offset === nothing ? nothing : Int(offset),
        ),
        format, parse_timeseries;
        validate = validate, eics = (domain,),
    )
end

"""
    balancing_energy_bids(client, connecting_domain, period_start, period_end[, format];
                          process_type="A47",
                          direction=nothing,
                          standard_market_product=nothing,
                          original_market_product=nothing)
      -> StructVector | String

Raw balancing-energy bid stream (Balancing 1.2.3.B/C, `documentType=A37`,
`businessType=B74`). `process_type` default `"A47"` (mFRR); pass
`"A46"` (RR), `"A51"` (aFRR), etc. `direction` filters by `A01`
(Up) / `A02` (Down). Response is `application/zip`; `_query` unzips
and parses transparently.

For historical periods use
[`balancing_energy_bids_archives`](@ref).
"""
function balancing_energy_bids(
        client::Client, connecting_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A47",
        direction::Union{Nothing, AbstractString} = nothing,
        standard_market_product::Union{Nothing, AbstractString} = nothing,
        original_market_product::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing123_b_c_balancing_energy_bids(
            apis.balancing, "A37", "B74", String(process_type),
            String(connecting_domain),
            _to_period(period_start), _to_period(period_end);
            offset = offset === nothing ? nothing : Int(offset),
            standard_market_product = standard_market_product === nothing ?
                nothing : String(standard_market_product),
            original_market_product = original_market_product === nothing ?
                nothing : String(original_market_product),
            direction = direction === nothing ? nothing : String(direction),
        ),
        format, parse_timeseries;
        validate = validate, eics = (connecting_domain,),
    )
end

"""
    balancing_energy_bids_archives(client, connecting_domain, period_start, period_end[, format];
                                   process_type="A47",
                                   storage_type="archive",
                                   offset=nothing)
      -> StructVector | String

Archived balancing-energy bids (Balancing 1.2.3.B/C archive variant).
Same shape as [`balancing_energy_bids`](@ref); use for historical
periods. `storage_type` default `"archive"`.
"""
function balancing_energy_bids_archives(
        client::Client, connecting_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A47",
        storage_type::AbstractString = "archive",
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing123_b_c_balancing_energy_bids_archives(
            apis.balancing, "A37", "B74", String(process_type),
            String(connecting_domain),
            _to_period(period_start), _to_period(period_end),
            String(storage_type);
            offset = offset === nothing ? nothing : Int(offset),
        ),
        format, parse_timeseries;
        validate = validate, eics = (connecting_domain,),
    )
end

"""
    allocation_and_use_of_cross_zonal_balancing_capacity(client, acquiring_domain, connecting_domain, period_start, period_end[, format];
                                                         process_type="A46",
                                                         type_market_agreement_type=nothing)
      -> StructVector | String

Allocation and use of cross-zonal balancing capacity (Balancing
1.2.3.H/I, `documentType=A38`). `process_type` default `"A46"` (RR);
pass `"A47"` (mFRR), `"A51"` (aFRR), etc.
"""
function allocation_and_use_of_cross_zonal_balancing_capacity(
        client::Client,
        acquiring_domain::AbstractString, connecting_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A46",
        type_market_agreement_type::Union{Nothing, AbstractString} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing123_h_i_allocation_and_use_of_cross_zonal_balancing_capacity(
            apis.balancing, "A38", String(process_type),
            String(connecting_domain), String(acquiring_domain),
            _to_period(period_start), _to_period(period_end);
            type_market_agreement_type = type_market_agreement_type === nothing ?
                nothing : String(type_market_agreement_type),
        ),
        format, parse_timeseries;
        validate = validate, eics = (acquiring_domain, connecting_domain),
    )
end

"""
    results_of_criteria_application_process(client, area, period_start, period_end[, format];
                                            process_type="A47") -> StructVector | String

Results of the criteria-application process (Balancing 18.5.4 SO GL,
`documentType=A45`). `StructVector{(time, value)}` of TSO-quality
measurements. `process_type` default `"A47"` (mFRR).
"""
function results_of_criteria_application_process(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A47",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing1854_results_of_the_criteria_application_process_measurements_so_gl(
            apis.balancing, "A45", String(process_type), String(area),
            _to_period(period_start), _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    fcr_total_capacity(client, area, period_start, period_end[, format])
      -> StructVector | String

FCR total capacity (Balancing 18.7.2 SO GL, `documentType=A26`,
`businessType=A25`). Per area, in MW.
"""
function fcr_total_capacity(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing1872_fcr_total_capacity_so_gl(
            apis.balancing;
            document_type = "A26", business_type = "A25",
            area_domain = String(area),
            period_start = _to_period(period_start),
            period_end = _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    shares_of_fcr_capacity(client, area, period_start, period_end[, format])
      -> StructVector | String

Shares of FCR capacity (Balancing 18.7.2 SO GL, `documentType=A26`,
`businessType=C23`). Per area, in MW.
"""
function shares_of_fcr_capacity(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing1872_shares_of_fcr_capacity_so_gl(
            apis.balancing;
            document_type = "A26", business_type = "C23",
            area_domain = String(area),
            period_start = _to_period(period_start),
            period_end = _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    frr_rr_capacity_outlook(client, area, period_start, period_end[, format];
                            process_type="A56") -> StructVector | String

FRR/RR capacity outlook (Balancing 18.8.3/18.9.2 SO GL,
`documentType=A26`, `businessType=C76`). `process_type` default
`"A56"` (FRR); pass `"A46"` for RR.
"""
function frr_rr_capacity_outlook(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A56",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing18831892_frr_rr_capacity_outlook_so_gl(
            apis.balancing, "A26", String(process_type), "C76", String(area),
            _to_period(period_start), _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    frr_and_rr_actual_capacity(client, area, period_start, period_end[, format];
                               process_type="A56", business_type="C77")
      -> StructVector | String

FRR & RR actual capacity (Balancing 18.8.4/18.9.3 SO GL,
`documentType=A26`). `process_type` default `"A56"` (FRR);
`business_type` default `"C77"` (Min).
"""
function frr_and_rr_actual_capacity(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A56",
        business_type::AbstractString = "C77",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing18841893_frr_and_rr_actual_capacity_so_gl(
            apis.balancing, "A26", String(process_type), String(business_type),
            String(area), _to_period(period_start), _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    outlook_of_reserve_capacities_on_rr(client, area, period_start, period_end[, format])
      -> StructVector | String

Outlook of reserve capacities on RR (Balancing 18.9.2 SO GL,
`documentType=A26`, `processType=A46`, `businessType=C76`).
"""
function outlook_of_reserve_capacities_on_rr(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing1892_outlook_of_reserve_capacities_on_rr_so_gl(
            apis.balancing;
            document_type = "A26", process_type = "A46", business_type = "C76",
            area_domain = String(area),
            period_start = _to_period(period_start),
            period_end = _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    rr_actual_capacity(client, area, period_start, period_end[, format])
      -> StructVector | String

RR actual capacity (Balancing 18.9.3 SO GL, `documentType=A26`,
`processType=A46`, `businessType=C77`).
"""
function rr_actual_capacity(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing1893_rr_actual_capacity_so_gl(
            apis.balancing;
            document_type = "A26", process_type = "A46", business_type = "C77",
            area_domain = String(area),
            period_start = _to_period(period_start),
            period_end = _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    sharing_of_rr_and_frr(client, acquiring_domain, connecting_domain, period_start, period_end[, format];
                          process_type="A56") -> StructVector | String

Sharing of RR and FRR between connected areas (Balancing 19.0.1 SO GL,
`documentType=A26`, `businessType=C22`). `process_type` default
`"A56"` (FRR); pass `"A46"` for RR.
"""
function sharing_of_rr_and_frr(
        client::Client,
        acquiring_domain::AbstractString, connecting_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A56",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing1901_sharing_of_rr_and_frr_so_gl(
            apis.balancing;
            document_type = "A26", process_type = String(process_type),
            business_type = "C22",
            acquiring_domain = String(acquiring_domain),
            connecting_domain = String(connecting_domain),
            period_start = _to_period(period_start),
            period_end = _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (acquiring_domain, connecting_domain),
    )
end

"""
    sharing_of_fcr_between_sas(client, area, period_start, period_end[, format])
      -> StructVector | String

Sharing of FCR between scheduling areas (Balancing 19.0.2 SO GL,
`documentType=A26`, `processType=A52`, `businessType=C22`).
"""
function sharing_of_fcr_between_sas(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing1902_sharing_of_fcr_between_sas_so_gl(
            apis.balancing;
            document_type = "A26", process_type = "A52", business_type = "C22",
            area_domain = String(area),
            period_start = _to_period(period_start),
            period_end = _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    exchanged_reserve_capacity(client, acquiring_domain, connecting_domain, period_start, period_end[, format];
                               process_type="A46") -> StructVector | String

Exchanged balancing-reserve capacity between control areas
(Balancing 19.0.3 SO GL, `documentType=A26`, `businessType=C21`).
`process_type` default `"A46"` (Replacement reserve); pass `"A51"`
(aFRR), `"A52"` (mFRR), etc. for other reserve products.

`StructVector{(time, value)}` in MW.
"""
function exchanged_reserve_capacity(
        client::Client,
        acquiring_domain::AbstractString, connecting_domain::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A46",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing1903_exchanged_reserve_capacity_so_gl(
            apis.balancing;
            document_type = "A26",
            process_type = String(process_type),
            business_type = "C21",
            acquiring_domain = String(acquiring_domain),
            connecting_domain = String(connecting_domain),
            period_start = _to_period(period_start),
            period_end = _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (acquiring_domain, connecting_domain),
    )
end

"""
    volumes_and_prices_of_contracted_reserves(client, control_area, period_start, period_end[, format];
                                              type_market_agreement_type="A01",
                                              process_type=nothing,
                                              psr_type=nothing,
                                              offset=nothing)
      -> StructVector | String

Volumes and prices of contracted balancing reserves (Balancing 17.1.B/C,
`documentType=A81`, `businessType=B95`). `type_market_agreement_type`
default `"A01"` (Daily); pass `"A02"` (Weekly), `"A03"` (Monthly),
`"A04"` (Yearly), `"A13"` (Hourly).

Optional kwargs:
  - `process_type` — `"A51"` (aFRR), `"A52"` (FCR), `"A47"` (mFRR),
    `"A46"` (RR)
  - `psr_type` — `"A03"` (Mixed), `"A04"` (Generation), `"A05"` (Load)

Mirrors entsoe-py's `query_contracted_reserve_{amount,prices}`.
"""
function volumes_and_prices_of_contracted_reserves(
        client::Client, control_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        type_market_agreement_type::AbstractString = "A01",
        process_type::Union{Nothing, AbstractString} = nothing,
        psr_type::Union{Nothing, AbstractString} = nothing,
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing171_b_c_volumes_and_prices_of_contracted_reserves(
            apis.balancing, "A81", "B95",
            String(type_market_agreement_type), String(control_area),
            _to_period(period_start), _to_period(period_end);
            process_type = process_type === nothing ? nothing : String(process_type),
            psr_type = psr_type === nothing ? nothing : String(psr_type),
            offset = offset === nothing ? nothing : Int(offset),
        ),
        format, parse_timeseries;
        validate = validate, eics = (control_area,),
    )
end

"""
    financial_expenses_and_income_for_balancing(client, control_area, period_start, period_end[, format])
      -> StructVector | String

Financial expenses and income for balancing (Balancing 17.1.I,
`documentType=A87`). Monetary flows aggregated per control area;
`StructVector{(time, value)}` in EUR.
"""
function financial_expenses_and_income_for_balancing(
        client::Client, control_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing171_i_financial_expenses_and_income_for_balancing(
            apis.balancing, "A87", String(control_area),
            _to_period(period_start), _to_period(period_end),
        ),
        format, parse_timeseries;
        validate = validate, eics = (control_area,),
    )
end

"""
    prices_of_activated_balancing_energy(client, control_area, period_start, period_end[, format];
                                         process_type="A16",
                                         business_type=nothing,
                                         psr_type=nothing,
                                         standard_market_product=nothing,
                                         original_market_product=nothing)
      -> StructVector | String

Prices of activated balancing energy (Balancing 17.1.F,
`documentType=A84`). One row per published settlement period —
`StructVector{(time, value)}` in EUR/MWh. Response is
`application/zip`; the wrapper unzips and parses transparently.

`process_type` defaults to `"A16"` (Realised). Pass `business_type` /
`psr_type` / market-product strings to filter server-side. Mirrors
entsoe-py's `query_activated_balancing_energy_prices`.
"""
function prices_of_activated_balancing_energy(
        client::Client, control_area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A16",
        business_type::Union{Nothing, AbstractString} = nothing,
        psr_type::Union{Nothing, AbstractString} = nothing,
        standard_market_product::Union{Nothing, AbstractString} = nothing,
        original_market_product::Union{Nothing, AbstractString} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing171_f_prices_of_activated_balancing_energy(
            apis.balancing, "A84", String(process_type), String(control_area),
            _to_period(period_start), _to_period(period_end);
            business_type = business_type === nothing ? nothing : String(business_type),
            psr_type = psr_type === nothing ? nothing : String(psr_type),
            standard_market_product = standard_market_product === nothing ?
                nothing : String(standard_market_product),
            original_market_product = original_market_product === nothing ?
                nothing : String(original_market_product),
        ),
        format, parse_timeseries;
        validate = validate, eics = (control_area,),
    )
end

"""
    total_imbalance_volumes(client, area, start, stop[, format]; business_type="A19")
      -> StructVector | String

Total imbalance volumes per settlement period (Balancing 17.1.H,
`documentType=A86`). Like [`imbalance_prices`](@ref), the response is
`application/zip` — unzipped and parsed transparently. Returns
`StructVector{(time, value)}` in MW.

`business_type` defaults to `"A19"` (Balance energy deviation).
"""
function total_imbalance_volumes(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        business_type::AbstractString = "A19",
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing171_h_total_imbalance_volumes(
            apis.balancing, "A86", String(area),
            _to_period(period_start), _to_period(period_end);
            business_type = String(business_type),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    procured_balancing_capacity(client, area, period_start[, period_end, format];
                                process_type="A51",
                                type_market_agreement_type="A01",
                                offset=nothing) -> StructVector | String

Procured balancing capacity volumes (Balancing 1.2.3.F,
`documentType=A15`). The underlying endpoint takes a *single*
`period_start` and an optional `period_end`; both are accepted here.
Response is `application/zip` and is unzipped transparently.

`process_type` defaults to `"A51"` (aFRR); pass `"A47"` for mFRR.
`type_market_agreement_type` defaults to `"A01"` (daily).
"""
function procured_balancing_capacity(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A51",
        type_market_agreement_type::AbstractString = "A01",
        offset::Union{Nothing, Integer} = nothing,
    )
    apis = entsoe_apis(client)
    return _query(
        () -> balancing123_f_procured_balancing_capacity_gl_eb(
            apis.balancing, "A15", String(process_type), String(area),
            _to_period(period_start);
            period_end = period_end === nothing ? nothing : _to_period(period_end),
            type_market_agreement_type = String(type_market_agreement_type),
            offset = offset === nothing ? nothing : Int(offset),
        ),
        format, parse_timeseries;
        validate = validate, eics = (area,),
    )
end

"""
    aggregated_balancing_energy_bids(client, area, start, stop[, format];
                                     process_type="A51") -> StructVector | String

Aggregated balancing-energy bid volumes (Balancing 1.2.3.E,
`documentType=A24`). `process_type` defaults to `"A51"` (Automatic
frequency restoration reserve — aFRR); pass `"A47"` for mFRR or
`"A46"` for RR. Returns `StructVector{(time, value)}` of bid volumes
in MW.
"""
function aggregated_balancing_energy_bids(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
        process_type::AbstractString = "A51",
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (area,),
    ) do
        balancing123_e_aggregated_balancing_energy_bids_gl_eb(
            apis.balancing, "A24", String(process_type), String(area),
            _to_period(period_start), _to_period(period_end),
        )
    end
end

# ---------------------------------------------------------------------------
# OMI — paginated. Always returns Vector{String} (one XML page per
# response); the `ResponseFormat` switch doesn't apply because there's
# no single "parsed" shape — different document types live behind this
# endpoint. Users parse pages with `parse_timeseries` etc. as needed.

"""
    omi_other_market_information(client, control_area, start, stop;
                                  document_type="A95", page_size=200,
                                  max_pages=25, validate=false)

Walk the OMI ("Other Market Information") endpoint with automatic
offset-based pagination. Each call to the underlying generated
function returns up to `page_size` documents (ENTSO-E hard-caps OMI
queries at 5000 entries total — `max_pages * page_size` defaults to
exactly that).

Returns a `Vector{String}` of XML payloads, one per page. Stops when a
page comes back as an [`ENTSOEAcknowledgement`](@ref) (no more data)
or when `max_pages` is reached.

```julia
xmls = omi_other_market_information(
    client, EIC.NL,
    DateTime("2024-09-01T22:00"), DateTime("2024-09-30T22:00"),
)
# Each entry is a separate <Anomalies_MarketDocument> chunk; users
# parse them however they need (often with `parse_timeseries` or the
# raw XML).
```
"""
function omi_other_market_information(
        client::Client, control_area::AbstractString,
        period_start, period_end;
        document_type::AbstractString = "A95",
        page_size::Int = 200,
        max_pages::Int = 25,
        validate::Bool = false,
    )
    validate && validate_eic(control_area; type = :CTA)
    apis = entsoe_apis(client)
    dt = String(document_type)::String
    ca = String(control_area)::String
    ps = _to_period(period_start)::Int64
    pe = _to_period(period_end)::Int64
    pages = String[]
    for i in 0:(max_pages - 1)
        offset = i * page_size
        xml, _ = ENTSOEAPI.omi_other_market_information(
            apis.omi, dt, ca, ps, pe;
            offset = offset,
        )
        # End-of-pagination signal is an Acknowledgement reason 999.
        ack = parse_acknowledgement(xml)
        if ack !== nothing
            i == 0 && throw(ack)   # acknowledgement on the first page is real
            break
        end
        push!(pages, xml)
    end
    return pages
end
