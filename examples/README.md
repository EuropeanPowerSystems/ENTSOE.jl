# Examples

Runnable walkthrough of every public surface in `ENTSOE.jl`.

## Setup

```bash
# From the repo root — develop the local package into the examples env
julia --project=examples -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
```

## Run

Token resolution: `ENV["ENTSOE_API_TOKEN"]` first, then the gitignored
`token.txt` at the repo root. If neither is set, the script tells you and
exits — it never hits the network without credentials.

```bash
julia --project=examples examples/walkthrough.jl
```

Each section prints a header plus the first few rows of whatever it
fetched, so you can scroll the output and see exactly what landed.

## What it covers

- Client construction with `validate_token = true`, the `is_uuid_token`
  predicate, `entsoe_period` for date conversion.
- The `EIC` curated zone tuple, `EIC_REGISTRY` lookup, `validate_eic`,
  `eics_of_type`.
- All four code-list tables (`DOCUMENT_TYPE`, `PROCESS_TYPE`,
  `BUSINESS_TYPE`, `PSR_TYPE`) plus `describe` and `code_for`.
- Every named wrapper currently exported (Market 12.1.D prices; Load
  6.1.A–E; Generation 14.1.A/C/D + 16.1.B/C; Transmission 11.1.A,
  12.1.F, 12.1.F net positions, 12.1.G; OMI with pagination).
- `Parsed()` vs `Raw()` dispatch.
- `query_split` over a multi-year window.
- `ENTSOEAcknowledgement` handling on a deliberately empty query.
- `RateLimitError` body parsing via `rate_limit_message` (offline demo).
- The `with_defaults` middleware composition (retry / rate-limit /
  timeout).
- Dropping down to the raw generated layer (`apis.market.market121_d_…`)
  for endpoints without a named wrapper.
