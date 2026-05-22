module ENTSOE

using HTTP: HTTP
using JSON: JSON
using OpenAPI: OpenAPI

# Generated low-level surface — DO NOT EDIT, regenerate via gen/regenerate.jl
include("api/ENTSOEAPI.jl")
using .ENTSOEAPI

# Re-export every public name from the generated module so users don't have to
# qualify with `ENTSOEAPI.`.
for n in names(ENTSOEAPI; all = false)
    n === Symbol("ENTSOEAPI") && continue
    @eval export $n
end

# Hand-written ergonomic surface
include("client/auth.jl")
include("client/errors.jl")
include("client/logging.jl")
include("client/retry.jl")
include("client/rate_limit.jl")
include("client/timeout.jl")
include("client/middleware.jl")
include("client/Client.jl")
include("client/pagination.jl")
include("client/show.jl")

export Client, Auth, NoAuth, BearerToken, APIKey, BasicAuth, resolve_credentials
export APIError, NetworkError, ClientError, ServerError, AuthError,
    RateLimitError, TimeoutError, check_response, rate_limit_message
export RetryPolicy, with_retry
export TokenBucket, acquire!, with_rate_limit
export with_timeout
export with_logging, redact_headers
export DefaultMiddleware, default_middleware, with_defaults
export paginate_cursor, paginate_offset, paginate_pagenum
export ResponseFormat, Parsed, Raw

# ENTSO-E specific helpers (hand-written, not part of the codegen output).
# Safe across `gen/regenerate.jl` runs — that script only rewrites `src/api/`.
include("conveniences/conveniences.jl")

# Typed XML document models — auto-generated from IEC 62325 XSDs in
# `spec/xsd/`. Each module under `XmlModels/` exposes `parse_document`
# returning a fully populated struct tree. Regenerate via
# `gen/regenerate_xml_models.jl`. The hand-written DOM walkers in
# `conveniences/parsing.jl` remain available for users who only want the
# (time, value) flattening.
module XmlModels
    const _MODEL_DIR = joinpath(@__DIR__, "xml_models")
    if isdir(_MODEL_DIR)
        for file in sort!(readdir(_MODEL_DIR))
            endswith(file, ".jl") || continue
            include(joinpath(_MODEL_DIR, file))
        end
    end
end
export XmlModels

end # module
