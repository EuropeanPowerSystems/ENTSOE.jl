"""
    Auth

Abstract supertype for authentication strategies, applied to outgoing
requests via `apply!` and composed into a `pre_request_hook` for
`OpenAPI.Clients.Client` by `build_pre_request_hook`.

ENTSO-E authenticates via a `securityToken` **query parameter**, which
header-based strategies cannot express — [`ENTSOEClient`](@ref) therefore
always uses [`NoAuth`](@ref) plus its own query-injecting hook. The `Auth`
seam stays for API completeness and testing.
"""
abstract type Auth end

"""
    NoAuth()

Pass-through auth: leaves request headers untouched. What
[`ENTSOEClient`](@ref) uses — the real credential travels as the
`securityToken` query parameter injected by its pre-request hook.
"""
struct NoAuth <: Auth end

"""
    apply!(auth::Auth, headers::Dict{String,String}) -> Nothing

Inject credentials into the outgoing request headers.
"""
apply!(::NoAuth, ::Dict{String, String}) = nothing

"""
    build_pre_request_hook(auth) -> Function

Build the `pre_request_hook` accepted by `OpenAPI.Clients.Client`. The hook
implements both required signatures: a `Ctx`-only pass-through and a
`(resource, body, headers)` form that calls `apply!` on `auth`.
"""
function build_pre_request_hook(auth::Auth)
    hook(ctx) = ctx
    function hook(resource::AbstractString, body, headers::Dict{String, String})
        apply!(auth, headers)
        return resource, body, headers
    end
    return hook
end
