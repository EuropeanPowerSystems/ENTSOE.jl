```@meta
CurrentModule = ENTSOE
```

# Tutorial: Belgian gas fleet from master data

The Master Data endpoint returns the **registered-resource registry**:
every production unit ENTSO-E knows about, with its constituent
generating units, technology, rated MW, and location. The wrapper
[`production_and_generation_units`](@ref) flattens this into one row
per generating unit with the parent production unit carried as
context, parsed by [`parse_master_data`](@ref).

This page asks: *what does Belgium's `B04 — Fossil gas` fleet look
like?*

## Setup

```@example master
using ENTSOE
using CairoMakie
using Dates
using Statistics: mean, median

CairoMakie.activate!(type = "png")

include(joinpath(pkgdir(ENTSOE), "test", "_brokenrecord_helpers.jl"))
const BR = _load_brokenrecord()
client = ENTSOEClient("PLAYBACK")
nothing # hide
```

## Pulling the registry

`production_and_generation_units` is the unusual wrapper that takes a
*single date* rather than a period — the master-data document is a
snapshot of the registry as of that day.

```@example master
units = BR.playback("tut_master_data_BE.yml") do
    production_and_generation_units(
        client, EIC.BE;
        implementation_date = "2017-01-01",
        business_type = "B11",     # production units
        psr_type = "B04",          # Fossil gas only
    )
end
length(units), propertynames(units)
```

Sample row — note how the production-unit context is carried beside
each generating-unit detail:

```@example master
units[1]
```

## Per-station breakdown

Production units in Belgium are sites containing one or more
generating units (a CCGT block might be one steam + one gas turbine).
Group by `production_unit_name` to see the station-level decomposition.

```@example master
stations = unique(units.production_unit_name)
station_totals = [
    (
        name = name,
        n_units = count(==(name), units.production_unit_name),
        total_mw = round(Int, sum(units.nominal_mw[units.production_unit_name .== name])),
    )
    for name in stations
]
sort!(station_totals; by = s -> -s.total_mw)
station_totals
```

## Horizontal bar chart, stacked by generating unit

Each station gets a horizontal stack — segments are the generating
units that compose it. Reading the chart you can immediately spot
which sites are single-unit and which are multi-unit CCGTs.

```@example master
n_stations = length(station_totals)
fig = Figure(size = (920, 90 + 32 * n_stations))
ax = Axis(fig[1, 1];
    title  = "Belgian fossil-gas fleet (B04) — production-unit decomposition",
    xlabel = "Rated MW",
    yticks = (1:n_stations, [s.name for s in station_totals]),
    yreversed = true,
)

palette = Makie.wong_colors()
for (i, station) in enumerate(station_totals)
    mask = units.production_unit_name .== station.name
    gens = units[mask]
    cum = 0.0
    for (j, g) in enumerate(gens)
        isnan(g.nominal_mw) && continue
        color = palette[mod1(j, length(palette))]
        barplot!(ax, [i], [g.nominal_mw];
            direction = :x, offset = cum,
            color = color, gap = 0.2, dodge_gap = 0.0,
            strokewidth = 0.5, strokecolor = :white)
        cum += g.nominal_mw
    end
end
fig
```

## Aggregate stats

```@example master
finite = filter(!isnan, units.nominal_mw)
(
    total_units             = length(units),
    distinct_production     = length(unique(units.production_unit_mrid)),
    total_rated_mw          = round(Int, sum(finite)),
    median_unit_mw          = round(Int, median(finite)),
    largest_unit_mw         = round(Int, maximum(finite)),
)
```

## Where to next

- Pass `psr_type = nothing` (or omit it) to pull *all* technologies in
  the bidding zone — useful for full-fleet capacity audits.
- Combine with [`installed_capacity_per_production_type`](@ref) (which
  publishes the annual aggregate) to cross-check the registry totals
  against the published year-ahead installed capacity.
- For outage notices keyed to these `resource_mrid`s, see
  [`unavailability_of_generation_units`](@ref) and the
  [outage timeline tutorial](tutorial_outages.md).
