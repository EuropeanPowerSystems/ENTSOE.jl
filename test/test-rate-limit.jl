using ENTSOE
using Test

function _mock_clock(start::Real = 100.0)
    now = Ref(Float64(start))
    sleeps = Float64[]
    sleep_fn = function (s)
        push!(sleeps, Float64(s))
        return now[] += Float64(s)
    end
    time_fn = () -> now[]
    return (; sleep_fn, time_fn, sleeps)
end

@testset "TokenBucket immediate acquire" begin
    clk = _mock_clock()
    b = ENTSOE.TokenBucket(; rate = 10.0, burst = 5.0)
    ENTSOE.acquire!(b; sleep_fn = clk.sleep_fn, time_fn = clk.time_fn)
    @test isempty(clk.sleeps)
    @test b.tokens ≈ 4.0
end

@testset "TokenBucket waits when empty" begin
    clk = _mock_clock()
    b = ENTSOE.TokenBucket(; rate = 2.0, burst = 1.0)
    ENTSOE.acquire!(b; sleep_fn = clk.sleep_fn, time_fn = clk.time_fn)
    ENTSOE.acquire!(b; sleep_fn = clk.sleep_fn, time_fn = clk.time_fn)
    @test length(clk.sleeps) == 1
    @test clk.sleeps[1] ≈ 0.5
end

@testset "TokenBucket throws when timeout would expire" begin
    clk = _mock_clock()
    b = ENTSOE.TokenBucket(; rate = 1.0, burst = 1.0)
    ENTSOE.acquire!(b; sleep_fn = clk.sleep_fn, time_fn = clk.time_fn)
    @test_throws ENTSOE.RateLimitError ENTSOE.acquire!(
        b; timeout = 0.1, sleep_fn = clk.sleep_fn, time_fn = clk.time_fn,
    )
end

@testset "TokenBucket rejects non-positive rate and burst" begin
    @test_throws ArgumentError ENTSOE.TokenBucket(; rate = 0.0)
    @test_throws ArgumentError ENTSOE.TokenBucket(; rate = -1.0)
    @test_throws ArgumentError ENTSOE.TokenBucket(; burst = 0.0)
end

@testset "acquire! rejects tokens beyond burst capacity" begin
    b = ENTSOE.TokenBucket(; rate = 1.0, burst = 5.0)
    # The reservoir can never hold 10 tokens — waiting would spin forever.
    @test_throws ArgumentError ENTSOE.acquire!(b; tokens = 10.0)
end

@testset "acquire! sleeps outside the bucket lock" begin
    # Task A drains the bucket then blocks inside its (injected) sleep while
    # waiting for a refill. Task B must still be able to enter acquire! and
    # observe its timeout — with the sleep inside the lock, B would block in
    # lock() until A's sleep finished and this test would time out.
    b = ENTSOE.TokenBucket(; rate = 1.0, burst = 1.0)
    ENTSOE.acquire!(b)   # drain the only token
    release = Channel{Nothing}(1)
    a = @async ENTSOE.acquire!(b; sleep_fn = _ -> take!(release))
    b_task = @async try
        ENTSOE.acquire!(b; timeout = 0.01)
        :acquired
    catch e
        e isa ENTSOE.RateLimitError ? :timed_out : rethrow()
    end
    @test timedwait(() -> istaskdone(b_task), 5.0) === :ok
    @test istaskdone(b_task) && fetch(b_task) === :timed_out
    # Refill the bucket, then let A's sleep return: its next loop iteration
    # finds a full reservoir and acquires without sleeping again.
    lock(() -> b.tokens = 1.0, b.lock)
    put!(release, nothing)
    @test timedwait(() -> istaskdone(a), 5.0) === :ok
end

@testset "with_rate_limit runs fn after acquire" begin
    clk = _mock_clock()
    b = ENTSOE.TokenBucket(; rate = 100.0, burst = 5.0)
    n = Ref(0)
    ENTSOE.with_rate_limit(
        b, () -> n[] += 1;
        sleep_fn = clk.sleep_fn, time_fn = clk.time_fn
    )
    @test n[] == 1
end
