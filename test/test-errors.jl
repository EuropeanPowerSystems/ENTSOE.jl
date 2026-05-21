using ENTSOE
using Test

@testset "Error type hierarchy" begin
    @test ENTSOE.NetworkError(ErrorException("dns")) isa ENTSOE.APIError
    @test ENTSOE.ClientError(404, "not found") isa ENTSOE.APIError
    @test ENTSOE.ServerError(500, "boom") isa ENTSOE.APIError
    @test ENTSOE.AuthError(401, "nope") isa ENTSOE.APIError
    @test ENTSOE.RateLimitError(; retry_after = 5.0) isa ENTSOE.APIError
    @test ENTSOE.TimeoutError(:read) isa ENTSOE.APIError
end

@testset "parse_retry_after" begin
    @test ENTSOE.parse_retry_after("5") == 5.0
    @test ENTSOE.parse_retry_after(" 12 ") == 12.0
    @test ENTSOE.parse_retry_after("Wed, 21 Oct 2015 07:28:00 GMT") === nothing
    @test ENTSOE.parse_retry_after("") === nothing
    @test ENTSOE.parse_retry_after(nothing) === nothing
end

@testset "check_response 2xx returns nothing" begin
    for s in (200, 201, 204, 299)
        @test ENTSOE.check_response(s, "") === nothing
    end
end

@testset "check_response classifies by status" begin
    @test_throws ENTSOE.AuthError ENTSOE.check_response(401, "")
    @test_throws ENTSOE.AuthError ENTSOE.check_response(403, "")
    @test_throws ENTSOE.ClientError ENTSOE.check_response(404, "missing")
    @test_throws ENTSOE.ServerError ENTSOE.check_response(503, "")
    @test_throws ENTSOE.ClientError ENTSOE.check_response(600, "weird")
end

@testset "check_response 429 surfaces RateLimitError" begin
    headers = Dict("Retry-After" => "7")
    err = try
        ENTSOE.check_response(429, "", headers)
        nothing
    catch e
        e
    end
    @test err isa ENTSOE.RateLimitError
    @test err.retry_after == 7.0
end

@testset "rate_limit_message extracts ENTSO-E ban text" begin
    # Shape modelled on the actual platform response — an HTML page with the
    # message text in the first `<p>`. Newlines + indentation must collapse.
    body = """
    <!DOCTYPE html>
    <html><head><title>429</title></head>
    <body>
      <h1>Too Many Requests</h1>
      <p>Your request has exceeded
        the API throttling limit of 380 requests per minute.</p>
      <p>Try again later.</p>
    </body></html>
    """
    err = ENTSOE.RateLimitError(; status = 429, retry_after = 60.0, body = body)
    msg = ENTSOE.rate_limit_message(err)
    @test msg == "Your request has exceeded the API throttling limit of 380 requests per minute."

    # showerror surfaces the parsed message so REPL users see it without
    # having to inspect `err.body` manually.
    rendered = sprint(showerror, err)
    @test occursin("HTTP 429", rendered)
    @test occursin("Retry-After: 60.0s", rendered)
    @test occursin("throttling limit of 380 requests per minute", rendered)
end

@testset "rate_limit_message returns nothing for empty / non-HTML bodies" begin
    @test ENTSOE.rate_limit_message(ENTSOE.RateLimitError()) === nothing
    @test ENTSOE.rate_limit_message(
        ENTSOE.RateLimitError(; body = "rate limit exceeded — not html"),
    ) === nothing
end
