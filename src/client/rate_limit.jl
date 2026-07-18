"""
    TokenBucket(; rate=10.0, burst=10.0)

Token-bucket rate limiter. `rate` is tokens added per second; `burst` is the
maximum reservoir size (and the initial fill).
"""
mutable struct TokenBucket
    rate::Float64
    burst::Float64
    tokens::Float64
    last_refill::Float64
    lock::ReentrantLock
end

function TokenBucket(; rate::Real = 10.0, burst::Real = 10.0)
    r = Float64(rate); b = Float64(burst)
    r > 0 || throw(ArgumentError("rate must be positive, got $r"))
    b > 0 || throw(ArgumentError("burst must be positive, got $b"))
    # `last_refill = NaN` is a sentinel meaning "uninitialised" — the first
    # `acquire!` will seed it from its `time_fn`, so a mocked clock and the
    # bucket's notion of time stay consistent.
    return TokenBucket(r, b, b, NaN, ReentrantLock())
end

"""
    acquire!(bucket; tokens=1.0, timeout=Inf, sleep_fn=Base.sleep, time_fn=time)

Block until `tokens` tokens are available, or throw [`RateLimitError`](@ref)
if the wait would exceed `timeout` seconds. `time_fn` and `sleep_fn` are
injectable for testing.
"""
function acquire!(
        b::TokenBucket;
        tokens::Real = 1.0,
        timeout::Real = Inf,
        sleep_fn = Base.sleep,
        time_fn = time,
    )
    need = Float64(tokens)
    need <= b.burst || throw(
        ArgumentError(
            "tokens ($need) exceeds burst capacity ($(b.burst)) — " *
                "the request can never be satisfied",
        ),
    )
    deadline = time_fn() + Float64(timeout)
    while true
        # Hold the lock only for the refill/deduct bookkeeping; sleeping
        # happens outside so concurrent acquirers can still enter, observe
        # their own deadlines, and time out independently.
        wait_secs = lock(b.lock) do
            now = time_fn()
            if isnan(b.last_refill)
                b.last_refill = now
            end
            elapsed = now - b.last_refill
            if elapsed > 0
                b.tokens = min(b.burst, b.tokens + elapsed * b.rate)
                b.last_refill = now
            end
            if b.tokens >= need
                b.tokens -= need
                return 0.0
            end
            return (need - b.tokens) / b.rate
        end
        wait_secs == 0.0 && return nothing
        if time_fn() + wait_secs > deadline
            throw(RateLimitError(; status = 429, retry_after = wait_secs))
        end
        # Another task may take the refilled tokens while we sleep; the loop
        # recomputes the shortfall on wake-up.
        sleep_fn(wait_secs)
    end
    return
end

"""
    with_rate_limit(bucket, fn; kwargs...) -> Any

Acquire from `bucket` then run `fn()`. Extra kwargs are forwarded to
[`acquire!`](@ref).
"""
function with_rate_limit(bucket::TokenBucket, fn::Function; kwargs...)
    acquire!(bucket; kwargs...)
    return fn()
end
