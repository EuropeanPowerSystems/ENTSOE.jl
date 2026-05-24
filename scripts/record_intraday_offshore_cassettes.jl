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
    (
        "balancing_171f_prices_of_activated_balancing_energy_DE_LU.yml",
        () -> prices_of_activated_balancing_energy(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_171i_financial_expenses_DE_LU.yml",
        () -> financial_expenses_and_income_for_balancing(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1903_exchanged_reserve_capacity_DE_AT.yml",
        () -> exchanged_reserve_capacity(
            client, EIC.DE_LU, EIC.AT,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    # SO-GL reserve-capacity family. ENTSO-E publishes these patchily,
    # so most cassettes will record as Acknowledgement(999) — that
    # still proves the wire shape and acknowledgement handling.
    (
        "balancing_1854_criteria_application_DE_LU.yml",
        () -> results_of_criteria_application_process(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1872_fcr_total_capacity_DE_LU.yml",
        () -> fcr_total_capacity(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1872_shares_of_fcr_capacity_DE_LU.yml",
        () -> shares_of_fcr_capacity(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1883_frr_rr_capacity_outlook_DE_LU.yml",
        () -> frr_rr_capacity_outlook(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1884_frr_rr_actual_capacity_DE_LU.yml",
        () -> frr_and_rr_actual_capacity(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1892_outlook_of_reserve_capacities_on_rr_DE_LU.yml",
        () -> outlook_of_reserve_capacities_on_rr(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1893_rr_actual_capacity_DE_LU.yml",
        () -> rr_actual_capacity(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1901_sharing_of_rr_and_frr_DE_AT.yml",
        () -> sharing_of_rr_and_frr(
            client, EIC.DE_LU, EIC.AT,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "balancing_1902_sharing_of_fcr_between_sas_DE_LU.yml",
        () -> sharing_of_fcr_between_sas(
            client, EIC.DE_LU,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "outages_fall_backs_NL.yml",
        () -> outages_fall_backs(
            client, EIC.NL,
            DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
        ),
    ),
    (
        "transmission_91_expansion_BE_FR.yml",
        () -> expansion_and_dismantling_project(
            client, EIC.BE, EIC.FR,
            DateTime("2024-01-01"), DateTime("2024-06-01"),
        ),
    ),
    # Market allocation wrappers — mostly publish only for explicit
    # auction borders. Cassettes capture either the auction data or an
    # Acknowledgement(999) per zone+date.
    (
        "market_111a_explicit_allocations_offered_BE_GB.yml",
        () -> explicit_allocations_offered_transfer_capacity(
            client, EIC.BE, EIC.GB,
            202308152200, 202308162200;
            auction_category = "A04",
            sequence = 1,
            update_date_and_or_time = 20230313123900,
        ),
    ),
    (
        "market_111b_flow_based_allocations_REGION1V.yml",
        () -> flow_based_allocations(
            client, "10YDOM-REGION-1V", "10YDOM-REGION-1V",
            201402032300, 201402040500,
        ),
    ),
    (
        "market_111c_continuous_allocations_BE_NL.yml",
        () -> continuous_allocations_offered_transfer_capacity(
            client, EIC.BE, EIC.NL,
            202405152200, 202504162200;
            update_date_and_or_time = 20240515123900,
        ),
    ),
    (
        "market_111d_implicit_allocations_DK1_DE.yml",
        () -> implicit_allocations_offered_transfer_capacity(
            client, "10YDK-1--------W", EIC.DE_LU,
            202212312300, 202301012300;
            update_date_and_or_time = 20230313123900,
            sequence = 1,
        ),
    ),
    (
        "market_121a_explicit_allocations_auction_revenue_HR_BA.yml",
        () -> explicit_allocations_auction_revenue(
            client, "10YBA-JPCC-----D", EIC.HR,
            202308242200, 202308252200,
        ),
    ),
    (
        "market_121a_explicit_allocations_use_of_capacity_BE_GB.yml",
        () -> explicit_allocations_use_of_transfer_capacity(
            client, EIC.BE, EIC.GB,
            202308152200, 202308162200;
            auction_category = "A04",
            sequence = 1,
        ),
    ),
    (
        "market_121c_total_capacity_already_allocated_HR_BA.yml",
        () -> total_capacity_already_allocated(
            client, "10YBA-JPCC-----D", EIC.HR,
            202308242200, 202308252200;
            auction_category = "A02",
        ),
    ),
    (
        "market_121h_third_country_capacities_FI_RU.yml",
        () -> transfer_capacities_with_third_countries(
            client, "10Y1001A1001A49F", EIC.FI,
            202308232200, 202308242200;
            auction_category = "A04",
            sequence = 1,
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
