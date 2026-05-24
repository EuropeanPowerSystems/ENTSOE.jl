# Beyond day-ahead: intraday, margins, and offshore outages

The headline wrappers (`day_ahead_prices`, `actual_total_load`,
`cross_border_physical_flows`) cover most everyday workflows, but
ENTSO-E publishes a long tail of more specialised documents. This page
introduces four wrappers that opened up alongside the entsoe-py
parity sweep:

| Wrapper                              | What it returns                                                              |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| [`intraday_prices`](@ref)            | Continuous-intraday / SIDC IDA auction clearing prices (12.1.D, A07)         |
| [`intraday_wind_solar_forecast`](@ref) | Wind/solar forecast republished as intraday auctions clear (14.1.D, A40)   |
| [`year_ahead_forecast_margin`](@ref) | Generation-adequacy margin one year out (8.1, A70/A33)                       |
| [`unavailability_of_offshore_grid`](@ref) | Outage notices for offshore-grid infrastructure (10.1.C, A79)           |

Setup is the same as anywhere else:

```julia
using ENTSOE
using Dates
using DataFrames    # only needed for the last example

client = ENTSOEClient(ENV["ENTSOE_API_TOKEN"])
```

## Intraday wind & solar forecast

When the day-ahead forecast looks wrong overnight (a storm front shifts,
clouds break unexpectedly), TSOs republish their wind/solar forecast on
the intraday horizon. `intraday_wind_solar_forecast` exposes the latest
published forecast — same wire endpoint as the day-ahead variant, but
with the intraday process type:

```julia
forecast = intraday_wind_solar_forecast(client, EIC.NL,
    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"))

forecast[1]
# → (time = DateTime("2024-09-01T22:00"), psr_type = "B16", value = 0.0)

# Pull out one technology:
solar = forecast[forecast.psr_type .== "B16"]
```

Like `wind_solar_forecast`, pass a `psr_type="B16"` kwarg to filter
server-side — useful when the response is large enough that you only
want one curve.

## Intraday prices

Intraday cleared prices ride on the same 12.1.D endpoint as day-ahead,
distinguished by the contract-marketagreement type (`A07` vs `A01`):

```julia
prices = intraday_prices(client, EIC.NL, t1, t2; sequence = 1)
```

`sequence` selects a specific IDA auction (1 / 2 / 3 in SIDC); omit it
to receive every published sequence in one call. Data is published
patchily — many zones don't expose A07 results at all, and on days
without IDA auctions ENTSO-E returns an
[`ENTSOEAcknowledgement`](@ref) with `reason_code = "999"`. Wrap
accordingly:

```julia
try
    intraday_prices(client, EIC.ES,
        DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00");
        sequence = 1)
catch err
    err isa ENTSOEAcknowledgement || rethrow()
    @info "no intraday data for that zone/date" err.reason_code
end
```

## Year-ahead forecast margin

`year_ahead_forecast_margin` answers the adequacy question one year out:
*how much surplus capacity is forecast to exist over forecast peak
load?* One row per published period — typically a single annual
snapshot in MW.

```julia
margin = year_ahead_forecast_margin(client, EIC.BE,
    DateTime("2023-12-31T23:00"), DateTime("2024-12-31T23:00"))

margin[1]      # → (time = DateTime("2023-12-31T23:00"), value = 970.0)
```

Distinct from [`year_ahead_load_forecast`](@ref) — that's the forecast
of demand alone (document A65); this is the *difference* between
forecasted available capacity and forecasted peak load (document A70).

## Offshore-grid outages

The offshore-grid outage notices live on a separate endpoint from
onshore transmission outages (10.1.C vs 10.1.A/B) and a different
document type (`A79` vs `A78`). The wrapper takes a single
`bidding_zone` rather than the `in_Domain`/`out_Domain` pair the onshore
endpoint requires:

```julia
outages = unavailability_of_offshore_grid(client, EIC.DE_LU,
    DateTime("2024-01-01"), DateTime("2024-04-01"))

length(outages)        # number of outage events in the window
outages[1].start       # DateTime UTC
outages[1].nominal_mw  # rated MW of the affected resource

# Filter to unplanned outages:
unplanned = outages[outages.business_type .== "A54"]
```

The same `parse_unavailability` row shape used by the onshore wrappers
(`unavailability_of_generation_units`, `..._production_units`,
`..._transmission_infrastructure`), so existing analyses port across
unchanged.

## Porting from entsoe-py

`EIC` is now callable with a plain string, so country codes can be
passed positionally exactly the way entsoe-py expects them:

```julia
day_ahead_prices(client, EIC("NL"), t1, t2)   # ≡ EIC.NL
day_ahead_prices(client, EIC("DE_LU"), t1, t2)
```

This matters when porting code that builds country codes dynamically
(e.g. iterating over a list of strings) — no need to hand-write a
`Dict("NL" => EIC.NL, "BE" => EIC.BE, …)` lookup.
