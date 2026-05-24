# ENTSO-E specific helpers layered on top of the generated API client and the
# template-provided `Client` overlay. Lives outside `src/api/` so it survives
# `gen/regenerate.jl` runs unchanged.

include("period.jl")
include("eic.jl")
include("codes.jl")
include("parsing.jl")
include("client.jl")
include("config.jl")
include("queries.jl")
include("splitting.jl")

export entsoe_period, EIC, ENTSOEClient, entsoe_apis, ENTSOE_BASE_URL, is_uuid_token
export DOCUMENT_TYPE, PROCESS_TYPE, BUSINESS_TYPE, PSR_TYPE, code_for
export parse_timeseries, parse_timeseries_per_psr, parse_installed_capacity,
    parse_unavailability, parse_unavailability_curve, parse_master_data
export parse_acknowledgement, check_acknowledgement, ENTSOEAcknowledgement
export unzip_response
export EIC_REGISTRY, lookup_eic, is_known_eic, eics_of_type, validate_eic
export day_ahead_prices,
    intraday_prices,
    total_nominated_capacity,
    congestion_income,
    implicit_auction_net_positions,
    actual_total_load,
    day_ahead_load_forecast, week_ahead_load_forecast,
    month_ahead_load_forecast, year_ahead_load_forecast,
    year_ahead_forecast_margin,
    installed_capacity_per_production_type,
    generation_forecast_day_ahead,
    wind_solar_forecast,
    intraday_wind_solar_forecast,
    actual_generation_per_production_type,
    water_reservoirs_and_hydro_storage_plants,
    cross_border_physical_flows,
    commercial_schedules,
    scheduled_exchanges,
    commercial_schedules_net_positions,
    forecasted_transfer_capacities,
    net_transfer_capacity_day_ahead,
    net_transfer_capacity_week_ahead,
    net_transfer_capacity_month_ahead,
    net_transfer_capacity_year_ahead,
    redispatching_internal,
    redispatching_cross_border,
    countertrading,
    costs_of_congestion_management,
    expansion_and_dismantling_project,
    unavailability_of_generation_units,
    unavailability_of_production_units,
    unavailability_of_transmission_infrastructure,
    unavailability_of_offshore_grid,
    outages_fall_backs,
    aggregated_unavailability_of_consumption_units,
    production_and_generation_units,
    current_balancing_state,
    aggregated_balancing_energy_bids,
    results_of_criteria_application_process,
    fcr_total_capacity,
    shares_of_fcr_capacity,
    frr_rr_capacity_outlook,
    frr_and_rr_actual_capacity,
    outlook_of_reserve_capacities_on_rr,
    rr_actual_capacity,
    sharing_of_rr_and_frr,
    sharing_of_fcr_between_sas,
    exchanged_reserve_capacity,
    financial_expenses_and_income_for_balancing,
    prices_of_activated_balancing_energy,
    imbalance_prices,
    total_imbalance_volumes,
    procured_balancing_capacity
# `omi_other_market_information` is already exported by the codegen layer
# (`ENTSOEAPI`); our paginated method is just a new dispatch on the same
# name (`(::Client, …)` instead of `(::OMIApi, …)`), so no extra export.
export split_period, query_split
export ENTSOEConfig, set_config, get_config
