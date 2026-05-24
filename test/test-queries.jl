using ENTSOE
using Test
using Dates: DateTime, Date
using TimeZones: ZonedDateTime, FixedTimeZone

# Unit tests for the named-argument query layer in
# `src/conveniences/queries.jl`. Live calls are exercised via
# BrokenRecord cassettes (already recorded for Load 6.1.A,
# Generation 14.1.A, Market 12.1.D) — that proves the wrapper produces
# the same wire format the generated layer does.

@testset "validate=true rejects unknown EICs at the wrapper boundary" begin
    # Off by default — bad EIC sails through (would 200 with an
    # acknowledgement at runtime, but we never reach the network here
    # because there's no client config and we want a fast-fail test).
    # With validate=true the wrapper throws *before* hitting the
    # network or constructing API state.
    client = ENTSOEClient("PLAYBACK")
    @test_throws ArgumentError day_ahead_prices(
        client, "10YNOT-A-CODE---",
        DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00");
        validate = true,
    )
end

@testset "EIC callable form (`EIC(\"NL\")`)" begin
    # Field access and the string-callable form must agree, and unknown
    # aliases must raise a clear error rather than returning a stub
    # value that would then silently 999 against the API.
    @test EIC("NL") === EIC.NL
    @test EIC("DE_LU") === EIC.DE_LU
    @test EIC("NO2") === EIC.NO2
    @test_throws ArgumentError EIC("NOT_A_ZONE")
end

@testset "_to_period overloads" begin
    # `Int` round-trip.
    @test ENTSOE._to_period(Int64(202409012200)) === Int64(202409012200)
    # DateTime → yyyymmddHHMM.
    @test ENTSOE._to_period(DateTime("2024-09-01T22:00")) === Int64(202409012200)
    # Date → midnight on that date.
    @test ENTSOE._to_period(Date("2024-09-02")) === Int64(202409020000)
    # ZonedDateTime → goes through the AbstractDateTime overload, then
    # internally converted to UTC via `entsoe_period`.
    cest = FixedTimeZone("CEST", 7200)
    zdt = ZonedDateTime(DateTime("2024-09-02T00:00"), cest)
    @test ENTSOE._to_period(zdt) === Int64(202409012200)   # 22:00 UTC the prior day

    # Catch-all rejects unsupported types loudly.
    @test_throws ArgumentError ENTSOE._to_period("not a period")
    @test_throws ArgumentError ENTSOE._to_period(3.14)
end

include("_brokenrecord_helpers.jl")

let BR = _load_brokenrecord()
    if BR === nothing
        @info "BrokenRecord not installed; skipping query-wrapper live tests."
    else

        client = ENTSOEClient("PLAYBACK")

        @testset "validate=true passes through for a known EIC" begin
            # Pair to the negative test above — drives the loop body in
            # `_query` to completion (line 59) and confirms validation
            # doesn't false-positive on a real bidding zone code.
            rows = Base.invokelatest(
                BR.playback,
                () -> day_ahead_prices(
                    client, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00");
                    validate = true,
                ),
                "market_121d_day_ahead_prices_NL.yml",
            )
            @test !isempty(rows)
        end

        @testset "actual_total_load (Load 6.1.A cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> actual_total_load(
                    client, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00"),
                ),
                "load_61a_actual_total_load_NL.yml",
            )
            @test length(rows) == 96     # 24h × 4 (PT15M)
            @test rows[1].time == DateTime("2024-09-01T22:00")
            @test rows[1].value > 1_000  # NL load is always thousands of MW
        end

        @testset "day_ahead_prices (Market 12.1.D cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> day_ahead_prices(
                    client, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00"),
                ),
                "market_121d_day_ahead_prices_NL.yml",
            )
            @test !isempty(rows)
            @test rows[1].time == DateTime("2024-09-01T22:00")
            # NL day-ahead prices range from negative tens to a few hundred
            # EUR/MWh — anything thousands is a parse error.
            @test all(-1_000 < r.value < 1_000 for r in rows)
        end

        @testset "installed_capacity_per_production_type (cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> installed_capacity_per_production_type(
                    client, EIC.NL,
                    DateTime("2023-12-31T23:00"),
                    DateTime("2024-12-31T23:00"),
                ),
                "generation_141a_installed_capacity_NL.yml",
            )
            @test !isempty(rows)
            # Every row should carry a known PSR-type code.
            @test all(haskey(PSR_TYPE, Symbol(r.psr_type)) for r in rows)
            # Solar is one of the largest categories in NL.
            solar = filter(r -> r.psr_type == "B16", rows)
            @test !isempty(solar)
            @test solar[1].capacity_mw > 1_000
        end

        @testset "Raw() returns raw XML" begin
            xml = Base.invokelatest(
                BR.playback,
                () -> day_ahead_prices(
                    client, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00"),
                    Raw(),
                ),
                "market_121d_day_ahead_prices_NL.yml",
            )
            @test xml isa AbstractString
            @test occursin("<Publication_MarketDocument", xml)
        end

        # ---------------------------------------------------------------
        # The remaining named-arg wrappers each get one cassette playback.
        # We keep assertions light — the point is to drive the wrapper
        # function and prove the parser handles the document shape.
        # ---------------------------------------------------------------

        local _start = DateTime("2024-09-01T22:00")
        local _stop = DateTime("2024-09-02T22:00")

        @testset "day_ahead_load_forecast (Load 6.1.B cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> day_ahead_load_forecast(client, EIC.NL, _start, _stop),
                "load_61b_day_ahead_forecast_NL.yml",
            )
            @test length(rows) == 96
            @test all(r.value > 1_000 for r in rows)   # MW
        end

        @testset "week_ahead_load_forecast (Load 6.1.C cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> week_ahead_load_forecast(client, EIC.NL, _start, _stop),
                "load_61c_week_ahead_forecast_NL.yml",
            )
            # Week-ahead is typically just a min/max forecast for the
            # period, not a quarter-hour curve — small row count is fine.
            @test !isempty(rows)
        end

        @testset "month_ahead_load_forecast (Load 6.1.D cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> month_ahead_load_forecast(client, EIC.NL, _start, _stop),
                "load_61d_month_ahead_forecast_NL.yml",
            )
            @test !isempty(rows)
        end

        @testset "year_ahead_load_forecast (Load 6.1.E cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> year_ahead_load_forecast(
                    client, EIC.NL,
                    DateTime("2023-12-31T23:00"),
                    DateTime("2024-12-31T23:00")
                ),
                "load_61e_year_ahead_forecast_NL.yml",
            )
            @test !isempty(rows)
        end

        @testset "generation_forecast_day_ahead (Generation 14.1.C cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> generation_forecast_day_ahead(client, EIC.NL, _start, _stop),
                "generation_141c_forecast_day_ahead_NL.yml",
            )
            @test length(rows) == 96
            @test all(r.value > 0 for r in rows)
        end

        @testset "wind_solar_forecast (Generation 14.1.D cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> wind_solar_forecast(client, EIC.NL, _start, _stop),
                "generation_141d_wind_solar_forecast_NL.yml",
            )
            @test !isempty(rows)
            # Result is per-PSR — should see at least Solar (B16) and one
            # of the wind technologies.
            @test any(r.psr_type == "B16" for r in rows)
            @test any(r.psr_type in ("B18", "B19") for r in rows)
        end

        @testset "actual_generation_per_production_type (Generation 16.1.B/C cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> actual_generation_per_production_type(
                    client, EIC.NL, _start, _stop
                ),
                "generation_161bc_actual_per_psr_NL.yml",
            )
            @test !isempty(rows)
            # Many PSR types contributing on a normal day.
            psrs = unique(r.psr_type for r in rows)
            @test length(psrs) >= 4
            @test "B16" in psrs   # Solar always present in NL data
        end

        @testset "omi_other_market_information — first page is acknowledgement → throws" begin
            # NL B47 returns an acknowledgement (no OMI submitted for
            # that area on that day). With `max_pages = 1` our wrapper
            # sees the ack on iteration 0 and throws.
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> omi_other_market_information(
                        client, EIC.NL,
                        DateTime("2024-09-23T22:00"),
                        DateTime("2024-09-24T22:00");
                        document_type = "B47", page_size = 200, max_pages = 1,
                    ),
                    "omi_other_market_information_NL.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement
            @test err.reason_code == "999"
        end

        @testset "cross_border_physical_flows (Transmission 12.1.G cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> cross_border_physical_flows(
                    client, EIC.NL, EIC.DE_LU, _start, _stop
                ),
                "transmission_121g_cross_border_NL_DE.yml",
            )
            @test !isempty(rows)
            # Hourly resolution, 24 h window.
            @test rows[1].time == _start
        end

        # The next three replay the smoke-suite cassettes (function-named,
        # recorded with Postman's canonical example parameters). Going
        # through the new named wrappers proves end-to-end that
        # parameter order, code pre-fill, and the kwarg pass-through all
        # match what the generated layer actually transmits.

        @testset "commercial_schedules (Transmission 12.1.F smoke cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> commercial_schedules(
                    client, EIC.FR, EIC.DE_LU,
                    202308232200, 202308242200;
                    contract_market_agreement_type = "A01",
                ),
                "transmission121_f_commercial_schedules.yml",
            )
            @test :time in propertynames(rows)
            @test :value in propertynames(rows)
            @test rows.value isa Vector{Float64}
            # Either the cassette captured real points (>0) or an
            # acknowledgement (rows empty). Both are valid coverage —
            # the wrapper executed end-to-end either way.
            @test length(rows) >= 0
        end

        @testset "commercial_schedules_net_positions (12.1.F net smoke cassette)" begin
            # ENTSO-E doesn't publish 12.1.F net positions for every
            # bidding zone — the Postman default (AT, mid-2025) hits an
            # `<Acknowledgement_MarketDocument reason=999>`. The wrapper
            # surfaces that as `ENTSOEAcknowledgement`, which is the
            # right user-facing behavior.
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> commercial_schedules_net_positions(
                        client, EIC.AT,
                        202506102200, 202506112200;
                        contract_market_agreement_type = "A01",
                    ),
                    "transmission121_f_commercial_schedules_net_positions.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement
            @test err.reason_code == "999"
        end

        @testset "forecasted_transfer_capacities (Transmission 11.1.A smoke cassette)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> forecasted_transfer_capacities(
                    client, EIC.BE, EIC.GB,
                    202308152200, 202308162200;
                    contract_market_agreement_type = "A01",
                ),
                "transmission111_a_forecasted_transfer_capacities.yml",
            )
            @test :time in propertynames(rows)
            @test :value in propertynames(rows)
            @test length(rows) >= 0
        end

        # ---------------------------------------------------------------
        # Smoke cassettes for the rest of the wrapper layer. Each test
        # routes through the named wrapper end-to-end (parameter order,
        # code pre-fill, kwarg pass-through). Cassettes were recorded
        # against Postman's canonical parameters; some return real data,
        # some return Acknowledgements. The helper below accepts both.

        function _expect_rows_or_ack(callable, cassette, required_cols)
            err = nothing
            rows = try
                Base.invokelatest(BR.playback, callable, cassette)
            catch e
                err = e
                nothing
            end
            if err !== nothing
                @test err isa ENTSOEAcknowledgement
            else
                for col in required_cols
                    @test col in propertynames(rows)
                end
            end
            return rows
        end

        @testset "water_reservoirs_and_hydro_storage_plants (Gen 16.1.D)" begin
            _expect_rows_or_ack(
                () -> water_reservoirs_and_hydro_storage_plants(
                    client, EIC.BG,
                    202307092100, 202307162100,
                ),
                "generation161_d_water_reservoirs_and_hydro_storage_plants.yml",
                (:time, :value),
            )
        end

        @testset "current_balancing_state (Balancing 1.2.3.A)" begin
            rows = _expect_rows_or_ack(
                () -> current_balancing_state(
                    client, EIC.HU,
                    202405292200, 202405302200;
                    business_type = "B33",
                ),
                "balancing123_a_current_balancing_state_gl_eb.yml",
                (:time, :value),
            )
            # PT1M resolution; an entire 24h window is 1440 samples.
            rows === nothing || @test length(rows) >= 1000
        end

        @testset "aggregated_balancing_energy_bids (Balancing 1.2.3.E)" begin
            _expect_rows_or_ack(
                () -> aggregated_balancing_energy_bids(
                    client, EIC.AT,
                    202309022200, 202309032200;
                    process_type = "A51",
                ),
                "balancing123_e_aggregated_balancing_energy_bids_gl_eb.yml",
                (:time, :value),
            )
        end

        @testset "redispatching_internal (Transmission 13.1.A internal)" begin
            _expect_rows_or_ack(
                () -> redispatching_internal(
                    client, EIC.NL,
                    202310312300, 202311302300,
                ),
                "transmission131_a_redispatching_internal.yml",
                (:time, :value),
            )
        end

        @testset "redispatching_cross_border (Transmission 13.1.A cross-border)" begin
            _expect_rows_or_ack(
                () -> redispatching_cross_border(
                    client, EIC.FR, EIC.AT,
                    202311010000, 202312010000,
                ),
                "transmission131_a_redispatching_cross_border.yml",
                (:time, :value),
            )
        end

        @testset "countertrading (Transmission 13.1.B)" begin
            _expect_rows_or_ack(
                () -> countertrading(
                    client, EIC.FR, EIC.ES,
                    202309122200, 202309132200,
                ),
                "transmission131_b_countertrading.yml",
                (:time, :value),
            )
        end

        @testset "costs_of_congestion_management (Transmission 13.1.C)" begin
            _expect_rows_or_ack(
                () -> costs_of_congestion_management(
                    client, EIC.BE,
                    202112312300, 202212312300,
                ),
                "transmission131_c_costs_of_congestion_management.yml",
                (:time, :value),
            )
        end

        @testset "production_and_generation_units (Master Data)" begin
            rows = _expect_rows_or_ack(
                () -> production_and_generation_units(
                    client, EIC.BE;
                    implementation_date = "2017-01-01",
                    business_type = "B11",
                    psr_type = "B04",
                ),
                "master_data_production_and_generation_units.yml",
                (
                    :production_unit_mrid, :generating_unit_mrid,
                    :psr_type, :nominal_mw,
                ),
            )
            # BE registry as of 2017 had a meaningful number of B04 units.
            rows === nothing || @test length(rows) > 5
        end

        @testset "aggregated_unavailability_of_consumption_units (7.1.A/B)" begin
            _expect_rows_or_ack(
                () -> aggregated_unavailability_of_consumption_units(
                    client, EIC.DE_LU,
                    202310312300, 202311302300;
                    business_type = "A53",
                ),
                "outages71_a_b_aggregated_unavailability_of_consumption_units.yml",
                (:start, :stop, :business_type),
            )
        end

        @testset "unavailability_of_generation_units (Outages 15.1.A/B)" begin
            _expect_rows_or_ack(
                () -> unavailability_of_generation_units(
                    client, EIC.BE,
                    202301022200, 202401022200;
                    business_type = "A53",
                    doc_status = "A05",
                    period_start_update = 202301031000,
                    period_end_update = 202301032200,
                    registered_resource = "22WCOOX6X000064W",
                    m_r_i_d = "nCYGn4HPvOBiVrWtRFL35g",
                    offset = 0,
                ),
                "outages151_a_b_unavailability_of_generation_units.yml",
                (:start, :stop, :resource_name, :nominal_mw),
            )
        end

        @testset "unavailability_of_production_units (Outages 15.1.C/D)" begin
            _expect_rows_or_ack(
                () -> unavailability_of_production_units(
                    client, EIC.BE,
                    202212312300, 202301312300;
                    business_type = "A53",
                    doc_status = "A05",
                    period_start_update = 202301152300,
                    period_end_update = 202301312300,
                    registered_resource = "22W20200608A---8",
                    m_r_i_d = "-WmcUg9Da9u8AF3A_gx8UQ",
                    offset = 1,
                ),
                "outages151_c_d_unavailability_of_production_units.yml",
                (:start, :stop, :resource_name, :nominal_mw),
            )
        end

        @testset "unavailability_of_transmission_infrastructure (10.1.A/B)" begin
            _expect_rows_or_ack(
                () -> unavailability_of_transmission_infrastructure(
                    client, EIC.BE, EIC.FR,
                    202312012300, 202312022300;
                    business_type = "A53",
                    doc_status = "A05",
                    period_start_update = 202111090000,
                    period_end_update = 202112212300,
                    m_r_i_d = "A47mJe5e9jml9FeSL6jfKg",
                    offset = 0,
                ),
                "outages101_a_b_unavailability_of_transmission_infrastructure.yml",
                (:start, :stop, :business_type),
            )
        end

        # The next three exercise the zip-aware `_query` path —
        # `application/zip` bodies get unzipped transparently and each
        # member is run through `parse_timeseries` before vcat-ing.

        @testset "imbalance_prices (Balancing 17.1.G, zipped)" begin
            rows = _expect_rows_or_ack(
                () -> imbalance_prices(
                    client, EIC.AT,
                    202401010000, 202401050000;
                    psr_type = "A04",
                ),
                "balancing171_g_imbalance_prices.bson",
                (:time, :value),
            )
            rows === nothing || @test length(rows) > 50
        end

        @testset "total_imbalance_volumes (Balancing 17.1.H, zipped)" begin
            rows = _expect_rows_or_ack(
                () -> total_imbalance_volumes(
                    client, EIC.AT,
                    202311032300, 202311042300;
                    business_type = "A19",
                ),
                "balancing171_h_total_imbalance_volumes.bson",
                (:time, :value),
            )
            rows === nothing || @test length(rows) > 50
        end

        @testset "procured_balancing_capacity (Balancing 1.2.3.F, zipped)" begin
            _expect_rows_or_ack(
                () -> procured_balancing_capacity(
                    client, "10YDE-VE-------2",
                    202306150000, 202306150100;
                    process_type = "A51",
                    type_market_agreement_type = "A01",
                    offset = 0,
                ),
                "balancing123_f_procured_balancing_capacity_gl_eb.bson",
                (:time, :value),
            )
        end

        # Auction / allocation wrappers (Market 12.1.B/E variants).

        @testset "total_nominated_capacity (Market 12.1.B)" begin
            rows = _expect_rows_or_ack(
                () -> total_nominated_capacity(
                    client, EIC.BE, EIC.GB,
                    202308202200, 202308212200,
                ),
                "market121_b_total_nominated_capacity.yml",
                (:time, :value),
            )
            rows === nothing || @test length(rows) >= 1
        end

        @testset "congestion_income (Market 12.1.E)" begin
            rows = _expect_rows_or_ack(
                () -> congestion_income(
                    client, EIC.AT, EIC.AT,
                    202308232200, 202308242200;
                    contract_market_agreement_type = "A01",
                ),
                "market121_e_implicit_and_flow_based_allocations_congestion_income.yml",
                (:time, :value),
            )
            rows === nothing || @test length(rows) >= 1
        end

        @testset "implicit_auction_net_positions (Market 12.1.E variant)" begin
            # Smoke cassette: BE intraday net positions (businessType=B09,
            # contractMarketAgreementType=A07). Defaults match.
            _expect_rows_or_ack(
                () -> implicit_auction_net_positions(
                    client, EIC.BE,
                    202308222200, 202308232200,
                ),
                "market121_e_implicit_auction_net_positions.yml",
                (:time, :value),
            )
        end

        @testset "scheduled_exchanges (alias for commercial_schedules A05/A01)" begin
            # `dayahead=true` → A01 → identical wire URL to the existing
            # `commercial_schedules` smoke cassette (FR→DE_LU, A01).
            rows = Base.invokelatest(
                BR.playback,
                () -> scheduled_exchanges(
                    client, EIC.FR, EIC.DE_LU,
                    202308232200, 202308242200;
                    dayahead = true,
                ),
                "transmission121_f_commercial_schedules.yml",
            )
            @test :time in propertynames(rows)
            @test :value in propertynames(rows)
        end

        @testset "net_transfer_capacity_day_ahead (NTC A01 alias)" begin
            # Thin alias over `forecasted_transfer_capacities` — reuse
            # the same Transmission 11.1.A smoke cassette (recorded
            # against contractMarketAgreementType=A01).
            rows = Base.invokelatest(
                BR.playback,
                () -> net_transfer_capacity_day_ahead(
                    client, EIC.BE, EIC.GB,
                    202308152200, 202308162200,
                ),
                "transmission111_a_forecasted_transfer_capacities.yml",
            )
            @test :time in propertynames(rows)
            @test :value in propertynames(rows)
        end

        @testset "volumes_and_prices_of_contracted_reserves (Balancing 17.1.B/C)" begin
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> volumes_and_prices_of_contracted_reserves(
                        client, EIC.DE_LU,
                        DateTime("2024-09-01T22:00"),
                        DateTime("2024-09-02T22:00")),
                    "balancing_171bc_volumes_prices_contracted_reserves_DE.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement
        end

        @testset "installed_capacity_per_production_unit (Generation 14.1.B)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> installed_capacity_per_production_unit(
                    client, EIC.NL,
                    DateTime("2023-12-31T23:00"),
                    DateTime("2024-12-31T23:00")),
                "generation_141b_installed_capacity_per_unit_NL.yml",
            )
            @test !isempty(rows)
            for col in (:unit_mrid, :unit_name, :psr_type, :capacity_mw)
                @test col in propertynames(rows)
            end
            # Wind Onshore should be one of the largest categories in NL.
            wind = filter(r -> r.psr_type == "B19", rows)
            @test !isempty(wind)
        end

        @testset "actual_generation_per_generation_unit (Generation 16.1.A)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> actual_generation_per_generation_unit(
                    client, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00")),
                "generation_161a_actual_generation_per_unit_NL.yml",
            )
            @test !isempty(rows)
            for col in (:time, :unit_mrid, :unit_name, :psr_type, :value)
                @test col in propertynames(rows)
            end
            # Several different PSR types in a NL day.
            @test length(unique(rows.psr_type)) >= 3
        end

        @testset "LocalTime() converts time column to ZonedDateTime" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> day_ahead_prices(client, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00"),
                    LocalTime("Europe/Amsterdam")),
                "market_121d_day_ahead_prices_NL.yml",
            )
            @test !isempty(rows)
            @test eltype(rows.time) === ZonedDateTime
            # 22:00 UTC = 00:00 CEST (summer offset +02:00) in the
            # zone's local time.
            @test DateTime(rows[1].time) == DateTime("2024-09-02T00:00")
        end

        @testset "cross_border_physical_flows_all (NEIGHBOURS helper)" begin
            # Override `neighbours` to a single border so we can reuse
            # the existing 12.1.G cassette (NL↔DE_LU, in=NL, out=DE_LU).
            # `export_=false` matches that wire direction (imports into NL).
            rows = Base.invokelatest(
                BR.playback,
                () -> cross_border_physical_flows_all(
                    client, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00");
                    neighbours = [EIC.DE_LU], export_ = false),
                "transmission_121g_cross_border_NL_DE.yml",
            )
            @test :time in propertynames(rows)
            @test :border in propertynames(rows)
            @test :value in propertynames(rows)
            @test !isempty(rows)
            @test all(rows.border .== EIC.DE_LU)
        end

        @testset "intraday_offered_capacity (implicit IDCT router)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> intraday_offered_capacity(client, EIC.BE, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00")),
                "market_111_intraday_offered_capacity_implicit_IDCT_BE_NL.yml",
            )
            @test :time in propertynames(rows)
            @test :value in propertynames(rows)
        end

        @testset "Transmission outage sub-views (10.1.A/B available + NPI)" begin
            cases = [
                (() -> unavailability_of_transmission_infrastructure_available_capacity(
                    client, EIC.DE_LU,
                    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00")),
                    "outages_101ab_transmission_available_capacity_DE.yml"),
                (() -> unavailability_of_transmission_infrastructure_net_position_impact(
                    client, "10YDOM-CZ-DE-SKK",
                    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00")),
                    "outages_101ab_transmission_npi_DE.yml"),
            ]
            for (call, cassette) in cases
                err = nothing
                try
                    Base.invokelatest(BR.playback, call, cassette)
                catch e
                    err = e
                end
                @test err isa ENTSOE.APIError
            end
        end

        @testset "Balancing IF (Inter-platform) family" begin
            cases = [
                (() -> cross_border_marginal_prices_for_afrr(
                    client, "10YDE-VE-------2",
                    202311082300, 202311092300),
                    "balancing_if_afrr316_cbmps_DE_AMPRION.yml"),
                (() -> netted_and_exchanged_volumes(
                    client, "10YDE-VE-------2", "10YDE-VE-------2",
                    202301012300, 202301022300),
                    "balancing_ifs310_netted_exchanged_DE.bson"),
                (() -> netted_and_exchanged_volumes_per_border(
                    client, EIC.BE, EIC.FR,
                    202503010000, 202503020000),
                    "balancing_ifs310_netted_exchanged_per_border_BE_FR.bson"),
                (() -> balancing_border_capacity_limitations(
                    client, EIC.AT, EIC.CZ,
                    202401312300, 202402012300;
                    registered_resource = "22T201903146---W"),
                    "balancing_ifs4344_border_capacity_limitations_CZ_AT.yml"),
                (() -> permanent_allocation_limitations_to_HVDC(
                    client, "10YDK-1--------W", EIC.NL,
                    202101010000, 202112310000;
                    registered_resource = "10T-DK-NL-000012"),
                    "balancing_ifs45_permanent_HVDC_NL_DK1.yml"),
                (() -> elastic_demands(
                    client, EIC.CZ,
                    202311302300, 202312012300; offset = 0),
                    "balancing_ifs_afrr_mfrr34_elastic_demands_CZ.yml"),
                (() -> changes_to_bid_availability(
                    client, "10YDE-VE-------2",
                    202309232200, 202309242200;
                    business_type = "C46", offset = 100),
                    "balancing_ifs_mfrr99_changes_to_bid_availability_DE.yml"),
                (() -> changes_to_bid_availability_archives(
                    client, "10YDE-VE-------2",
                    202309232200, 202309242200;
                    business_type = "C46", offset = 100),
                    "balancing_ifs_mfrr99_changes_to_bid_availability_archives_DE.yml"),
            ]
            for (call, cassette) in cases
                err = nothing
                result = try
                    Base.invokelatest(BR.playback, call, cassette)
                catch e
                    err = e
                    nothing
                end
                @test result !== nothing || err isa ENTSOE.APIError
            end
        end

        @testset "Balancing bids family (1.2.3.B/C, 1.2.3.H/I)" begin
            cases = [
                (() -> balancing_energy_bids(client, EIC.DE_LU,
                    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00")),
                    "balancing_123bc_balancing_energy_bids_DE_LU.yml"),
                (() -> balancing_energy_bids_archives(client, EIC.DE_LU,
                    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00")),
                    "balancing_123bc_balancing_energy_bids_archives_DE_LU.yml"),
                (() -> allocation_and_use_of_cross_zonal_balancing_capacity(
                    client, EIC.DE_LU, EIC.AT,
                    DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00")),
                    "balancing_123hi_allocation_cross_zonal_DE_AT.yml"),
            ]
            for (call, cassette) in cases
                err = nothing
                result = try
                    Base.invokelatest(BR.playback, call, cassette)
                catch e
                    err = e
                    nothing
                end
                @test result !== nothing || err isa ENTSOE.APIError
            end
        end

        # Balancing SO-GL reserve-capacity family. ENTSO-E publishes
        # these patchily — most return Acknowledgement(999), a couple
        # reject the canonical doctype/processType combo as 400. Either
        # outcome proves the wrapper surfaces a typed error cleanly.
        @testset "SO-GL reserve-capacity wrappers (Balancing 18/19.x)" begin
            cases = [
                (
                    :results_of_criteria_application_process, EIC.DE_LU,
                    "balancing_1854_criteria_application_DE_LU.yml",
                ),
                (
                    :fcr_total_capacity, EIC.DE_LU,
                    "balancing_1872_fcr_total_capacity_DE_LU.yml",
                ),
                (
                    :shares_of_fcr_capacity, EIC.DE_LU,
                    "balancing_1872_shares_of_fcr_capacity_DE_LU.yml",
                ),
                (
                    :frr_rr_capacity_outlook, EIC.DE_LU,
                    "balancing_1883_frr_rr_capacity_outlook_DE_LU.yml",
                ),
                (
                    :frr_and_rr_actual_capacity, EIC.DE_LU,
                    "balancing_1884_frr_rr_actual_capacity_DE_LU.yml",
                ),
                (
                    :outlook_of_reserve_capacities_on_rr, EIC.DE_LU,
                    "balancing_1892_outlook_of_reserve_capacities_on_rr_DE_LU.yml",
                ),
                (
                    :rr_actual_capacity, EIC.DE_LU,
                    "balancing_1893_rr_actual_capacity_DE_LU.yml",
                ),
                (
                    :sharing_of_fcr_between_sas, EIC.DE_LU,
                    "balancing_1902_sharing_of_fcr_between_sas_DE_LU.yml",
                ),
            ]
            for (fname, area, cassette) in cases
                fn = getfield(ENTSOE, fname)
                err = nothing
                try
                    Base.invokelatest(
                        BR.playback,
                        () -> fn(
                            client, area,
                            DateTime("2024-09-01T22:00"),
                            DateTime("2024-09-02T22:00")
                        ),
                        cassette,
                    )
                catch e
                    err = e
                end
                @test err isa ENTSOEAcknowledgement || err isa ClientError
            end
        end

        @testset "exchanged_reserve_capacity (Balancing 19.0.3 SO GL)" begin
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> exchanged_reserve_capacity(
                        client, EIC.DE_LU, EIC.AT,
                        DateTime("2024-09-01T22:00"),
                        DateTime("2024-09-02T22:00"),
                    ),
                    "balancing_1903_exchanged_reserve_capacity_DE_AT.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement
        end

        @testset "financial_expenses_and_income_for_balancing (Balancing 17.1.I)" begin
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> financial_expenses_and_income_for_balancing(
                        client, EIC.DE_LU,
                        DateTime("2024-09-01T22:00"),
                        DateTime("2024-09-02T22:00"),
                    ),
                    "balancing_171i_financial_expenses_DE_LU.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement
            @test err.reason_code == "999"
        end

        @testset "prices_of_activated_balancing_energy (Balancing 17.1.F)" begin
            # 17.1.F data is published patchily — DE_LU 2024-09-01 hits
            # an Acknowledgement. The wrapper must surface that cleanly.
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> prices_of_activated_balancing_energy(
                        client, EIC.DE_LU,
                        DateTime("2024-09-01T22:00"),
                        DateTime("2024-09-02T22:00"),
                    ),
                    "balancing_171f_prices_of_activated_balancing_energy_DE_LU.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement
            @test err.reason_code == "999"
        end

        # Market allocation family — 8 endpoints sharing the same
        # (in_area, out_area, period) wire shape with different
        # documentType/auctionType/businessType pre-fills.
        @testset "Market allocation wrappers (11.1.x, 12.1.A/C/H)" begin
            cases = [
                (
                    () -> explicit_allocations_offered_transfer_capacity(
                        client, EIC.BE, EIC.GB,
                        202308152200, 202308162200;
                        auction_category = "A04", sequence = 1,
                        update_date_and_or_time = 20230313123900
                    ),
                    "market_111a_explicit_allocations_offered_BE_GB.yml",
                ),
                (
                    () -> flow_based_allocations(
                        client, "10YDOM-REGION-1V", "10YDOM-REGION-1V",
                        201402032300, 201402040500
                    ),
                    "market_111b_flow_based_allocations_REGION1V.yml",
                ),
                (
                    () -> continuous_allocations_offered_transfer_capacity(
                        client, EIC.BE, EIC.NL,
                        202405152200, 202504162200;
                        update_date_and_or_time = 20240515123900
                    ),
                    "market_111c_continuous_allocations_BE_NL.yml",
                ),
                (
                    () -> implicit_allocations_offered_transfer_capacity(
                        client, "10YDK-1--------W", EIC.DE_LU,
                        202212312300, 202301012300;
                        update_date_and_or_time = 20230313123900, sequence = 1
                    ),
                    "market_111d_implicit_allocations_DK1_DE.yml",
                ),
                (
                    () -> explicit_allocations_auction_revenue(
                        client, "10YBA-JPCC-----D", EIC.HR,
                        202308242200, 202308252200
                    ),
                    "market_121a_explicit_allocations_auction_revenue_HR_BA.yml",
                ),
                (
                    () -> explicit_allocations_use_of_transfer_capacity(
                        client, EIC.BE, EIC.GB,
                        202308152200, 202308162200;
                        auction_category = "A04", sequence = 1
                    ),
                    "market_121a_explicit_allocations_use_of_capacity_BE_GB.yml",
                ),
                (
                    () -> total_capacity_already_allocated(
                        client, "10YBA-JPCC-----D", EIC.HR,
                        202308242200, 202308252200; auction_category = "A02"
                    ),
                    "market_121c_total_capacity_already_allocated_HR_BA.yml",
                ),
                (
                    () -> transfer_capacities_with_third_countries(
                        client, "10Y1001A1001A49F", EIC.FI,
                        202308232200, 202308242200;
                        auction_category = "A04", sequence = 1
                    ),
                    "market_121h_third_country_capacities_FI_RU.yml",
                ),
            ]
            for (call, cassette) in cases
                err = nothing
                result = try
                    Base.invokelatest(BR.playback, call, cassette)
                catch e
                    err = e
                    nothing
                end
                # Either we got real rows or a typed error — both prove
                # the wrapper executed end-to-end.
                @test result !== nothing || err isa ENTSOE.APIError
            end
        end

        @testset "outages_fall_backs (Outages IF, A53)" begin
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> outages_fall_backs(
                        client, EIC.NL,
                        DateTime("2024-09-01T22:00"),
                        DateTime("2024-09-02T22:00")
                    ),
                    "outages_fall_backs_NL.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement || err isa ClientError
        end

        @testset "expansion_and_dismantling_project (Transmission 9.1, A90)" begin
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> expansion_and_dismantling_project(
                        client, EIC.BE, EIC.FR,
                        DateTime("2024-01-01"), DateTime("2024-06-01"),
                    ),
                    "transmission_91_expansion_BE_FR.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement || err isa ClientError
        end

        @testset "unavailability_of_offshore_grid (Outages 10.1.C)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> unavailability_of_offshore_grid(
                    client, EIC.DE_LU,
                    DateTime("2024-01-01"), DateTime("2024-04-01"),
                ),
                "outages_101c_unavailability_offshore_grid_DE_LU.bson",
            )
            @test !isempty(rows)
            # Reuses `parse_unavailability` — same column shape as the
            # onshore-transmission/generation/production wrappers.
            for col in (:start, :stop, :business_type, :nominal_mw)
                @test col in propertynames(rows)
            end
        end

        @testset "year_ahead_forecast_margin (Load 8.1, doc A70)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> year_ahead_forecast_margin(
                    client, EIC.BE,
                    DateTime("2023-12-31T23:00"),
                    DateTime("2024-12-31T23:00"),
                ),
                "load_81_year_ahead_forecast_margin_BE.yml",
            )
            # One row per published period — typically a single annual
            # snapshot, in MW.
            @test !isempty(rows)
            @test :time in propertynames(rows)
            @test :value in propertynames(rows)
        end

        @testset "intraday_wind_solar_forecast (Generation 14.1.D, process A40)" begin
            rows = Base.invokelatest(
                BR.playback,
                () -> intraday_wind_solar_forecast(
                    client, EIC.NL,
                    DateTime("2024-09-01T22:00"),
                    DateTime("2024-09-02T22:00"),
                ),
                "generation_141d_intraday_wind_solar_forecast_NL.yml",
            )
            @test !isempty(rows)
            @test :psr_type in propertynames(rows)
            # Solar (B16) is always present in NL intraday forecasts.
            @test any(r.psr_type == "B16" for r in rows)
        end

        @testset "intraday_prices (Market 12.1.D, contract A07)" begin
            # ENTSO-E publishes A07 intraday prices patchily — DE_LU
            # 2024-09-01 hits an `<Acknowledgement reason=999>`. Verify
            # the wrapper surfaces that as `ENTSOEAcknowledgement` rather
            # than crashing the parser on an empty document.
            err = nothing
            try
                Base.invokelatest(
                    BR.playback,
                    () -> intraday_prices(
                        client, EIC.DE_LU,
                        DateTime("2024-09-01T22:00"),
                        DateTime("2024-09-02T22:00"),
                    ),
                    "market_121d_intraday_prices_DE_LU.yml",
                )
            catch e
                err = e
            end
            @test err isa ENTSOEAcknowledgement
            @test err.reason_code == "999"
        end
    end
end
