using ENTSOE
using Test

@testset "NoAuth leaves headers untouched" begin
    h = Dict{String, String}()
    ENTSOE.apply!(ENTSOE.NoAuth(), h)
    @test isempty(h)
end

@testset "build_pre_request_hook applies auth on the resource form" begin
    hook = ENTSOE.build_pre_request_hook(ENTSOE.NoAuth())
    res, body, hdr = hook("/r", nothing, Dict{String, String}("A" => "B"))
    @test res == "/r"
    @test body === nothing
    @test hdr == Dict("A" => "B")
    # Ctx form is a pass-through.
    @test hook(:ctx_sentinel) === :ctx_sentinel
end
