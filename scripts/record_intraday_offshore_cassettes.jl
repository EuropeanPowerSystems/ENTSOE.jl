#!/usr/bin/env julia
# record_intraday_offshore_cassettes.jl
# =====================================
#
# Re-record cassettes for the entsoe-py-parity wrappers landed in
# `src/conveniences/queries.jl`:
#
#   - intraday_prices
#   - intraday_wind_solar_forecast
#   - year_ahead_forecast_margin
#   - unavailability_of_offshore_grid
#
# Token resolution: `ENV["ENTSOE_API_TOKEN"]` first, then `token.txt`
# at the repo root.

using Pkg

const ROOT = normpath(joinpath(@__DIR__, ".."))
Pkg.activate(ROOT; io = devnull)

Pkg.activate(joinpath(ROOT, "test"); io = devnull)
using BrokenRecord
Pkg.activate(ROOT; io = devnull)

using Dates
using ENTSOE

const CASSETTES = joinpath(ROOT, "test", "cassettes")

# Match the test/_brokenrecord_helpers.jl setup so playback finds the
# same on-disk shape.
let target = Base.Threads.maxthreadid()
    while length(BrokenRecord.STATE) < target
        push!(
            BrokenRecord.STATE, (
                responses = empty(BrokenRecord.STATE[1].responses),
                ignore_headers = String[],
                ignore_query = String[],
            )
        )
    end
end

BrokenRecord.configure!(;
    path = CASSETTES,
    ignore_headers = [
        "Authorization", "X-API-Key", "api_key", "X-Api-Key",
        "Cookie", "Set-Cookie", "Proxy-Authorization",
        "User-Agent", "Accept-Encoding",
    ],
    ignore_query = ["api_key", "token", "access_token", "securityToken"],
)

const TOKEN = let env = get(ENV, "ENTSOE_API_TOKEN", "")
    if !isempty(env)
        env
    else
        tok = joinpath(ROOT, "token.txt")
        isfile(tok) || error("Set ENTSOE_API_TOKEN or write your token to $tok")
        strip(read(tok, String))
    end
end

client = ENTSOEClient(TOKEN)

# Each entry: (cassette_name, callable). Cassette is re-recorded if
# missing; existing cassettes are left alone (delete to force).
const JOBS = Any[
    (
        "market_121d_intraday_prices_DE_LU.yml",
        () -> intraday_prices(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "generation_141d_intraday_wind_solar_forecast_NL.yml",
        () -> intraday_wind_solar_forecast(
            client, EIC.NL,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "load_81_year_ahead_forecast_margin_BE.yml",
        () -> year_ahead_forecast_margin(
            client, EIC.BE,
            DateTime("2023-12-31T23:00"), DateTime("2024-12-31T23:00"),
        ),
    ),
    (
        "outages_101c_unavailability_offshore_grid_DE_LU.yml",
        () -> unavailability_of_offshore_grid(
            client, EIC.DE_LU,
            DateTime("2024-01-01"), DateTime("2024-04-01"),
        ),
    ),
]

for (cassette, fn) in JOBS
    path = joinpath(CASSETTES, cassette)
    bson_path = replace(path, r"\.yml$" => ".bson")
    if isfile(path) || isfile(bson_path)
        @info "skip (exists)" cassette
        continue
    end
    @info "recording" cassette
    try
        BrokenRecord.playback(fn, cassette)
        @info "  ok" cassette
    catch err
        if err isa ENTSOEAcknowledgement
            @info "  recorded (acknowledgement)" cassette err.reason_code
        else
            @warn "  failed" cassette exception = err
        end
    end
    # Mirror `regenerate_smoke_cassettes.jl`: if the body was ZIP, the
    # YAML cassette is corrupt at replay time. Re-record as BSON.
    if isfile(path) && occursin("application/zip", read(path, String))
        rm(path)
        bson_name = replace(cassette, r"\.yml$" => ".bson")
        BrokenRecord.configure!(extension = "bson")
        try
            BrokenRecord.playback(fn, bson_name)
            @info "  re-recorded as BSON (binary response)" bson_name
        catch err
            err isa ENTSOEAcknowledgement ||
                @warn "  BSON re-record failed" bson_name exception = err
        end
        # Restore default extension for subsequent jobs.
        BrokenRecord.configure!(extension = "yml")
    end
end
