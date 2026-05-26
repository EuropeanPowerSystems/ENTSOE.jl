```@meta
CurrentModule = ENTSOE
```

# Beyond day-ahead: intraday, margins, and offshore outages

The headline wrappers (`day_ahead_prices`, `actual_total_load`,
`cross_border_physical_flows`) cover most everyday workflows, but
ENTSO-E publishes a long tail of more specialised documents. This page
introduces four wrappers that cover those specialised documents:

| Wrapper                              | What it returns                                                              |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| [`intraday_prices`](@ref)            | Continuous-intraday / SIDC IDA auction clearing prices (12.1.D, A07)         |
| [`intraday_wind_solar_forecast`](@ref) | Wind/solar forecast republished as intraday auctions clear (14.1.D, A40)   |
| [`year_ahead_forecast_margin`](@ref) | Generation-adequacy margin one year out (8.1, A70/A33)                       |
| [`unavailability_of_offshore_grid`](@ref) | Outage notices for offshore-grid infrastructure (10.1.C, A79)           |

## Setup

```@example intraday
using ENTSOE
using Dates

include(joinpath(pkgdir(ENTSOE), "test", "_brokenrecord_helpers.jl"))
const BR = _load_brokenrecord()
client = ENTSOEClient("PLAYBACK")
nothing # hide
```

## Intraday wind & solar forecast

When the day-ahead forecast looks wrong overnight (a storm front shifts,
clouds break unexpectedly), TSOs republish their wind/solar forecast on
the intraday horizon. `intraday_wind_solar_forecast` exposes the latest
published forecast — same wire endpoint as the day-ahead variant, but
with the intraday process type:

```@example intraday
forecast = BR.playback("generation_141d_intraday_wind_solar_forecast_NL.yml") do
    intraday_wind_solar_forecast(
        client, EIC.NL,
        DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
    )
end
forecast[1]
```

Pull out one technology — solar is `B16`:

```@example intraday
solar = forecast[forecast.psr_type .== "B16"]
length(solar), solar[1]
```

Like `wind_solar_forecast`, pass a `psr_type="B16"` kwarg to filter
server-side — useful when the response is large enough that you only
want one curve.

## Intraday prices

Intraday cleared prices ride on the same 12.1.D endpoint as day-ahead,
distinguished by the contract-marketagreement type (`A07` vs `A01`).
The wrapper takes an optional `sequence=1`/`2`/`3` kwarg to pick a
specific IDA auction; omit it to receive every published sequence in
one call.

ENTSO-E publishes A07 patchily — many zones don't expose intraday
results on a given day, and the body comes back as an
[`ENTSOEAcknowledgement`](@ref) with `reason_code = "999"`. DE_LU on
2024-09-01 is one such case, and the wrapper surfaces the empty
document as a typed exception rather than crashing the parser:

```@example intraday
reason_code = try
    BR.playback("market_121d_intraday_prices_DE_LU.yml") do
        intraday_prices(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        )
    end
    nothing
catch err
    err isa ENTSOEAcknowledgement || rethrow()
    err.reason_code
end
```

`reason_code == "999"` is ENTSO-E's "no matching data" code — wrap
intraday calls in `try`/`catch` whenever you sweep across zones or
dates that may not all have IDA results.

## Year-ahead forecast margin

`year_ahead_forecast_margin` answers the adequacy question one year out:
*how much surplus capacity is forecast to exist over forecast peak
load?* One row per published period — typically a single annual
snapshot in MW.

```@example intraday
margin = BR.playback("load_81_year_ahead_forecast_margin_BE.yml") do
    year_ahead_forecast_margin(
        client, EIC.BE,
        DateTime("2023-12-31T23:00"), DateTime("2024-12-31T23:00"),
    )
end
margin[1]
```

Distinct from [`year_ahead_load_forecast`](@ref) — that's the forecast
of demand alone (document A65); this is the *difference* between
forecasted available capacity and forecasted peak load (document A70).

## Offshore-grid outages

The offshore-grid outage notices live on a separate endpoint from
onshore transmission outages (10.1.C vs 10.1.A/B) and a different
document type (`A79` vs `A78`). The wrapper takes a single
`bidding_zone` rather than the `in_Domain`/`out_Domain` pair the onshore
endpoint requires.

The response is an `application/zip` bundle (one XML notice per event),
so the cassette is stored as BSON — YAML can't byte-stably round-trip
binary bodies. We flip BrokenRecord's extension before loading:

```@example intraday
BR.configure!(; extension = "bson")
outages = BR.playback("outages_101c_unavailability_offshore_grid_DE_LU.bson") do
    unavailability_of_offshore_grid(
        client, EIC.DE_LU,
        DateTime("2024-01-01"), DateTime("2024-04-01"),
    )
end
length(outages), propertynames(outages)
```

Sample row:

```@example intraday
outages[1]
```

Same `parse_unavailability` shape used by the onshore wrappers
(`unavailability_of_generation_units`, `..._production_units`,
`..._transmission_infrastructure`), so existing analyses port across
unchanged. Filter to unplanned outages (`A54`) with column-wise
indexing:

```@example intraday
unplanned = outages[outages.business_type .== "A54"]
length(unplanned)
```

## EIC codes from plain strings

`EIC` is also callable with a plain country-code string, so zones can
be constructed dynamically without field access:

```@example intraday
EIC("NL") == EIC.NL, EIC("DE_LU") == EIC.DE_LU
```

This matters when you're iterating over a list of country-code strings
(e.g. from a config file or another data source) — no need to
hand-write a `Dict("NL" => EIC.NL, "BE" => EIC.BE, …)` lookup.
