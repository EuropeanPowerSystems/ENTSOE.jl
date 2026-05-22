```@meta
CurrentModule = ENTSOE
```

# Tutorial: typed IEC 62325 document models

For the **flat** view of an ENTSO-E response — one row per timestamp —
the hand-written walkers in `src/conveniences/parsing.jl`
([`parse_timeseries`](@ref) and friends) are perfect. But each XML
document also carries a lot of *structural* metadata that the flat
parsers throw away: `mRID`, `createdDateTime`, sender/receiver
participants, `codingScheme` attributes on every domain identifier,
multiple `<TimeSeries>` blocks each with `businessType` / `auction_*` /
currency tags, optional `<Reason>` annotations on Points, …

The **typed-model layer** under `ENTSOE.XmlModels` exposes all of that.
It's **auto-generated from the official IEC 62325 XSD schemas**:
`gen/regenerate_xml_models.jl` walks every `.xsd` in `spec/xsd/` and
emits one Julia module per schema (currently **198 modules across 69
document families** — Acknowledgement v7-v9, Anomaly v5.0–v5.3,
Allocation v7.0–v7.2, Publication v7.0–v7.4, Capacity v7.0–v8.4,
Settlement, BidDocument, Outage, Configuration, GLSK, CNE, Crac, …).

This page walks one day-ahead-prices document through both parsers
side-by-side, and shows the structural information you can pull out
once you have the typed view.

## Setup

```@example xml
using ENTSOE
using CairoMakie
using Dates
using Statistics: mean

CairoMakie.activate!(type = "png")

include(joinpath(pkgdir(ENTSOE), "test", "_brokenrecord_helpers.jl"))
const BR = _load_brokenrecord()
client = ENTSOEClient("PLAYBACK")
nothing # hide
```

## Fetch the raw XML once

We'll use the same cassette as the rest of the tutorial set — `Raw()`
hands us the body without parsing.

```@example xml
xml = BR.playback("market_121d_day_ahead_prices_NL.yml") do
    day_ahead_prices(
        client, EIC.NL,
        DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        Raw(),
    )
end
length(xml), first(xml, 80)
```

## Two views of the same body

### Flat: `parse_timeseries`

The hand-written walker collapses the document to `(time, value)`
rows — the most common shape for analysts who just want to plot a
price curve.

```@example xml
flat = parse_timeseries(xml)
flat[1:3]
```

```@example xml
(n_rows = length(flat), first = flat[1], last = flat[end])
```

### Typed: `XmlModels.Publication_v7_4.parse_document`

The typed parser returns a fully-populated struct tree that mirrors
the IEC 62325 schema element-for-element.

```@example xml
doc = ENTSOE.XmlModels.Publication_v7_4.parse_document(xml)
typeof(doc)
```

```@example xml
(
    mRID = doc.mRID,
    revisionNumber = doc.revisionNumber,
    type = doc.type_,                              # "A44" = Price document
    createdDateTime = doc.createdDateTime,
    sender_role = doc.sender_MarketParticipant_marketRole_type,
    n_timeseries = length(doc.TimeSeries),
)
```

Domain identifiers in IEC 62325 carry an XSD `simpleContent` +
`codingScheme` attribute. The typed model exposes both:

```@example xml
ts = doc.TimeSeries[1]
(
    in_domain_value          = ts.in_Domain_mRID.value,
    in_domain_codingScheme   = ts.in_Domain_mRID.codingScheme,
    out_domain_value         = ts.out_Domain_mRID.value,
    currency_unit            = ts.currency_Unit_name,
    measurement_unit         = ts.price_Measurement_Unit_name,
    curve_type               = ts.curveType,
)
```

The flat parser drops every one of those fields.

## Visualising what the structured view unlocks

Even from one TimeSeries with one Period, the typed parser gives us
enough structure to draw a richer picture — the price curve **plus**
the period boundaries, the resolution annotation, and per-point
text-Reason callouts (when present).

```@example xml
period = ts.Period[1]
n = length(period.Point)

# X axis: position index → hour-of-day labels from the start instant.
start_dt = period.timeInterval.start            # already a String (raw YYYY-MM-DDTHH:MMZ)
tick_idx = 1:6:n
tick_labels = [Dates.format(flat.time[i], "HH:MM") for i in tick_idx]

fig = Figure(size = (980, 400))
ax = Axis(fig[1, 1];
    title  = "NL day-ahead prices — 2 Sep 2024 (resolution = $(period.resolution))",
    xlabel = "UTC time",
    ylabel = "EUR/MWh",
    xticks = (tick_idx, tick_labels),
)
prices_v = [p.price_amount === nothing ? NaN : p.price_amount for p in period.Point]
lines!(ax, 1:n, prices_v; color = :firebrick, linewidth = 1.6)
scatter!(ax, 1:n, prices_v; color = :firebrick, markersize = 6)

# Annotate the daily mean.
μ = mean(skipmissing(prices_v))
hlines!(ax, [μ]; color = :gray60, linestyle = :dash, linewidth = 1)
text!(ax, n - 0.5, μ;
    text = "  μ = $(round(μ; digits = 2))", align = (:right, :bottom),
    fontsize = 11, color = :gray50)

# Annotate the document-level metadata in the corner.
text!(ax, 1, maximum(filter(!isnan, prices_v));
    text = "mRID: $(doc.mRID[1:12])…\ncodingScheme: $(ts.in_Domain_mRID.codingScheme)\n" *
        "currency: $(ts.currency_Unit_name)",
    align = (:left, :top), fontsize = 10, color = :gray50)
fig
```

The plot itself is the same shape as `parse_timeseries` would
produce, but the **annotations** (currency, codingScheme, document
mRID) come straight off the typed struct — no extra DOM walking.

## When to use which

| Need | Use |
|---|---|
| 80% of analyst work: one column of values, plot, aggregate, regress | [`parse_timeseries`](@ref) / [`parse_timeseries_per_psr`](@ref) / [`parse_installed_capacity`](@ref) — fast, columnar, Tables.jl-friendly |
| Document mRID, createdDateTime, sender/receiver identification for audit | typed model |
| Multiple TimeSeries with distinct `businessType` / `auction_*` metadata | typed model — the flat parsers concatenate across TimeSeries blindly |
| `codingScheme` attribute, `quantity_Measurement_Unit`, `curve_type` | typed model |
| Per-point `<Reason>` annotations (rare, but they exist) | typed model — `period.Point[i].Reason` is a `Vector{Reason}` |
| Cross-version round-trip (parse one version, emit another) | typed model — each XSD version has its own module |

## Coverage

```@example xml
mods = [m for m in names(ENTSOE.XmlModels; all = true)
    if isdefined(ENTSOE.XmlModels, m) &&
       getproperty(ENTSOE.XmlModels, m) isa Module &&
       m != :XmlModels]
length(mods)
```

```@example xml
families = sort(unique([String(first(split(String(m), "_v"))) for m in mods]))
families
```

Every endpoint that returns an IEC 62325 document has at least one
matching module — typically the version ENTSO-E currently emits, plus
all historical versions in the schema package.

## Re-generating after a spec update

ENTSO-E publishes schema updates as a 7-zip archive on the
[EDI library page](https://www.entsoe.eu/publications/electronic-data-interchange-edi-library/).
To pull a new release:

```bash
# 1. Download + extract CIM_xsd_package_v<year>.7z into spec/xsd/
# 2. Regenerate (it overwrites src/xml_models/ wholesale)
julia --project gen/regenerate_xml_models.jl
```

The generator emits ~80 ms per XSD; the full 199-schema run takes
under 30 s. `src/xml_models/` is `linguist-generated=true` for
GitHub's diff renderer; never hand-edit it.

## Where to next

- The hand-written DOM walkers (`parse_timeseries` et al.) live in
  [`src/conveniences/parsing.jl`](https://github.com/langestefan/ENTSOE.jl/blob/main/src/conveniences/parsing.jl)
  and remain the default for the named-argument wrappers
  ([`day_ahead_prices`](@ref) etc.).
- The XSD codegen script is at
  [`gen/regenerate_xml_models.jl`](https://github.com/langestefan/ENTSOE.jl/blob/main/gen/regenerate_xml_models.jl)
  — about 450 lines, self-contained, EzXML-only.
- Wiring the typed parser into a named-wrapper signature
  (`day_ahead_prices(client, area, t1, t2, Typed())`?) is a planned
  follow-up; until then, drop down to `XmlModels.<Family>.parse_document`
  on the `Raw()` body when you need the structured view.
