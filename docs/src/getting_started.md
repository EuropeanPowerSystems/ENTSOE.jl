# Getting Started

## Installation

```julia
using Pkg
Pkg.add("ENTSOE")
```

## Constructing a Client

```julia
using ENTSOE

client = Client("https://api.example.com"; auth = NoAuth())
```

ENTSO-E authenticates with a `securityToken` **query parameter**, so
header-based auth strategies don't apply here — construct clients with
[`ENTSOEClient`](@ref) (which uses [`NoAuth`](@ref) plus a query-injecting
pre-request hook) and never set the token via headers.

## Reliability primitives

The hand-written overlay ships retry, rate-limit, and timeout helpers. Wrap a
call to compose them:

```julia
result = with_retry(; policy = RetryPolicy(; max_attempts = 3)) do
    with_timeout(5.0) do
        # ... call a generated endpoint here ...
    end
end
```

## Pagination

The only paginated ENTSO-E endpoint is OMI — its wrapper
[`omi_other_market_information`](@ref) walks the server's fixed
200-document pages via the `offset` parameter automatically.
