# ENTSOE.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://europeanpowersystems.github.io/ENTSOE.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://europeanpowersystems.github.io/ENTSOE.jl/dev/)
[![Build Status](https://github.com/EuropeanPowerSystems/ENTSOE.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/EuropeanPowerSystems/ENTSOE.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Documentation](https://github.com/EuropeanPowerSystems/ENTSOE.jl/actions/workflows/Documentation.yml/badge.svg?branch=main)](https://github.com/EuropeanPowerSystems/ENTSOE.jl/actions/workflows/Documentation.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/EuropeanPowerSystems/ENTSOE.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/EuropeanPowerSystems/ENTSOE.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![tested with JET.jl](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)

A Julia client for the
[ENTSO-E Transparency Platform RESTful API](https://transparencyplatform.zendesk.com/hc/en-us/sections/12783116987028-Web-API).

Electricity market, generation, load, transmission, outage,
balancing, and master data for Europe.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/EuropeanPowerSystems/ENTSOE.jl")
```

> [!IMPORTANT]
> You'll also need an API token. Register at [transparency.entsoe.eu](https://transparency.entsoe.eu/) (free) and e-mail the listed support address requesting access. Set `ENV["ENTSOE_API_TOKEN"]` (or pass the token explicitly to `ENTSOEClient`).

## Quick start

```julia
julia> using ENTSOE
julia> using Dates
julia> using DataFrames             # optional — see "Tables.jl interface"

julia> client = ENTSOEClient(ENV["ENTSOE_API_TOKEN"])

# if ENV["ENTSOE_API_TOKEN"] is set this is equivalent to just:
julia> client = ENTSOEClient()

julia> prices = day_ahead_prices(client, EIC.NL,
           DateTime("2024-09-01T22:00"),   # 2024-09-02 00:00 CET
           DateTime("2024-09-02T22:00"),   # 2024-09-03 00:00 CET
       )
# 24-element StructArray(::Vector{DateTime}, ::Vector{Float64}) with eltype @NamedTuple{time::DateTime, value::Float64}:

julia> prices[1:3]
# 3-element StructArray(::Vector{DateTime}, ::Vector{Float64}) with eltype @NamedTuple{time::DateTime, value::Float64}:
#  (time = DateTime("2024-09-01T22:00:00"), value = 91.24)
#  (time = DateTime("2024-09-01T23:00:00"), value = 94.77)
#  (time = DateTime("2024-09-02T00:00:00"), value = 92.39)

julia> prices.value
# 24-element Vector{Float64}:

julia> prices.time
# 24-element Vector{DateTime}:

julia> DataFrame(prices)     # works directly — every wrapper is Tables.jl-compatible
# 24×2 DataFrame
#  Row │ time                 value
#      │ DateTime             Float64
# ─────┼──────────────────────────────
#    1 │ 2024-09-01T22:00:00    91.24
#   ⋮  │          ⋮              ⋮
#   24 │ 2024-09-02T21:00:00   104.0
```

### Tables.jl interface

Every wrapper returns a
[`StructArray`](https://github.com/JuliaArrays/StructArrays.jl) that
satisfies the [Tables.jl](https://github.com/JuliaData/Tables.jl)
interface, so you get both shapes for free:

- **Row access** — `prices[1]` is a `NamedTuple`-like row.
- **Column access** — `prices.value`, `prices.time` return plain
  `Vector`s (no allocation).
- **Round-trips** into `DataFrame`, `CSV.write`, `Arrow.Table`,
  `Plots.plot`, etc.

Period bounds accept `DateTime`, `Date`, `ZonedDateTime`, or a raw
`Int64` `yyyymmddHHMM` and are interpreted as **UTC**.

## Named wrappers

The high-level functions in `src/conveniences/queries.jl` pre-fill the
magic ENTSO-E codes (`A44`, `A65`, …) and parse the XML — e.g.
`day_ahead_prices`, `actual_total_load`, `day_ahead_load_forecast`,
`actual_generation_per_production_type`,
`installed_capacity_per_production_type`,
`cross_border_physical_flows`. Each takes an optional trailing
`ResponseFormat` argument:

```julia
day_ahead_prices(client, EIC.NL, t1, t2)                          # Parsed() — default StructVector
day_ahead_prices(client, EIC.NL, t1, t2, Raw())                   # ::String, unparsed XML
day_ahead_prices(client, EIC.NL, t1, t2, LocalTime("Europe/Amsterdam"))  # time as ZonedDateTime
```

## Codes and identifiers

```julia
PSR_TYPE.B19                       # "Wind Onshore"
code_for(PSR_TYPE, "wind onshore") # "B19"  — reverse lookup by fragment
EIC.NL                             # "10YNL----------L"
```

Four code tables (`DOCUMENT_TYPE`, `PROCESS_TYPE`, `BUSINESS_TYPE`,
`PSR_TYPE`) and 33 named bidding zones in `EIC` are exported; pass any
raw 16-char EIC string for zones not listed. `EIC_REGISTRY` covers the
extended set. Pass `validate = true` to any wrapper to assert the zone.

## Long periods, "no data", reliability

```julia
# Most endpoints reject requests longer than a year — split automatically:
query_split(day_ahead_prices, client, EIC.NL,
    DateTime("2020-01-01"), DateTime("2025-01-01"); window = Year(1))
```

"No data" comes back as HTTP 200 with an `<Acknowledgement_MarketDocument>`;
wrappers re-raise it as `ENTSOEAcknowledgement` (which `query_split`
catches per chunk). HTTP errors map to typed exceptions
(`AuthError`, `RateLimitError`, `ClientError`, `ServerError`,
`NetworkError`, `TimeoutError`). Wrap any call in retry / rate-limit /
timeout with `with_defaults(...) do ... end`.

## Documentation

Full guide, tutorials, and REST playground at
[europeanpowersystems.github.io/ENTSOE.jl](https://europeanpowersystems.github.io/ENTSOE.jl).
