"""
    APIError

Abstract supertype for all errors raised by this client.
"""
abstract type APIError <: Exception end

"""
    NetworkError(cause)

Wraps an underlying transport-layer exception (DNS failure, connection reset,
TLS handshake error, etc.).
"""
struct NetworkError <: APIError
    cause::Exception
end

"""
    ClientError(status, body, parsed=nothing)

A 4xx response — caller error. `parsed` may be `nothing` or the JSON-decoded
body, depending on `Content-Type`.
"""
struct ClientError <: APIError
    status::Int
    body::String
    parsed::Any
end
ClientError(status::Integer, body::AbstractString) = ClientError(Int(status), String(body), nothing)

"""
    ServerError(status, body, parsed=nothing)

A 5xx response — server-side failure.
"""
struct ServerError <: APIError
    status::Int
    body::String
    parsed::Any
end
ServerError(status::Integer, body::AbstractString) = ServerError(Int(status), String(body), nothing)

"""
    AuthError(status, message)

A 401 / 403 response — authentication or authorization failure.
"""
struct AuthError <: APIError
    status::Int
    message::String
end

"""
    RateLimitError(status=429; retry_after=nothing, body="")

A 429 response. `retry_after` is the parsed `Retry-After` header value in
seconds, or `nothing` when absent / unparsable.
"""
struct RateLimitError <: APIError
    status::Int
    retry_after::Union{Nothing, Float64}
    body::String
end
RateLimitError(; status::Integer = 429, retry_after = nothing, body::AbstractString = "") =
    RateLimitError(Int(status), retry_after === nothing ? nothing : Float64(retry_after), String(body))

"""
    TimeoutError(phase::Symbol)

Request exceeded the configured timeout. `phase` is `:connect`, `:read`, or
`:total`.
"""
struct TimeoutError <: APIError
    phase::Symbol
end

"""
    parse_retry_after(header) -> Union{Float64,Nothing}

Parse a `Retry-After` header value. Supports the `seconds` form only — HTTP
date form returns `nothing`.
"""
function parse_retry_after(header::AbstractString)
    s = strip(String(header))
    isempty(s) && return nothing
    n = tryparse(Float64, s)
    return n === nothing ? nothing : n
end
parse_retry_after(::Nothing) = nothing

# ENTSO-E's 429 responses are HTML pages whose interesting text sits in the
# first `<p>...</p>`. Pull it out (stripped, single-line) so end users and
# `showerror` can surface the platform's own message instead of the raw HTML.
const _RATE_LIMIT_HTML_BODY_RX = r"<p[^>]*>(.*?)</p>"is

"""
    rate_limit_message(err::RateLimitError) -> Union{String,Nothing}

Extract the human-readable message from ENTSO-E's HTML 429 body, or `nothing`
when the body is empty / non-HTML / shape-unrecognised. The platform serves a
short HTML page on rate-limit hits whose first `<p>` carries the explanation
(e.g. "Your request has exceeded the API throttling limit of 380 requests per
minute. The platform will respond again at …"). For non-HTML bodies the raw
`body` field is still available on the error.
"""
function rate_limit_message(err::RateLimitError)
    isempty(err.body) && return nothing
    m = match(_RATE_LIMIT_HTML_BODY_RX, err.body)
    m === nothing && return nothing
    msg = strip(replace(m.captures[1], r"\s+" => " "))
    return isempty(msg) ? nothing : String(msg)
end

function Base.showerror(io::IO, err::RateLimitError)
    print(io, "RateLimitError: HTTP ", err.status)
    if err.retry_after !== nothing
        print(io, " (Retry-After: ", err.retry_after, "s)")
    end
    msg = rate_limit_message(err)
    msg === nothing || print(io, " — ", msg)
    return nothing
end

# ENTSO-E commonly serves HTML pages on errors (a 503 during scheduled
# maintenance is ~100KB of CSS-laden HTML). Dumping the full body into a
# stack trace is unreadable; truncate to a one-line summary instead.
# Callers who need the full body can still reach for `err.body`.
const _BODY_PREVIEW_CHARS = 200

function _summarise_body(body::AbstractString)
    isempty(body) && return ""
    # Strip a leading <!DOCTYPE…> / <html…> so HTML bodies summarise as
    # something other than just the doctype string.
    cleaned = replace(String(body), r"<[^>]+>" => " ")
    cleaned = strip(replace(cleaned, r"\s+" => " "))
    isempty(cleaned) && return "(body $(length(body)) chars, all markup)"
    return length(cleaned) > _BODY_PREVIEW_CHARS ?
        first(cleaned, _BODY_PREVIEW_CHARS) * "…" : cleaned
end

function Base.showerror(io::IO, err::ServerError)
    print(io, "ServerError: HTTP ", err.status)
    body_preview = _summarise_body(err.body)
    isempty(body_preview) || print(io, " — ", body_preview)
    return nothing
end

function Base.showerror(io::IO, err::ClientError)
    print(io, "ClientError: HTTP ", err.status)
    body_preview = _summarise_body(err.body)
    isempty(body_preview) || print(io, " — ", body_preview)
    return nothing
end

function Base.showerror(io::IO, err::AuthError)
    print(io, "AuthError: HTTP ", err.status)
    isempty(err.message) || print(io, " — ", _summarise_body(err.message))
    return nothing
end

function Base.showerror(io::IO, err::TimeoutError)
    print(io, "TimeoutError: ", err.phase, " phase exceeded configured timeout")
    return nothing
end

function Base.showerror(io::IO, err::NetworkError)
    print(io, "NetworkError: ", typeof(err.cause).name.name)
    msg = sprint(showerror, err.cause)
    isempty(msg) || print(io, " — ", first(msg, _BODY_PREVIEW_CHARS))
    return nothing
end

"""
    check_response(status, body, headers=Dict()) -> Nothing

Throw the appropriate [`APIError`](@ref) subtype based on the HTTP status.
Returns `nothing` for 2xx responses.
"""
function check_response(
        status::Integer,
        body::AbstractString,
        headers::AbstractDict = Dict{String, String}(),
    )
    s = Int(status)
    if 200 <= s < 300
        return nothing
    elseif s == 401 || s == 403
        throw(AuthError(s, String(body)))
    elseif s == 429
        retry_after = parse_retry_after(get(headers, "Retry-After", nothing))
        throw(RateLimitError(; status = s, retry_after = retry_after, body = String(body)))
    elseif 400 <= s < 500
        throw(ClientError(s, String(body)))
    elseif 500 <= s < 600
        throw(ServerError(s, String(body)))
    else
        throw(ClientError(s, String(body)))
    end
end
