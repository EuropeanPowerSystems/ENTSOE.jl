# ENTSOE.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://europeanpowersystems.github.io/ENTSOE.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://europeanpowersystems.github.io/ENTSOE.jl/dev/)
[![Build Status](https://github.com/EuropeanPowerSystems/ENTSOE.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/EuropeanPowerSystems/ENTSOE.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Documentation](https://github.com/EuropeanPowerSystems/ENTSOE.jl/actions/workflows/Documentation.yml/badge.svg?branch=main)](https://github.com/EuropeanPowerSystems/ENTSOE.jl/actions/workflows/Documentation.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/EuropeanPowerSystems/ENTSOE.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/EuropeanPowerSystems/ENTSOE.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![tested with JET.jl](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)

A Julia client for the
[ENTSO-E Transparency Platform RESTful API](https://transparencyplatform.zendesk.com/hc/en-us/sections/12783116987028-Web-API)
— electricity market, generation, load, transmission, outage,
balancing, and master data for Europe.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/EuropeanPowerSystems/ENTSOE.jl")
```

You'll also need an API token. Register at
[transparency.entsoe.eu](https://transparency.entsoe.eu/) (free) and
e-mail the listed support address requesting access. Set
`ENV["ENTSOE_API_TOKEN"]` (or pass the token explicitly to `ENTSOEClient`).

## Quick start

```julia
using ENTSOE
using Dates
using DataFrames             # optional — see "Tables.jl interface"

client = ENTSOEClient(ENV["ENTSOE_API_TOKEN"])

prices = day_ahead_prices(client, EIC.NL,
    DateTime("2024-09-01T22:00"),   # 2024-09-02 00:00 CET
    DateTime("2024-09-02T22:00"),   # 2024-09-03 00:00 CET
)

prices[1:3]
# 3-element StructVector(@NamedTuple{time::DateTime, value::Float64}):
#  (time = DateTime("2024-09-01T22:00"), value = 91.24)
#  (time = DateTime("2024-09-01T23:00"), value = 94.77)
#  (time = DateTime("2024-09-02T00:00"), value = 92.39)

prices.value          # Vector{Float64}, all 24 hourly prices
prices.time           # Vector{DateTime}
DataFrame(prices)     # works directly — every wrapper is Tables.jl-compatible
```

### Tables.jl interface

Every wrapper returns a
[`StructVector`](https://github.com/JuliaArrays/StructArrays.jl) — a
columnar layout that satisfies the
[Tables.jl](https://github.com/JuliaData/Tables.jl) interface. You get
both shapes for free:

- **Row access** — `prices[1]` is a `NamedTuple`-like row.
- **Column access** — `prices.value`, `prices.time` return plain
  `Vector{Float64}` / `Vector{DateTime}` (no allocation).
- **Round-trips** straight into `DataFrames.DataFrame`,
  `CSV.write`, `Arrow.Table`, `Plots.plot`, etc.

Every wrapper accepts `DateTime`, `Date`, `ZonedDateTime`, or a raw
`Int64` `yyyymmddHHMM` for the period bounds — pick whichever you have
on hand. Periods are interpreted as **UTC**; the example above asks for
24 h starting at 2024-09-01 22:00 UTC, which is the local CET trading
day 2024-09-02.

## Named wrappers

The high-level functions below pre-fill the magic ENTSO-E codes
(`A44`, `A65`, `A68`, …) and parse the XML response into typed Julia
values. They live in `src/conveniences/queries.jl` and wrap the
auto-generated functions in `src/api/`.

### Choosing parsed vs. raw output

Every wrapper takes an **optional trailing positional argument** of
type `ResponseFormat` that switches the return shape:

| Trailing argument | Return type | Use it for |
| --- | --- | --- |
| *(omitted)* | `StructVector{<row>}` | The default. Tables.jl-compatible, drop into `DataFrame` / plot / stats. |
| `Parsed()` | `StructVector{<row>}` | Same as default — useful when you want the choice explicit at the call site. |
| `Raw()` | `String` | Bypass the parser. Hand the XML to your own walker, archive the body, debug a parse mismatch. |

```julia
t1, t2 = DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00")

# Default — parsed StructVector
prices = day_ahead_prices(client, EIC.NL, t1, t2)
prices.value[1:3]    # → [91.24, 94.77, 92.39]

# Explicit Parsed() — identical to the default; reads better in
# pipelines where multiple formats coexist.
prices2 = day_ahead_prices(client, EIC.NL, t1, t2, Parsed())

# Raw() — return the application/xml String unchanged
xml = day_ahead_prices(client, EIC.NL, t1, t2, Raw())
typeof(xml)          # → String
```

`Parsed` and `Raw` are subtypes of the abstract `ResponseFormat`, so
each variant has a **concrete runtime return type**:

```julia
typeof(prices)
# → StructVector{@NamedTuple{time::DateTime, value::Float64},
#                @NamedTuple{time::Vector{DateTime}, value::Vector{Float64}}, Int64}

typeof(xml)
# → String
```

Downstream code can branch on `ResponseFormat` at the call site — no
runtime `isa Union{…}` dispatch needed.

### Day-ahead prices

```julia
prices = day_ahead_prices(client, EIC.DE_LU,
    DateTime("2025-01-15"), DateTime("2025-01-16"))

prices[1]            # → (time = DateTime("2025-01-14T23:00"), value = 118.0)
prices[2].time       # → DateTime("2025-01-14T23:15")
```

Resolution and exact row count vary by bidding zone and date — NL
day-ahead currently publishes hourly (24 rows for a 24 h window),
DE_LU and most CWE zones publish quarter-hourly (96 rows), and on
days where ENTSO-E republishes multiple TSO documents you may see
several stitched curves in one response. Don't hard-code a length —
trust `prices.time` and the row stride.

### Realised total system load

```julia
load = actual_total_load(client, EIC.NL,
    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"))

length(load)   # → 96   (15-min resolution)
load[1]        # → (time = DateTime("2024-09-01T22:00"), value = 12156.45)  # MW
```

Day/week/month/year-ahead forecasts are also wrapped:
`day_ahead_load_forecast`, `week_ahead_load_forecast`,
`month_ahead_load_forecast`, `year_ahead_load_forecast` — same
signature.

### Actual generation per production type

```julia
gen = actual_generation_per_production_type(client, EIC.FR,
    DateTime("2025-03-10"), DateTime("2025-03-11"))

# rows tagged with PSR type, sorted by (psr_type, time):
gen[1]    # → (time = DateTime("2025-03-10T00:00"),
          #    psr_type = "B01",   # Biomass — see PSR_TYPE
          #    value = 311.2)      # MW

# Filter to one technology server-side:
solar = actual_generation_per_production_type(client, EIC.FR,
    DateTime("2025-03-10"), DateTime("2025-03-11");
    psr_type = "B16")    # B16 = Solar
```

### Installed capacity per production type

```julia
caps = installed_capacity_per_production_type(client, EIC.NL,
    DateTime("2024-12-31T23:00"), DateTime("2025-12-31T23:00"))

# Vector{@NamedTuple{psr_type::String, capacity_mw::Float64}}, one
# row per PSR type present in the registry for that year.
caps[1]   # → (psr_type = "B01", capacity_mw = 418.0)   # Biomass

# `ENTSOE.describe` resolves a code against any of the four code
# tables. Qualified because the name collides with `DataFrames.describe`.
ENTSOE.describe(PSR_TYPE, caps[1].psr_type)   # → "Biomass"
```

### Cross-border physical flows

```julia
# Flow from Germany into the Netherlands (positive = imports)
flow = cross_border_physical_flows(client,
    EIC.NL, EIC.DE_LU,                 # in_area, out_area
    DateTime("2024-09-01"), DateTime("2024-09-02"))

length(flow)   # → 96   (15-min resolution)
flow[1]        # → (time = DateTime("2024-09-01T00:00"), value = 333.0)  # MW
```

## Codes and identifiers

ENTSO-E codes everything as 2- or 3-character strings (`A44`,
`B19`, etc.). The package ships four code-list tables and helpers:

```julia
DOCUMENT_TYPE.A44               # "Price document"
PROCESS_TYPE.A16                # "Realised"
BUSINESS_TYPE.A33               # "Outage"
PSR_TYPE.B19                    # "Wind Onshore"

# Reverse lookup by fragment — must match exactly one entry:
code_for(PSR_TYPE, "wind onshore")        # "B19"
code_for(DOCUMENT_TYPE, "Price document") # "A44"
# A too-generic fragment throws — "price" matches A44/A84/A85/A89.
```

Bidding zones are
[EIC codes](https://www.entsoe.eu/data/energy-identification-codes-eic/)
— 16 ASCII chars. The most-used 33 are exposed as named-tuple fields:

```julia
EIC.NL          # "10YNL----------L"
EIC.DE_LU       # "10Y1001A1001A82H"
EIC.NO2         # "10YNO-2--------T"  (southern Norway)
```

For zones not in `EIC`, pass the raw 16-character string directly. The
extended `EIC_REGISTRY` table covers a curated set of ~120 ENTSO-E
EICs and maps each to a `Vector{@NamedTuple{name::String,
types::Vector{Symbol}}}` (one entry per registration — `types`
elements are `:BZN`, `:CTA`, `:MBA`, …). Pass `validate = true` to
any wrapper to assert the zone exists and is the right type for the
endpoint.

## Long periods (auto-split)

Most ENTSO-E endpoints reject single requests longer than one year. To
fetch 5 years of NL prices in one call, wrap with `query_split`:

```julia
prices = query_split(
    day_ahead_prices,
    client, EIC.NL,
    DateTime("2020-01-01"), DateTime("2025-01-01");
    window = Year(1),
)

length(prices)    # → 43677   (5 years × 8760 h, minus a handful of
                  #            DST/no-data slots)
```

Internally `query_split` calls `day_ahead_prices` once per yearly chunk
and concatenates the results. Some endpoints cap at one day rather than
one year (e.g. balancing energy bids); pass `window = Day(1)` there.

## "No data" responses

ENTSO-E returns HTTP 200 with an `<Acknowledgement_MarketDocument>` when
there's no matching data for a query. The wrappers detect this and
re-raise as a typed exception:

```julia
try
    day_ahead_prices(client, EIC.GR,
        DateTime("1999-01-01"), DateTime("1999-01-02"))
catch err
    err isa ENTSOEAcknowledgement || rethrow()
    @info "no data" err.reason_code err.text
end
# ┌ Info: no data
# │   err.reason_code = "999"
# └   err.text = "No matching data found for ..."
```

`query_split` catches `ENTSOEAcknowledgement` per chunk and continues
with the next window — so a multi-year request that's only partially
populated still returns whatever data exists.

## Reliability stack

`ENTSOEClient` is built on the package's underlying `Client`, so the
generic `with_defaults` middleware composes around any call:

```julia
result = with_defaults(;
    retry      = RetryPolicy(; max_attempts = 5, base_delay = 0.5),
    rate_limit = TokenBucket(; rate = 10.0, burst = 10.0),
    timeout    = 5.0,
) do
    day_ahead_prices(client, EIC.NL,
        DateTime("2024-09-01"), DateTime("2024-09-02"))
end
```

The default policy retries on `408`/`429`/`5xx` and honours
`Retry-After` headers. Any non-2xx response is mapped to a typed
exception by `check_response`:

| Status | Type |
| --- | --- |
| 401 / 403 | `AuthError` |
| 408 / 429 | `RateLimitError` (parses `Retry-After`) |
| Other 4xx | `ClientError` |
| 5xx | `ServerError` |
| Network / DNS / TLS | `NetworkError` |
| Timeout | `TimeoutError(:connect \| :read \| :total)` |

## Documentation

The full guide — including the
[2025 EU price heat-map tutorial](https://europeanpowersystems.github.io/ENTSOE.jl/dev/tutorial_eu_map)
and a per-tag interactive REST playground — lives at
[europeanpowersystems.github.io/ENTSOE.jl](https://europeanpowersystems.github.io/ENTSOE.jl).
Build it locally with:

```bash
julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
julia --project=docs docs/make.jl
cd docs && npm install && npm run docs:dev
```

## Re-running codegen (maintainers only)

The OpenAPI spec is committed at `spec/openapi.json`, derived once from
ENTSO-E's official Postman collection. To rebuild `src/api/`:

```bash
julia --project gen/regenerate.jl
```

Requires Java 11+ and Node 18+. End users of the published package
never touch this step — `src/api/` is committed plain Julia. The
scheduled `.github/workflows/regen-check.yml` runs codegen weekly and
opens a PR if the upstream Postman collection has drifted.

## Architecture

Two layers, both Julia, both committed:

- **`src/api/`** — generated by
  [OpenAPI Generator](https://openapi-generator.tech/) (`julia-client`).
  77 functions, one per ENTSO-E operation. Returns
  `(xml::String, response)`. Never re-run at runtime.
- **`src/conveniences/`** — hand-written: `ENTSOEClient`, named-argument
  wrappers (`day_ahead_prices` etc.), parsers, code tables, EIC registry,
  `query_split`. Untouched by codegen.

See [`CLAUDE.md`](./CLAUDE.md) for the full layout including the
Postman→OpenAPI conversion script.
