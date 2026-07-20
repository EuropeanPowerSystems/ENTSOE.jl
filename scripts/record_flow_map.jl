#!/usr/bin/env julia
# record_flow_map.jl
# ==================
#
# One-shot recorder for the cross-border flow-map tutorial
# (`docs/src/tutorial_flow_map.md`). Walks every unique border in
# `ENTSOE.NEIGHBOURS`, pulls one week of `cross_border_physical_flows`
# in *both* directions, integrates the hourly/quarter-hourly MW series
# into energy (GWh) over the period, and writes a compact JSON fixture
# the docs build loads offline.
#
# We deliberately record a single representative week, not a whole year:
# a year of quarter-hour flows is ~35k points per direction × ~80
# directed queries — minutes of download and parse. A week is ~50×
# smaller and captures the same structural picture for a tutorial. Widen
# PERIOD_START/END (and re-run) if you want a longer window.
#
# Direction convention (matches `cross_border_physical_flows`):
#   `cross_border_physical_flows(client, in, out)` is the flow that
#   arrives *in* `in` coming *from* `out`. So the net flow a → b is
#     energy(in=b, out=a) − energy(in=a, out=b).
#   A positive net means a was, on balance, exporting to b over the week.
#
# Usage
# -----
#     julia --project=docs scripts/record_flow_map.jl
#     FLOW_MAP_MAX_BORDERS=6 julia --project scripts/record_flow_map.jl  # quick subset
#
# Token is read from ENV["ENTSOE_API_TOKEN"] first, then <root>/token.txt.

using Pkg

const ROOT = normpath(joinpath(@__DIR__, ".."))
Pkg.activate(ROOT; io = devnull)

using ENTSOE
using ENTSOE: NEIGHBOURS, EIC_REGISTRY
using Dates
using Statistics: median
using JSON

# One representative winter week (Mon 2025-01-13 00:00 → Mon 2025-01-20
# 00:00 UTC). Short on purpose — see the header note.
const PERIOD_START = DateTime("2025-01-13T00:00")
const PERIOD_END = DateTime("2025-01-20T00:00")
const PERIOD_LABEL = "2025-01-13 – 2025-01-20"

# EIC → bidding-zone geojson filename stem (see
# docs/src/assets/bidding_zones/). Only zones with a polygon appear here;
# borders touching a zone that is absent (GB, IE(SEM)) are still recorded
# but carry `zone = nothing` so the tutorial can skip drawing them.
const EIC_TO_ZONE = Dict(
    "10YBE----------2" => "BE",
    "10YNL----------L" => "NL",
    "10YFR-RTE------C" => "FR",
    "10YCH-SWISSGRIDZ" => "CH",
    "10YAT-APG------L" => "AT",
    "10YCZ-CEPS-----N" => "CZ",
    "10YNO-2--------T" => "NO_2",
    "10YHU-MAVIR----U" => "HU",
    "10Y1001A1001A73I" => "IT_NORD",
    "10YES-REE------0" => "ES",
    "10YSI-ELES-----O" => "SI",
    "10YPL-AREA-----S" => "PL",
    "10YDK-1--------W" => "DK_1",
    "10YDK-2--------M" => "DK_2",
    "10Y1001A1001A82H" => "DE_LU",
    "10YLT-1001A0008Q" => "LT",
    "10Y1001A1001A47J" => "SE_4",
    "10Y1001A1001A46L" => "SE_3",
    "10Y1001A1001A48H" => "NO_5",
    "10YNO-1--------2" => "NO_1",
    "10YHR-HEP------M" => "HR",
    "10YRO-TEL------P" => "RO",
    "10YCS-SERBIATSOV" => "RS",
    "10YSK-SEPS-----K" => "SK",
    "10YPT-REN------W" => "PT",
)

function _resolve_token()
    tok = get(ENV, "ENTSOE_API_TOKEN", "")
    isempty(tok) || return strip(tok)
    isfile(joinpath(ROOT, "token.txt")) &&
        return strip(read(joinpath(ROOT, "token.txt"), String))
    return ""
end

# Short human label for an EIC, from the registry's first alias.
function _label(eic)
    haskey(EIC_REGISTRY, eic) && return EIC_REGISTRY[eic][1].name
    return eic
end

# Unique undirected borders {a, b} across the whole NEIGHBOURS graph.
function _unique_pairs()
    seen = Set{Tuple{String, String}}()
    pairs = Tuple{String, String}[]
    for (a, ns) in NEIGHBOURS, b in ns
        key = a < b ? (a, b) : (b, a)
        key in seen && continue
        push!(seen, key)
        push!(pairs, key)
    end
    return sort(pairs)
end

# Median resolution of a time series, in hours (fallback 1.0).
function _resolution_hours(times)
    length(times) < 2 && return 1.0
    t = sort(times)
    gaps = [Dates.value(t[i + 1] - t[i]) / 3.6e6 for i in 1:(length(t) - 1)]  # ms → h
    isempty(gaps) && return 1.0
    r = median(gaps)
    return r > 0 ? r : 1.0
end

# Integrated energy (GWh) of a (time, value[MW]) series over the period.
function _energy_gwh(rows)
    res_h = _resolution_hours(rows.time)
    return sum(r -> r.value * res_h, rows; init = 0.0) / 1000   # MW×h → MWh → GWh
end

# One directed border query, returning (GWh, n_points) — (0, 0) on no-data.
function _directed_gwh(client, in_area, out_area)
    rows = try
        cross_border_physical_flows(client, in_area, out_area, PERIOD_START, PERIOD_END)
    catch e
        e isa ENTSOEAcknowledgement && return (0.0, 0)
        rethrow()
    end
    return (_energy_gwh(rows), length(rows))
end

function main()
    token = _resolve_token()
    isempty(token) && error("no ENTSOE_API_TOKEN in env or token.txt — cannot record.")
    client = ENTSOEClient(String(token))

    pairs = _unique_pairs()
    # FLOW_MAP_MAX_BORDERS=n truncates the run — handy for a quick smoke
    # recording before committing to the full ~40-border, ~80-call sweep.
    maxb = tryparse(Int, get(ENV, "FLOW_MAP_MAX_BORDERS", ""))
    maxb === nothing || (pairs = pairs[1:min(maxb, length(pairs))])
    @info "recording $(length(pairs)) unique borders for $PERIOD_LABEL"

    borders = Dict{String, Any}[]
    for (a, b) in pairs
        za, zb = get(EIC_TO_ZONE, a, nothing), get(EIC_TO_ZONE, b, nothing)
        @info "border $(_label(a)) ↔ $(_label(b))"
        flush(stderr)

        # flow b → a (arrives in a, out of b) and a → b (arrives in b, out of a)
        gwh_b_to_a, n1 = _directed_gwh(client, a, b)
        gwh_a_to_b, n2 = _directed_gwh(client, b, a)

        net_a_to_b = gwh_a_to_b - gwh_b_to_a           # + ⇒ a exports to b
        push!(
            borders, Dict(
                "a_eic" => a, "b_eic" => b,
                "a_zone" => za, "b_zone" => zb,
                "a_label" => _label(a), "b_label" => _label(b),
                "net_a_to_b_gwh" => round(net_a_to_b; digits = 3),
                "gross_a_to_b_gwh" => round(gwh_a_to_b; digits = 3),
                "gross_b_to_a_gwh" => round(gwh_b_to_a; digits = 3),
                "n_points" => n1 + n2,
                "drawable" => za !== nothing && zb !== nothing,
            ),
        )
    end

    out = Dict{String, Any}(
        "period_start" => Dates.format(PERIOD_START, "yyyy-mm-ddTHH:MM"),
        "period_end" => Dates.format(PERIOD_END, "yyyy-mm-ddTHH:MM"),
        "period_label" => PERIOD_LABEL,
        "comment" => "Cross-border physical flows (Transmission 12.1.G, A11), " *
            "integrated to energy in GWh over the period. Net a→b positive ⇒ " *
            "a exports to b. Recorded $(Dates.format(Dates.now(), "yyyy-mm-dd")) by " *
            "scripts/record_flow_map.jl.",
        "borders" => borders,
    )

    dst = joinpath(ROOT, "docs", "src", "assets", "cross_border_flows_2025.json")
    mkpath(dirname(dst))
    open(dst, "w") do io
        JSON.print(io, out, 2)
    end
    ndraw = count(b -> b["drawable"], borders)
    @info "wrote fixture" path = dst borders = length(borders) drawable = ndraw bytes = filesize(dst)
    return nothing
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end
