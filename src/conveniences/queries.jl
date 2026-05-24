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

using Dates: Dates, DateTime, Date

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
function _query(api_call::Function, ::Parsed, parser::F; kw...) where {F <: Function}
    # `check_ack = false` because binary zip bytes break the XML parser
    # `check_acknowledgement` uses; we re-run the check per-member.
    xml = _query_xml(api_call; check_ack = false, kw...)
    if _looks_like_zip(xml)
        members = unzip_response(Vector{UInt8}(codeunits(xml)))
        isempty(members) && return parser("")
        parts = map(members) do (_name, bytes)
            inner = String(copy(bytes))
            check_acknowledgement(inner)   # raises if a member is an Ack doc
            parser(inner)
        end
        return reduce(vcat, parts)
    end
    check_acknowledgement(xml)
    return parser(xml)
end

function _query(api_call::Function, ::Raw, ::F; kw...) where {F <: Function}
    xml = _query_xml(api_call; check_ack = false, kw...)
    if _looks_like_zip(xml)
        members = unzip_response(Vector{UInt8}(codeunits(xml)))
        return join(
            (String(copy(b)) for (_n, b) in members),
            "\n<!-- next zip member -->\n"
        )
    end
    check_acknowledgement(xml)
    return xml
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
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(format, parse_timeseries; validate = validate, eics = (area,)) do
        market121_d_energy_prices(
            apis.market, "A44",
            _to_period(period_start), _to_period(period_end),
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
    )
    apis = entsoe_apis(client)
    return _query(format, parse_timeseries; validate = validate, eics = (area,)) do
        market121_d_energy_prices(
            apis.market, "A44",
            _to_period(period_start), _to_period(period_end),
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
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    ) do
        market121_b_total_nominated_capacity(
            apis.market, "A26", "B08",
            String(out_area), String(in_area),
            _to_period(period_start);
            period_end = period_end === nothing ? nothing : _to_period(period_end),
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
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (in_area, out_area),
    ) do
        market121_e_implicit_and_flow_based_allocations_congestion_income(
            apis.market, "A25", "B10",
            String(contract_market_agreement_type),
            String(out_area), String(in_area),
            _to_period(period_start), _to_period(period_end),
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
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries;
        validate = validate, eics = (area,),
    ) do
        market121_e_implicit_auction_net_positions(
            apis.market, "A25", "B09",
            String(contract_market_agreement_type),
            String(area), String(area),
            _to_period(period_start), _to_period(period_end),
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
        validate::Bool,
        api_fn::Function,
    )
    apis = entsoe_apis(client)
    return _query(format, parse_timeseries; validate = validate, eics = (area,)) do
        api_fn(
            apis.load, "A65", String(process), String(area),
            _to_period(period_start), _to_period(period_end),
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
    validate = false,
) = _load_query(
    client, "A16", area, start, stop, format;
    validate = validate, api_fn = load61_a_actual_total_load,
)

"""
    day_ahead_load_forecast(client, area, start, stop[, format]) -> StructVector | String

Day-ahead total load forecast (Load 6.1.B, `processType=A01`).
"""
day_ahead_load_forecast(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false,
) = _load_query(
    client, "A01", area, start, stop, format;
    validate = validate, api_fn = load61_b_day_ahead_total_load_forecast,
)

"""
    week_ahead_load_forecast(client, area, start, stop[, format]) -> StructVector | String

Week-ahead total load forecast (Load 6.1.C, `processType=A31`).
"""
week_ahead_load_forecast(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false,
) = _load_query(
    client, "A31", area, start, stop, format;
    validate = validate, api_fn = load61_c_week_ahead_total_load_forecast,
)

"""
    month_ahead_load_forecast(client, area, start, stop[, format]) -> StructVector | String

Month-ahead total load forecast (Load 6.1.D, `processType=A32`).
"""
month_ahead_load_forecast(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false,
) = _load_query(
    client, "A32", area, start, stop, format;
    validate = validate, api_fn = load61_d_month_ahead_total_load_forecast,
)

"""
    year_ahead_load_forecast(client, area, start, stop[, format]) -> StructVector | String

Year-ahead total load forecast (Load 6.1.E, `processType=A33`).
"""
year_ahead_load_forecast(
    client::Client, area, start, stop, format::ResponseFormat = Parsed();
    validate = false,
) = _load_query(
    client, "A33", area, start, stop, format;
    validate = validate, api_fn = load61_e_year_ahead_total_load_forecast,
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
    )
    apis = entsoe_apis(client)
    return _query(format, parse_timeseries; validate = validate, eics = (area,)) do
        load81_year_ahead_forecast_margin(
            apis.load, "A70", "A33", String(area),
            _to_period(period_start), _to_period(period_end),
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
    generation_forecast_day_ahead(client, area, start, stop[, format]) -> StructVector | String

Day-ahead total generation forecast (Generation 14.1.C,
`documentType=A71`, `processType=A01`). Returns
`StructVector{(time, value)}` in MW.
"""
function generation_forecast_day_ahead(
        client::Client, area::AbstractString,
        period_start, period_end, format::ResponseFormat = Parsed();
        validate::Bool = false,
    )
    apis = entsoe_apis(client)
    return _query(format, parse_timeseries; validate = validate, eics = (area,)) do
        generation141_c_generation_forecast_day_ahead(
            apis.generation, "A71", "A01", String(area),
            _to_period(period_start), _to_period(period_end),
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
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries_per_psr;
        validate = validate, eics = (area,),
    ) do
        generation141_d_generation_forecasts_for_wind_and_solar(
            apis.generation, "A69", "A01", String(area),
            _to_period(period_start), _to_period(period_end);
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
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries_per_psr;
        validate = validate, eics = (area,),
    ) do
        generation141_d_generation_forecasts_for_wind_and_solar(
            apis.generation, "A69", "A40", String(area),
            _to_period(period_start), _to_period(period_end);
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
    )
    apis = entsoe_apis(client)
    return _query(
        format, parse_timeseries_per_psr;
        validate = validate, eics = (area,),
    ) do
        generation161_b_c_actual_generation_per_production_type(
            apis.generation, "A75", "A16", String(area),
            _to_period(period_start), _to_period(period_end);
            psr_type = psr_type === nothing ? nothing : String(psr_type),
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
            doc_status = doc_status === nothing ? nothing : String(doc_status),
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
            doc_status = doc_status === nothing ? nothing : String(doc_status),
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
            doc_status = doc_status === nothing ? nothing : String(doc_status),
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
