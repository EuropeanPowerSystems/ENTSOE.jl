# XML response parsing for ENTSO-E documents.
#
# Every Transparency Platform endpoint returns `application/xml` — the
# generated wrapper functions hand it back as a `String`. This file lifts
# the most common shapes into Julia data structures.
#
# We don't try to model the full IEC 62325 schema (200+ document types,
# many revisions). Instead we walk the DOM with EzXML and extract the
# fields that almost every TimeSeries document carries. Users who need
# field access we don't expose can still drop down to EzXML directly via
# `parsexml(xml)` — the strings we return are unmodified.

using EzXML: EzXML, parsexml, root, elements, nodename, nodecontent
using Dates: Dates, DateTime, Minute
using StructArrays: StructArray, StructArrays
using ZipFile: ZipFile

# ---------------------------------------------------------------------------
# Internal helpers — DOM walking with namespace-agnostic name matching.
# ENTSO-E XML uses default-namespaced documents, which makes XPath queries
# clunky; `nodename` strips the prefix so a plain comparison works.

_named(el::EzXML.Node, name::AbstractString) =
    [c for c in elements(el) if nodename(c) == name]

function _first_named(el::EzXML.Node, name::AbstractString)
    for c in elements(el)
        nodename(c) == name && return c
    end
    return nothing
end

# Resolve the most common ISO-8601 durations the API uses to whole minutes.
# These cover every resolution observed across the eight Transparency
# Platform groups; sub-minute resolutions (PT1S, PT4S etc.) are not
# supported because they'd round-trip lossily through `Minute(...)`.
function _resolution_minutes(s::AbstractString)
    s == "PT1M"   && return 1     # 1.2.3.A current balancing state, 17.1.G imbalance prices
    s == "PT5M"   && return 5
    s == "PT10M"  && return 10
    s == "PT15M"  && return 15
    s == "PT30M"  && return 30
    s == "PT60M"  && return 60
    s == "PT1H"   && return 60
    s == "P1D"    && return 60 * 24
    s == "P7D"    && return 60 * 24 * 7
    s == "P1M"    && return 60 * 24 * 30   # nominal
    s == "P1Y"    && return 60 * 24 * 365  # nominal
    # Unknown resolution — most likely a new ISO-8601 duration ENTSO-E
    # has started emitting (or a sub-minute resolution we can't round-trip
    # losslessly through `Minute(...)`). Warn once per call site and
    # return `nothing` so the parser drops the offending Period rather
    # than crashing an entire batch import.
    @warn "ENTSOE: unsupported resolution `$s` — skipping Period. " *
        "Please open an issue at https://github.com/EuropeanPowerSystems/ENTSOE.jl/issues " *
        "so this resolution can be added to the table." maxlog = 1 _id = Symbol(s)
    return nothing
end

# ENTSO-E ISO timestamps look like `2024-09-01T22:00Z`. Drop the trailing
# `Z` (`DateTime` is naive, parsed values are always interpreted as UTC).
_parse_entsoe_datetime(s::AbstractString) = DateTime(s[1:min(end, 16)])

# A `<Point>` carries its numeric value in one of several differently-named
# child elements: `<quantity>` (load/generation/flows/capacity/balancing
# volumes), `<price.amount>` (Market 12.1.D), `<congestionCost_Price.amount>`
# (Transmission 13.1.C), `<imbalancePrice_Price.amount>` (Balancing 17.1.G),
# etc. Rather than enumerating every variant, pick the first child whose
# name is exactly `quantity` or ends in `.amount`. Returns `nothing` if no
# such child exists.
function _point_value_node(pt::EzXML.Node)
    for c in elements(pt)
        n = nodename(c)
        (n == "quantity" || endswith(n, ".amount")) && return c
    end
    return nothing
end

# The `<curveType>` of a `<TimeSeries>` (or `<Available_Period>` parent),
# e.g. `A01` (sequential, every point present) or `A03` (variable-sized
# block, unchanged points omitted). Empty string when absent.
_curve_type(node::EzXML.Node) =
let n = _first_named(node, "curveType")
    n === nothing ? "" : strip(nodecontent(n))
end

# Total number of resolution steps a `<Period>` spans, derived from its
# `<timeInterval>` (`end - start`) and the per-step `stride` in minutes.
# Returns `nothing` when the interval has no parseable `<end>` — in which
# case the final A03 block can't be extended past its listed position.
function _period_npoints(ti::EzXML.Node, start::DateTime, stride::Int)
    end_node = _first_named(ti, "end")
    end_node === nothing && return nothing
    stop = _parse_entsoe_datetime(nodecontent(end_node))
    stop <= start && return nothing
    total_minutes = div(Dates.value(stop - start), 60_000)   # ms → minutes
    return div(total_minutes, stride)
end

# Expand one `<Period>`'s listed `(position, value)` points into per-step
# `(time, value)` columns. ENTSO-E's variable-sized-block encoding
# (`curveType` `A03`) omits unchanged points: a point at position `p` holds
# until the next listed position, and the last point holds to the period's
# end (`npoints`). When `expand` (the caller's `fill_gaps && curveType==A03`),
# every step in those runs gets a row; otherwise only the literal points are
# emitted — leaving sequential (`A01`) documents untouched.
function _expand_period(
        positions::Vector{Int}, vals::Vector{Float64},
        start::DateTime, stride::Int, npoints::Union{Int, Nothing}, expand::Bool,
    )
    times = DateTime[]
    values = Float64[]
    n = length(positions)
    n == 0 && return (times, values)
    if !expand
        for i in 1:n
            push!(times, start + Minute((positions[i] - 1) * stride))
            push!(values, vals[i])
        end
        return (times, values)
    end
    for i in 1:n
        p = positions[i]
        stop_pos = if i < n
            positions[i + 1] - 1
        else
            npoints === nothing ? p : max(p, npoints)
        end
        for pos in p:stop_pos
            push!(times, start + Minute((pos - 1) * stride))
            push!(values, vals[i])
        end
    end
    return (times, values)
end

# ---------------------------------------------------------------------------
# Public parsers

"""
    parse_timeseries(xml) -> StructVector{@NamedTuple{time::DateTime, value::Float64}}

Walk every `<TimeSeries>/<Period>/<Point>` in the document and produce a
[Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible
[`StructVector`](https://github.com/JuliaArrays/StructArrays.jl) with
two columns:

- `time`  — `DateTime` (UTC) computed from `<timeInterval>/<start>` plus
  `(position - 1) * resolution`
- `value` — `Float64` from `<quantity>` (load, generation, capacity,
  balancing volumes) or `<price.amount>` (price documents), whichever
  the point carries.

The result indexes like a `Vector{NamedTuple}` (`prices[1].value`) and
also exposes columns directly (`prices.value`, `prices.time` —
`Vector{Float64}` / `Vector{DateTime}`). It plumbs straight into
DataFrames (`DataFrame(prices)`) and any other Tables.jl consumer.

Returns an empty `StructVector` if the document has no usable TimeSeries
— typically because the API returned an
[`ENTSOEAcknowledgement`](@ref). For typed handling of that case use a
pipeline that calls [`check_acknowledgement`](@ref) first.

## Sparse (`curveType` `A03`) series and `fill_gaps`

ENTSO-E often emits *variable-sized block* series (`<curveType>A03`) in
which **unchanged points are omitted**: a `<Point>` at position `p`
holds its value until the next listed position, and the final point
holds until the period's `<timeInterval>/<end>`. Read literally this
leaves gaps in the `time` column (e.g. a jump from 17:00 straight to
19:00). With `fill_gaps = true` (the default, taken from
[`get_config`](@ref)`().fill_gaps`) the parser forward-fills those runs
so every resolution step gets a row; pass `fill_gaps = false` to keep
only the literal points. For dense (`A01`) series the expansion is a
no-op. Toggle the default globally with
[`set_config`](@ref)`(; fill_gaps = false)`.

# Example
```julia
using ENTSOE, Dates

client = ENTSOEClient(ENV["ENTSOE_API_TOKEN"])
prices = day_ahead_prices(client, EIC.NL,
    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"))

prices[1]      # → (time = DateTime("2024-09-01T22:00"), value = 91.24)
prices.value   # Vector{Float64} of all 24 prices
mean(prices.value)
DataFrame(prices)
```
"""
function parse_timeseries(xml::AbstractString; fill_gaps::Bool = get_config().fill_gaps)
    times = DateTime[]
    values = Float64[]
    doc = parsexml(xml)
    for ts in _named(root(doc), "TimeSeries")
        expand = fill_gaps && _curve_type(ts) == "A03"
        for period in _named(ts, "Period")
            ti = _first_named(period, "timeInterval")
            ti === nothing && continue
            start_node = _first_named(ti, "start")
            start_node === nothing && continue
            start = _parse_entsoe_datetime(nodecontent(start_node))

            res_node = _first_named(period, "resolution")
            res_node === nothing && continue
            stride = _resolution_minutes(nodecontent(res_node))
            stride === nothing && continue   # warned + skip this Period

            positions = Int[]
            vals = Float64[]
            for pt in _named(period, "Point")
                pos_node = _first_named(pt, "position")
                pos_node === nothing && continue
                vnode = _point_value_node(pt)
                vnode === nothing && continue
                push!(positions, parse(Int, nodecontent(pos_node)))
                push!(vals, parse(Float64, nodecontent(vnode)))
            end
            npoints = _period_npoints(ti, start, stride)
            ptimes, pvalues = _expand_period(positions, vals, start, stride, npoints, expand)
            append!(times, ptimes)
            append!(values, pvalues)
        end
    end
    return StructArray((time = times, value = values))
end

"""
    parse_timeseries_per_psr(xml) -> StructVector{@NamedTuple{time::DateTime, psr_type::String, value::Float64}}

Like [`parse_timeseries`](@ref), but additionally extracts the
`<MktPSRType>/<psrType>` from each `<TimeSeries>` and tags every point
with it. Useful for documents that split data per production type, like
14.1.D (wind & solar forecast) and 16.1.B/C (actual generation per
production type) — where one TimeSeries holds Solar, another Wind
Onshore, etc.

Points without a `<MktPSRType>` get `psr_type = ""`.

The return value is a Tables.jl-compatible `StructVector` — index
rows (`rows[1]`), or pull a column (`rows.value`, `rows.psr_type`).

# Example
```julia
rows = actual_generation_per_production_type(client, EIC.NL,
    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"))

# Pivot a column out:
solar_only = rows[rows.psr_type .== "B16"]
solar_only.value
```
"""
function parse_timeseries_per_psr(xml::AbstractString; fill_gaps::Bool = get_config().fill_gaps)
    times = DateTime[]
    psr_types = String[]
    values = Float64[]
    doc = parsexml(xml)
    for ts in _named(root(doc), "TimeSeries")
        psrwrap = _first_named(ts, "MktPSRType")
        psr = if psrwrap === nothing
            ""
        else
            n = _first_named(psrwrap, "psrType")
            n === nothing ? "" : nodecontent(n)
        end
        expand = fill_gaps && _curve_type(ts) == "A03"
        for period in _named(ts, "Period")
            ti = _first_named(period, "timeInterval")
            ti === nothing && continue
            start_node = _first_named(ti, "start")
            start_node === nothing && continue
            start = _parse_entsoe_datetime(nodecontent(start_node))
            res_node = _first_named(period, "resolution")
            res_node === nothing && continue
            stride = _resolution_minutes(nodecontent(res_node))
            stride === nothing && continue   # warned + skip

            positions = Int[]
            vals = Float64[]
            for pt in _named(period, "Point")
                pos_node = _first_named(pt, "position")
                pos_node === nothing && continue
                vnode = _point_value_node(pt)
                vnode === nothing && continue
                push!(positions, parse(Int, nodecontent(pos_node)))
                push!(vals, parse(Float64, nodecontent(vnode)))
            end
            npoints = _period_npoints(ti, start, stride)
            ptimes, pvalues = _expand_period(positions, vals, start, stride, npoints, expand)
            append!(times, ptimes)
            append!(psr_types, fill(psr, length(ptimes)))
            append!(values, pvalues)
        end
    end
    return StructArray((time = times, psr_type = psr_types, value = values))
end

"""
    parse_installed_capacity(xml) -> StructVector{@NamedTuple{psr_type::String, capacity_mw::Float64}}

Parse a 14.1.A "Installed Capacity per Production Type" document.
Returns one row per `<TimeSeries>` — each contains a single
`<MktPSRType>/<psrType>` (e.g. `"B16"` for Solar) and a `<Period>`
with one `<Point>` carrying the year-ahead declared capacity in MW.

Tables.jl-compatible `StructVector`. Pull a column directly with
`rows.capacity_mw` (`Vector{Float64}`) or `rows.psr_type`
(`Vector{String}`); convert with `DataFrame(rows)`.

The `psr_type` codes are documented in [`PSR_TYPE`](@ref); pass through
[`describe(PSR_TYPE, code)`](@ref describe) for human-readable labels.

# Example
```julia
rows = installed_capacity_per_production_type(client, EIC.NL,
    DateTime("2024-12-31T23:00"), DateTime("2025-12-31T23:00"))

rows[1]              # → (psr_type = "B01", capacity_mw = 580.0)
rows.capacity_mw     # 14-element Vector{Float64}
sum(rows.capacity_mw)
```
"""
function parse_installed_capacity(xml::AbstractString)
    psr_types = String[]
    caps = Float64[]
    doc = parsexml(xml)
    for ts in _named(root(doc), "TimeSeries")
        psrwrap = _first_named(ts, "MktPSRType")
        psrwrap === nothing && continue
        psr_node = _first_named(psrwrap, "psrType")
        psr_node === nothing && continue
        psr = nodecontent(psr_node)

        period = _first_named(ts, "Period")
        period === nothing && continue
        for pt in _named(period, "Point")
            qty = _first_named(pt, "quantity")
            qty === nothing && continue
            push!(psr_types, psr)
            push!(caps, parse(Float64, nodecontent(qty)))
        end
    end
    return StructArray((psr_type = psr_types, capacity_mw = caps))
end

"""
    parse_installed_capacity_per_unit(xml) -> StructVector{@NamedTuple{
        unit_mrid::String, unit_name::String, psr_type::String,
        capacity_mw::Float64}}

Parse a 14.1.B "Installed Capacity per Production Unit" document. One
row per `<TimeSeries>` (one per unit), with fields:

  - `unit_mrid`    — `<registeredResource.mRID>`, the unit's EIC
  - `unit_name`    — `<registeredResource.name>`
  - `psr_type`     — `<MktPSRType><psrType>` (e.g. `B19` Wind Onshore)
  - `capacity_mw`  — `<Period>/<Point>/<quantity>`, year-ahead declared
                     capacity in MW

Tables.jl-compatible `StructVector`; pull columns directly with
`rows.capacity_mw` or `DataFrame(rows)`.
"""
function parse_installed_capacity_per_unit(xml::AbstractString)
    unit_mrids = String[]
    unit_names = String[]
    psr_types = String[]
    caps = Float64[]
    doc = parsexml(xml)
    for ts in _named(root(doc), "TimeSeries")
        mrid = _first_text(ts, "registeredResource.mRID")
        name = _first_text(ts, "registeredResource.name")

        psrwrap = _first_named(ts, "MktPSRType")
        psr = if psrwrap === nothing
            ""
        else
            n = _first_named(psrwrap, "psrType")
            n === nothing ? "" : nodecontent(n)
        end

        period = _first_named(ts, "Period")
        period === nothing && continue
        for pt in _named(period, "Point")
            qty = _first_named(pt, "quantity")
            qty === nothing && continue
            push!(unit_mrids, mrid)
            push!(unit_names, name)
            push!(psr_types, psr)
            push!(caps, parse(Float64, nodecontent(qty)))
        end
    end
    return StructArray(
        (
            unit_mrid = unit_mrids,
            unit_name = unit_names,
            psr_type = psr_types,
            capacity_mw = caps,
        )
    )
end

"""
    parse_timeseries_per_unit(xml) -> StructVector{@NamedTuple{
        time::DateTime, unit_mrid::String, unit_name::String,
        psr_type::String, value::Float64}}

Parse a per-generation-unit time-series document — used by 16.1.A
"Actual Generation per Generation Unit". One row per `<Point>`,
tagged with the parent generating unit's mRID and name (extracted
from `<MktPSRType>/<PowerSystemResources>`) plus the PSR type.
"""
function parse_timeseries_per_unit(xml::AbstractString; fill_gaps::Bool = get_config().fill_gaps)
    times = DateTime[]
    unit_mrids = String[]
    unit_names = String[]
    psr_types = String[]
    values = Float64[]
    doc = parsexml(xml)
    for ts in _named(root(doc), "TimeSeries")
        psrwrap = _first_named(ts, "MktPSRType")
        psr = ""
        unit_mrid = ""
        unit_name = ""
        if psrwrap !== nothing
            n = _first_named(psrwrap, "psrType")
            psr = n === nothing ? "" : nodecontent(n)
            psr_block = _first_named(psrwrap, "PowerSystemResources")
            if psr_block !== nothing
                unit_mrid = _first_text(psr_block, "mRID")
                unit_name = _first_text(psr_block, "name")
            end
        end
        # Fall back to top-level `registeredResource.*` if the
        # per-PSR `PowerSystemResources` block is absent.
        if isempty(unit_mrid)
            unit_mrid = _first_text(ts, "registeredResource.mRID")
        end
        if isempty(unit_name)
            unit_name = _first_text(ts, "registeredResource.name")
        end

        expand = fill_gaps && _curve_type(ts) == "A03"
        for period in _named(ts, "Period")
            ti = _first_named(period, "timeInterval")
            ti === nothing && continue
            start_node = _first_named(ti, "start")
            start_node === nothing && continue
            start = _parse_entsoe_datetime(nodecontent(start_node))
            res_node = _first_named(period, "resolution")
            res_node === nothing && continue
            stride = _resolution_minutes(nodecontent(res_node))
            stride === nothing && continue

            positions = Int[]
            vals = Float64[]
            for pt in _named(period, "Point")
                pos_node = _first_named(pt, "position")
                pos_node === nothing && continue
                vnode = _point_value_node(pt)
                vnode === nothing && continue
                push!(positions, parse(Int, nodecontent(pos_node)))
                push!(vals, parse(Float64, nodecontent(vnode)))
            end
            npoints = _period_npoints(ti, start, stride)
            ptimes, pvalues = _expand_period(positions, vals, start, stride, npoints, expand)
            m = length(ptimes)
            append!(times, ptimes)
            append!(unit_mrids, fill(unit_mrid, m))
            append!(unit_names, fill(unit_name, m))
            append!(psr_types, fill(psr, m))
            append!(values, pvalues)
        end
    end
    return StructArray(
        (
            time = times,
            unit_mrid = unit_mrids,
            unit_name = unit_names,
            psr_type = psr_types,
            value = values,
        )
    )
end

# ---------------------------------------------------------------------------
# Unavailability_MarketDocument — outage notifications.
#
# Used by Outages 15.1.A/B (generation units), 15.1.C/D (production units),
# 10.1.A/B (transmission infrastructure), and 7.1.A/B (aggregated consumption
# units). All variants share the same per-TimeSeries metadata shape; we
# extract the one-row-per-outage summary that most users want and leave the
# per-15-minute curtailment curve to callers who reach for `Raw()`.

_first_text(el::EzXML.Node, name::AbstractString) =
let n = _first_named(el, name)
    n === nothing ? "" : strip(nodecontent(n))
end

# Outage time bounds can be expressed two ways: as separate
# `start_DateAndOrTime.{date,time}` siblings on the TimeSeries, or as a
# `timeInterval/start` nested under an `Available_Period`. Try both;
# return `nothing` if neither yields a parseable datetime.
function _outage_datetime(ts::EzXML.Node, which::Symbol)
    @assert which in (:start, :stop)
    date_field = which === :start ? "start_DateAndOrTime.date" : "end_DateAndOrTime.date"
    time_field = which === :start ? "start_DateAndOrTime.time" : "end_DateAndOrTime.time"

    date = _first_text(ts, date_field)
    if !isempty(date)
        time = _first_text(ts, time_field)
        # Time often ends `Z`; `_parse_entsoe_datetime` already strips it.
        return _parse_entsoe_datetime(
            isempty(time) ?
                date * "T00:00:00" : "$(date)T$(time)"
        )
    end

    # Fall back to the Available_Period timeInterval.
    ap = _first_named(ts, "Available_Period")
    ap === nothing && return nothing
    ti = _first_named(ap, "timeInterval")
    ti === nothing && return nothing
    boundary_field = which === :start ? "start" : "end"
    boundary = _first_text(ti, boundary_field)
    return isempty(boundary) ? nothing : _parse_entsoe_datetime(boundary)
end

# ENTSO-E's Unavailability documents express the production-unit metadata
# in TWO different forms across endpoints:
#   1. Flat dot-notation siblings on TimeSeries — what real outages
#      data returns (e.g. `<production_RegisteredResource.name>X</...>`).
#   2. Nested `<production_RegisteredResource><name>X</name>...</>` —
#      what some test fixtures use.
# Try the nested form first (cheaper), fall back to the flat form.
function _resource_field(ts::EzXML.Node, tail::AbstractString, nested_path::Vector{String})
    # Nested form: walk the path.
    nested = ts
    for hop in nested_path
        nested = _first_named(nested, hop)
        nested === nothing && break
    end
    nested === nothing || return strip(nodecontent(nested))
    # Flat form: `production_RegisteredResource.<tail>` on the TimeSeries.
    return _first_text(ts, "production_RegisteredResource." * tail)
end

"""
    parse_unavailability(xml) -> StructVector{@NamedTuple{
        start::DateTime, stop::DateTime,
        business_type::String, resource_name::String,
        resource_mrid::String, psr_type::String,
        nominal_mw::Float64}}

Parse an `<Unavailability_MarketDocument>` — the response shape used by
every Outages endpoint (generation, production, transmission, consumption).
One row per `<TimeSeries>`; fields:

  - `start` / `stop`    — DateTime UTC bounds of the outage window
  - `business_type`     — `A53` (planned) or `A54` (unplanned); see
                          [`BUSINESS_TYPE`](@ref)
  - `resource_name`     — `"production_RegisteredResource/name"`, or empty
                          when the document is an aggregated notice
  - `resource_mrid`     — mRID of the affected resource (or empty)
  - `psr_type`          — `production_RegisteredResource/pSRType/psrType`
                          (e.g. `"B16"` Solar, `"B19"` Wind Onshore)
  - `nominal_mw`        — rated capacity of the unit; `NaN` when absent

The per-15-minute Available_Period curve (i.e. the curtailed-to-MW
trajectory during the outage) is intentionally not unpacked here — use
`Raw()` if you need it. For most analyst use cases the one-row summary
is what you want; Tables.jl row/column access works as usual.
"""
function parse_unavailability(xml::AbstractString)
    starts = DateTime[]
    stops = DateTime[]
    business_types = String[]
    resource_names = String[]
    resource_mrids = String[]
    psr_types = String[]
    nominal_mws = Float64[]

    doc = parsexml(xml)
    for ts in _named(root(doc), "TimeSeries")
        s = _outage_datetime(ts, :start)
        e = _outage_datetime(ts, :stop)
        (s === nothing || e === nothing) && continue

        bt = _first_text(ts, "businessType")

        # Production-unit metadata — both nested and flat forms.
        name = _resource_field(ts, "name", ["production_RegisteredResource", "name"])
        mrid = _resource_field(ts, "mRID", ["production_RegisteredResource", "mRID"])
        psr = _resource_field(
            ts, "pSRType.psrType",
            ["production_RegisteredResource", "pSRType", "psrType"],
        )

        # Nominal rated capacity. Real outages XML uses a much longer
        # path:  `production_RegisteredResource.pSRType.powerSystemResources.nominalP`.
        # Test fixtures may use the legacy `nominal_P` sibling.
        nominal_text = _resource_field(
            ts, "pSRType.powerSystemResources.nominalP",
            [
                "production_RegisteredResource", "pSRType",
                "powerSystemResources", "nominalP",
            ],
        )
        if isempty(nominal_text)
            nominal_text = _first_text(ts, "nominal_P")
        end
        nominal_mw = isempty(nominal_text) ? NaN : parse(Float64, nominal_text)

        push!(starts, s)
        push!(stops, e)
        push!(business_types, bt)
        push!(resource_names, name)
        push!(resource_mrids, mrid)
        push!(psr_types, psr)
        push!(nominal_mws, nominal_mw)
    end
    return StructArray(
        (
            start = starts,
            stop = stops,
            business_type = business_types,
            resource_name = resource_names,
            resource_mrid = resource_mrids,
            psr_type = psr_types,
            nominal_mw = nominal_mws,
        )
    )
end

"""
    parse_unavailability_curve(xml) -> StructVector{@NamedTuple{
        time::DateTime, resource_mrid::String,
        resource_name::String, available_mw::Float64}}

Sister parser to [`parse_unavailability`](@ref) that walks each
`<TimeSeries>`'s `<Available_Period>/<Point>` series and returns one row
per timestamp — the per-15-minute (or per-resolution) MW curve the unit
was curtailed to *during* the outage. Use this when the one-row-per-event
summary `parse_unavailability` returns isn't enough — e.g. when you need
to know "the unit ran at 50% from 14:00–16:00, full from 16:00–20:00."

Each row carries the parent resource's `mRID` and `name` so you can
group multiple outages on the same unit. The Available_Period
`<Point>/<quantity>` value is the rated MW *available* during that
slice (not the rated capacity — for that pair this with the
`nominal_mw` column from `parse_unavailability`).

For documents without `<Available_Period>` children (rare), the
corresponding TimeSeries contributes no rows.
"""
function parse_unavailability_curve(xml::AbstractString; fill_gaps::Bool = get_config().fill_gaps)
    times = DateTime[]
    mrids = String[]
    names = String[]
    available_mws = Float64[]

    doc = parsexml(xml)
    for ts in _named(root(doc), "TimeSeries")
        mrid = _resource_field(ts, "mRID", ["production_RegisteredResource", "mRID"])
        name = _resource_field(ts, "name", ["production_RegisteredResource", "name"])
        expand = fill_gaps && _curve_type(ts) == "A03"

        for ap in _named(ts, "Available_Period")
            ti = _first_named(ap, "timeInterval")
            ti === nothing && continue
            start_node = _first_named(ti, "start")
            start_node === nothing && continue
            start = _parse_entsoe_datetime(nodecontent(start_node))

            res_node = _first_named(ap, "resolution")
            res_node === nothing && continue
            stride = _resolution_minutes(nodecontent(res_node))
            stride === nothing && continue

            positions = Int[]
            vals = Float64[]
            for pt in _named(ap, "Point")
                pos_node = _first_named(pt, "position")
                pos_node === nothing && continue
                qty = _first_named(pt, "quantity")
                qty === nothing && continue
                push!(positions, parse(Int, nodecontent(pos_node)))
                push!(vals, parse(Float64, nodecontent(qty)))
            end
            npoints = _period_npoints(ti, start, stride)
            ptimes, pvalues = _expand_period(positions, vals, start, stride, npoints, expand)
            m = length(ptimes)
            append!(times, ptimes)
            append!(mrids, fill(mrid, m))
            append!(names, fill(name, m))
            append!(available_mws, pvalues)
        end
    end
    return StructArray(
        (
            time = times,
            resource_mrid = mrids,
            resource_name = names,
            available_mw = available_mws,
        )
    )
end

# ---------------------------------------------------------------------------
# Configuration_MarketDocument — master-data registry for production +
# generation units. One `<TimeSeries>` per production unit, each with
# nested `<GeneratingUnit_PowerSystemResources>` children. We flatten to
# one row per generating unit, carrying the production-unit context as
# parent fields. Production units with no nested generating units emit a
# single row with the generating-unit fields blank.

"""
    parse_master_data(xml) -> StructVector{@NamedTuple{
        production_unit_mrid::String, production_unit_name::String,
        generating_unit_mrid::String, generating_unit_name::String,
        psr_type::String, nominal_mw::Float64,
        location::String, bidding_zone::String,
        implementation_date::String}}

Parse a `<Configuration_MarketDocument>` from the master-data endpoint
(`master_data_production_and_generation_units`). Returns one row per
*generating* unit, flattened from the per-production-unit grouping in
the document — fields:

  - `production_unit_mrid` / `production_unit_name` — the parent
    production unit (TimeSeries-level metadata).
  - `generating_unit_mrid` / `generating_unit_name` — the leaf
    generating unit (`<GeneratingUnit_PowerSystemResources>` child).
    Empty when the production unit has no nested generating units.
  - `psr_type`               — the generating unit's PSR type (B04
    Fossil Gas, B14 Nuclear, …); falls back to the production unit's
    `<MktPSRType/psrType>` when the generating-unit-level field is
    absent.
  - `nominal_mw`             — generating-unit rated MW
    (`<nominalP>`), or the production-unit nominal when missing.
  - `location`               — `registeredResource.location.name`.
  - `bidding_zone`           — EIC of the parent bidding zone.
  - `implementation_date`    — ISO date the resource entered the
    registry (string, not parsed — many entries use just a year).

Group-by-production-unit aggregations are one `groupby(rows, :production_unit_mrid)`
away with DataFrames.
"""
function parse_master_data(xml::AbstractString)
    p_unit_mrids = String[]
    p_unit_names = String[]
    g_unit_mrids = String[]
    g_unit_names = String[]
    psr_types = String[]
    nominal_mws = Float64[]
    locations = String[]
    bidding_zones = String[]
    impl_dates = String[]

    doc = parsexml(xml)
    for ts in _named(root(doc), "TimeSeries")
        p_mrid = _first_text(ts, "registeredResource.mRID")
        p_name = _first_text(ts, "registeredResource.name")
        location = _first_text(ts, "registeredResource.location.name")
        bz = _first_text(ts, "biddingZone_Domain.mRID")
        impl = _first_text(ts, "implementation_DateAndOrTime.date")

        # Production-unit-level PSR + nominal serve as fallbacks for
        # generating-unit rows that don't carry their own values.
        psrwrap = _first_named(ts, "MktPSRType")
        parent_psr = psrwrap === nothing ? "" :
            _first_text(psrwrap, "psrType")
        parent_nominal_text = psrwrap === nothing ? "" :
            _first_text(psrwrap, "nominalIP_PowerSystemResources.nominalP")
        parent_nominal = isempty(parent_nominal_text) ? NaN :
            parse(Float64, parent_nominal_text)

        gu_nodes = psrwrap === nothing ?
            EzXML.Node[] :
            _named(psrwrap, "GeneratingUnit_PowerSystemResources")

        if isempty(gu_nodes)
            # Emit one row with blank generating-unit fields — preserves
            # the production-unit in the output even if it has no
            # decomposition.
            push!(p_unit_mrids, p_mrid)
            push!(p_unit_names, p_name)
            push!(g_unit_mrids, "")
            push!(g_unit_names, "")
            push!(psr_types, parent_psr)
            push!(nominal_mws, parent_nominal)
            push!(locations, location)
            push!(bidding_zones, bz)
            push!(impl_dates, impl)
        else
            for gu in gu_nodes
                gu_mrid = _first_text(gu, "mRID")
                gu_name = _first_text(gu, "name")
                gu_psr = _first_text(gu, "generatingUnit_PSRType.psrType")
                gu_nominal_text = _first_text(gu, "nominalP")
                gu_nominal = isempty(gu_nominal_text) ? parent_nominal :
                    parse(Float64, gu_nominal_text)
                gu_location = _first_text(gu, "generatingUnit_Location.name")
                push!(p_unit_mrids, p_mrid)
                push!(p_unit_names, p_name)
                push!(g_unit_mrids, gu_mrid)
                push!(g_unit_names, gu_name)
                push!(psr_types, isempty(gu_psr) ? parent_psr : gu_psr)
                push!(nominal_mws, gu_nominal)
                push!(locations, isempty(gu_location) ? location : gu_location)
                push!(bidding_zones, bz)
                push!(impl_dates, impl)
            end
        end
    end
    return StructArray(
        (
            production_unit_mrid = p_unit_mrids,
            production_unit_name = p_unit_names,
            generating_unit_mrid = g_unit_mrids,
            generating_unit_name = g_unit_names,
            psr_type = psr_types,
            nominal_mw = nominal_mws,
            location = locations,
            bidding_zone = bidding_zones,
            implementation_date = impl_dates,
        )
    )
end

# ---------------------------------------------------------------------------
# Acknowledgement detection (also used by `check_acknowledgement`).

"""
    ENTSOEAcknowledgement(reason_code, text) <: APIError

Parsed `<Acknowledgement_MarketDocument>` payload — *also* a throwable
[`APIError`](@ref). ENTSO-E returns a 200 response containing this
document when there is no data for the requested query (also when the
query is ill-formed but well-typed). The official reason codes live in
the IEC 62325 reason-code list — the most commonly seen ones are:

  - `999` — "No matching data found" (your query was valid; the
    Transparency Platform just has nothing for that period / area).
  - `113` — "Not Authorized" (token rejected).
  - `400`–`499` — assorted client-side issues (bad parameter, …).

Use [`parse_acknowledgement`](@ref) for the non-throwing variant and
[`check_acknowledgement`](@ref) when you want it raised as an error.
"""
struct ENTSOEAcknowledgement <: APIError
    reason_code::String
    text::String
end

Base.show(io::IO, ack::ENTSOEAcknowledgement) =
    print(io, "ENTSOEAcknowledgement($(repr(ack.reason_code)): $(ack.text))")

Base.showerror(io::IO, ack::ENTSOEAcknowledgement) =
    print(
    io, "ENTSOEAcknowledgement: ENTSO-E returned reason code ",
    repr(ack.reason_code), " — ", ack.text
)

"""
    parse_acknowledgement(xml) -> ENTSOEAcknowledgement | nothing

If the document root is `<Acknowledgement_MarketDocument>`, parse out
the first `<Reason>` element's `<code>` and `<text>` and return them.
Otherwise return `nothing`.

This is the low-level form. Most callers want
[`check_acknowledgement`](@ref) instead, which throws — turning silent
"no data" responses into typed errors.
"""
function parse_acknowledgement(xml::AbstractString)
    doc = parsexml(xml)
    nodename(root(doc)) == "Acknowledgement_MarketDocument" || return nothing
    reason = _first_named(root(doc), "Reason")
    reason === nothing && return ENTSOEAcknowledgement("", "")
    code_node = _first_named(reason, "code")
    text_node = _first_named(reason, "text")
    return ENTSOEAcknowledgement(
        code_node === nothing ? "" : nodecontent(code_node),
        text_node === nothing ? "" : nodecontent(text_node),
    )
end

"""
    check_acknowledgement(xml) -> xml

Throw an [`ENTSOEAcknowledgement`](@ref) if `xml` is an
`<Acknowledgement_MarketDocument>`; otherwise return the input string
unchanged. Designed to be chained inline:

```julia
xml = check_acknowledgement(xml)
rows = parse_timeseries(xml)
```

Equivalent to:

```julia
ack = parse_acknowledgement(xml)
ack === nothing || throw(ack)
```
"""
function check_acknowledgement(xml::AbstractString)
    ack = parse_acknowledgement(xml)
    ack === nothing || throw(ack)
    return xml
end

# ---------------------------------------------------------------------------
# ZIP-response handling.

"""
    unzip_response(zip_bytes) -> Vector{Pair{String, Vector{UInt8}}}

ENTSO-E sometimes returns very large queries (especially outage and
master-data exports) as a `application/zip` body containing multiple
XML files. Pass the raw response bytes (`Vector{UInt8}`) and get back
a list of `name => contents` pairs.

`String(contents)` then yields the XML for each entry, ready to feed
into [`parse_timeseries`](@ref) or any other parser.

```julia
using HTTP

resp = HTTP.get(url; query = q, status_exception = false)
if startswith(HTTP.header(resp, "Content-Type", ""), "application/zip")
    members = unzip_response(resp.body)
    for (name, bytes) in members
        rows = parse_timeseries(String(bytes))
        # …
    end
end
```

Uses the stdlib `ZipFile` (via `Pkg`) — no extra deps. If the bytes
aren't a valid ZIP, errors propagate from `ZipFile`.
"""
function unzip_response(zip_bytes::Vector{UInt8})
    out = Pair{String, Vector{UInt8}}[]
    reader = ZipFile.Reader(IOBuffer(zip_bytes))
    try
        for entry in reader.files
            push!(out, entry.name => read(entry))
        end
    finally
        close(reader)
    end
    return out
end
