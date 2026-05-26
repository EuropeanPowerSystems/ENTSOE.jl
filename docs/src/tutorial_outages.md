```@meta
CurrentModule = ENTSOE
```

# Tutorial: outage timeline — Belgian generation units

`Outages 15.1.A/B` publishes a notice for every generation-unit
outage in a bidding zone. The wrapper
[`unavailability_of_generation_units`](@ref) returns one row per
event: window, resource, technology, rated MW. This page pulls a
real BE month and turns it into a Gantt-style timeline coloured by
rated capacity.

The HTTP body is `application/zip` (one XML doc per notice); the
wrapper unzips it transparently and `vcat`s the parsed
[`parse_unavailability`](@ref) results.

## Setup

```@example outages
using ENTSOE
using CairoMakie
using Dates

CairoMakie.activate!(type = "png")

include(joinpath(pkgdir(ENTSOE), "test", "_brokenrecord_helpers.jl"))
const BR = _load_brokenrecord()
# The outage cassette is BSON because the response is `application/zip` —
# YAML can't byte-stably round-trip binary bodies.
BR.configure!(; extension = "bson")
client = ENTSOEClient("PLAYBACK")
nothing # hide
```

## Fetch one month's planned outages

```@example outages
notices = BR.playback("tut_outages_BE_2024.bson") do
    unavailability_of_generation_units(
        client, EIC.BE,
        DateTime("2024-01-01T00:00"), DateTime("2024-02-01T00:00");
        business_type = BusinessType.PLANNED_OUTAGE,
    )
end
length(notices), propertynames(notices)
```

Sample row:

```@example outages
notices[1]
```

## Gantt chart, coloured by rated MW

Each row is one outage event — horizontal bar spans `start`→`stop`,
positioned by resource name on Y, coloured by rated MW on a viridis
scale. We convert times to *days since 1 Jan 2024* for the X axis
(Makie's DateTime axis support is version-dependent — index-based
plotting is robust).

```@example outages
ordered_resources = unique(notices.resource_name)
y_of = Dict(name => i for (i, name) in enumerate(ordered_resources))
ref = DateTime("2024-01-01T00:00")

# X-axis: days since the reference. Negative = outage started before
# the query window opens.
to_days(t) = (t - ref).value / 86_400_000   # ms → days

finite_mw = filter(!isnan, notices.nominal_mw)
mw_range = isempty(finite_mw) ? (0.0, 1.0) : (Float64(minimum(finite_mw)),
                                              Float64(maximum(finite_mw)))

fig = Figure(size = (1000, 120 + 26 * length(ordered_resources)))
ax = Axis(fig[1, 1];
    title  = "Planned generation outages — Belgium, Jan 2024",
    xlabel = "Days since 1 Jan 2024",
    yticks = (1:length(ordered_resources), ordered_resources),
    yticklabelsize = 9,
    yreversed = true,
)

cgrad_v = Makie.cgrad(:viridis)
for row in notices
    y = y_of[row.resource_name]
    span = mw_range[2] - mw_range[1]
    c = isnan(row.nominal_mw) ? RGBAf(0.55, 0.55, 0.55, 0.85) :
        cgrad_v[clamp((row.nominal_mw - mw_range[1]) / max(span, 1.0), 0, 1)]
    lines!(ax, [to_days(row.start), to_days(row.stop)], [y, y];
        color = c, linewidth = 8)
end

Colorbar(fig[1, 2], colormap = :viridis, limits = mw_range,
    label = "Rated MW", height = Relative(0.7))
fig
```

The plot reads directly:

- Long horizontal bars are **multi-month or multi-year outages**
  spilling into the January window — typically refits or fuel-change
  campaigns. Several Belgian generation units sit in maintenance for
  months at a time.
- The colour ramp shows which units carry the most rated capacity per
  outage event; the brightest bars are the largest plants offline.

## Per-station summary

```@example outages
by_resource = Dict{String, NamedTuple{(:n, :total_outage_days, :rated_mw),
                                      Tuple{Int, Float64, Float64}}}()
for row in notices
    name = row.resource_name
    days = (row.stop - row.start).value / 86_400_000
    cur = get(by_resource, name,
        (n = 0, total_outage_days = 0.0,
         rated_mw = isnan(row.nominal_mw) ? 0.0 : row.nominal_mw))
    by_resource[name] = (
        n = cur.n + 1,
        total_outage_days = cur.total_outage_days + days,
        rated_mw = cur.rated_mw,
    )
end

sorted = sort(collect(by_resource); by = p -> -p.second.total_outage_days)
first(sorted, min(5, length(sorted)))
```

## Where to next

- [`unavailability_of_production_units`](@ref) (Outages 15.1.C/D)
  for whole-station outages.
- [`unavailability_of_transmission_infrastructure`](@ref) (10.1.A/B)
  for cross-border interconnector outages.
- [`parse_unavailability_curve`](@ref) walks each `<Available_Period>`
  to return the **per-15-min curtailment trajectory** — useful when
  the outage is partial (the unit ran at, say, 50% during the window).
