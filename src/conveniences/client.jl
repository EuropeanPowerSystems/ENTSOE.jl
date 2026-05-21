using OpenAPI: OpenAPI

"""
    ENTSOE_BASE_URL

The public Transparency Platform API base URL —
`"https://web-api.tp.entsoe.eu/api"`. Default value for
[`ENTSOEClient`](@ref)'s `base_url` keyword; override only when
testing against the IOP environment or a recorded mock server.
"""
const ENTSOE_BASE_URL = "https://web-api.tp.entsoe.eu/api"

# BrokenRecord-driven tests construct clients with this literal sentinel so
# the URL still parses but no live credential is needed (playback never
# touches the wire). It is always accepted by `validate_token=true`.
const _PLAYBACK_TOKEN_SENTINEL = "PLAYBACK"

# Canonical 8-4-4-4-12 UUID form. ENTSO-E's security tokens are UUIDs; the
# platform accepts both the hyphenated form returned by the user portal and
# the bare 32-hex-character form that some clients post. We accept either.
const _UUID_HYPHENATED_RX = r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"i
const _UUID_BARE_RX = r"^[0-9a-f]{32}$"i

"""
    is_uuid_token(token) -> Bool

`true` when `token` is in canonical UUID form (8-4-4-4-12 hyphenated, or
32 bare hex characters). ENTSO-E's API keys are UUIDs; callers can use this
to fail fast on obviously-malformed input without paying a 401 round-trip.
The opt-in `validate_token = true` kwarg on [`ENTSOEClient`](@ref) wraps it.
"""
is_uuid_token(token::AbstractString) =
    occursin(_UUID_HYPHENATED_RX, token) || occursin(_UUID_BARE_RX, token)

"""
    ENTSOEClient(token; base_url=ENTSOE_BASE_URL, validate_token=false, kwargs...) -> Client

Build a `Client` wired with ENTSO-E's `securityToken` query-parameter auth.
Every operation in the generated API declares the `SecurityToken` security
requirement, and this client's `pre_request_hook` injects the token into the
query string for those operations.

Empty or whitespace-only tokens are always rejected with `ArgumentError`.
Pass `validate_token = true` to additionally require UUID format (see
[`is_uuid_token`](@ref)) — useful when the token comes from user input or
config files where typos are likely. The string `"PLAYBACK"` is always
accepted so BrokenRecord-driven tests keep working.

The generated `<Group>Api` constructors take an `OpenAPI.Clients.Client`, so
unwrap with `.inner` before constructing them — or use [`entsoe_apis`](@ref)
which does that for you and returns one API per ENTSO-E group:

```julia
using ENTSOE
client = ENTSOEClient(ENV["ENTSOE_API_TOKEN"]; validate_token = true)
apis = entsoe_apis(client)

start = entsoe_period(Dates.DateTime("2023-08-23T22:00"))
stop  = entsoe_period(Dates.DateTime("2023-08-24T22:00"))
xml, _ = market121_d_energy_prices(apis.market, "A44", EIC.NL, EIC.NL, start, stop)
```

Extra keyword arguments are forwarded verbatim to `OpenAPI.Clients.Client`
(useful for `timeout`, `httplib`, etc.).
"""
function ENTSOEClient(
        token::AbstractString;
        base_url::AbstractString = ENTSOE_BASE_URL,
        validate_token::Bool = false,
        kwargs...,
    )
    tok = String(token)
    isempty(strip(tok)) && throw(
        ArgumentError(
            "ENTSOEClient: token is empty or whitespace-only. Pass your " *
                "ENTSO-E API key (the UUID e-mailed to you by transparency@entsoe.eu) " *
                "or the literal string \"PLAYBACK\" for BrokenRecord-driven tests."
        )
    )
    if validate_token && tok != _PLAYBACK_TOKEN_SENTINEL && !is_uuid_token(tok)
        throw(
            ArgumentError(
                "ENTSOEClient: token does not look like an ENTSO-E API key " *
                    "(expected a UUID such as `1a2b3c4d-…`). Pass " *
                    "`validate_token = false` to skip this check, or fix the token."
            )
        )
    end
    inner = OpenAPI.Clients.Client(
        String(base_url);
        pre_request_hook = _entsoe_pre_request_hook(tok),
        kwargs...,
    )
    return Client(inner, NoAuth(), String(base_url))
end

# Build a `pre_request_hook` with both signatures expected by `OpenAPI.Clients`.
#
# Stage 1 — `(ctx::Ctx)` runs before the URL is assembled. We inject
# `securityToken` into `ctx.query` for any op that declares the
# SecurityToken scheme. (Headers we'd inject here too, but ENTSO-E uses
# query-string auth.)
#
# Stage 2 — `(resource, body, headers)` runs after the URL is fully
# assembled (path + query). We use it to collapse the synthetic per-
# endpoint path back to the single real ENTSO-E endpoint. The OpenAPI
# spec gives each operation a synthetic path like
# `/market/12-1-d-energy-prices` so codegen produces one Julia function
# per logical query (see `info.description` in `spec/openapi.json` and
# the README of `scripts/postman_to_openapi.jl`). The actual HTTP
# endpoint is `/api?<query>` for every operation — so we strip
# everything between `/api` and the query string before the request
# hits the wire.
function _entsoe_pre_request_hook(token::String)
    function hook(ctx::OpenAPI.Clients.Ctx)
        "SecurityToken" in ctx.auth && (ctx.query["securityToken"] = token)
        return ctx
    end
    function hook(
            resource_path::AbstractString, body, headers::Dict{String, String},
        )
        rewritten = replace(
            String(resource_path),
            r"^(https?://[^/]+/api)/[^?]+" => s"\1",
        )
        return rewritten, body, headers
    end
    return hook
end

"""
    entsoe_apis(c::Client) -> NamedTuple

One API instance per ENTSO-E group, ready to pass to the generated query
functions:

```julia
apis = entsoe_apis(client)
apis.market         # MarketApi
apis.load           # LoadApi
apis.generation     # GenerationApi
# ... balancing, master_data, omi, outages, transmission
```
"""
function entsoe_apis(c::Client)
    return (
        balancing = BalancingApi(c.inner),
        generation = GenerationApi(c.inner),
        load = LoadApi(c.inner),
        market = MarketApi(c.inner),
        master_data = MasterDataApi(c.inner),
        omi = OMIApi(c.inner),
        outages = OutagesApi(c.inner),
        transmission = TransmissionApi(c.inner),
    )
end
