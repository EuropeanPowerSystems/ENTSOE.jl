# ENTSOE.jl — end-to-end walkthrough.
#
# Hits every public surface of the package against the live Transparency
# Platform API. Each section prints a header and a small sample of what
# it received so you can scroll the output and read it like a tour.
#
# Token resolution: `ENV["ENTSOE_API_TOKEN"]` first, then `token.txt`
# at the repo root (gitignored — same fallback the test suite uses).

using ENTSOE
using Dates
using Statistics: extrema, mean

# ---------------------------------------------------------------------------
# Pretty-printing helpers — keep the script readable, the output scannable.

section(title) = (
    println();
    printstyled(
        "══ ", title, " ", "═"^max(2, 70 - length(title)), "\n";
        color = :cyan, bold = true
    )
)
subhead(label) = printstyled("  ▸ ", label, "\n"; color = :light_blue)
note(msg) = printstyled("    · ", msg, "\n"; color = :light_black)

# Cell formatting — DateTime as `yyyy-mm-dd HH:MM`, floats rounded to 2
# decimals, everything else stringified. Keeps tables narrow without
# pulling in DataFrames or PrettyTables as deps.
_cell(x::Dates.DateTime) = Dates.format(x, "yyyy-mm-dd HH:MM")
_cell(x::AbstractFloat) = string(round(x; digits = 2))
_cell(x) = string(x)

# Summarise an APIError in one line — never dump the raw body (a 503 from
# ENTSO-E during maintenance is a ~100KB HTML page nobody wants in their
# REPL). Falls back to typeof + a snippet for unknown error types.
function _summarise_err(err)
    err isa ENTSOE.RateLimitError && return "RateLimitError $(err.status) " *
        (rate_limit_message(err) === nothing ? "" : "— $(rate_limit_message(err))")
    err isa ENTSOE.ServerError && return "ServerError $(err.status) (body $(length(err.body)) chars; likely platform maintenance)"
    err isa ENTSOE.ClientError && return "ClientError $(err.status) — $(first(err.body, 120))"
    err isa ENTSOE.AuthError   && return "AuthError $(err.status) — $(err.message)"
    err isa ENTSOE.NetworkError && return "NetworkError ($(typeof(err.cause)))"
    err isa ENTSOE.TimeoutError && return "TimeoutError (phase = $(err.phase))"
    err isa ENTSOEAcknowledgement && return "Acknowledgement reason $(err.reason_code) — $(err.text)"
    return "$(typeof(err)): $(first(sprint(showerror, err), 200))"
end

# Run `f()` and either return the result or print a short notice and
# return `nothing`. Keeps the walkthrough flowing when ENTSO-E is down,
# rate-limiting, or returning an unexpected status — every demo call
# below routes through this.
#
# Argument order matches Julia's `do`-block convention: the closure
# (passed by the do-block) is the first positional argument, the label
# is second. Use as `try_call("label") do ... end`.
function try_call(f::Function, label::AbstractString)
    try
        return f()
    catch err
        err isa Union{ENTSOE.APIError, ENTSOEAcknowledgement} || rethrow()
        printstyled("    ⚠ $label → "; color = :yellow)
        println(_summarise_err(err))
        return nothing
    end
end

# Render the first `n` rows of any Tables.jl-compatible columnar source
# (StructVector, NamedTuple of vectors, …) as a small aligned table. Far
# more scannable than printing a Vector{NamedTuple} verbatim.
function preview(rows; n::Int = 3, label::AbstractString = "rows")
    cols = collect(propertynames(rows))
    isempty(cols) && (println("    (no columns to preview)"); return rows)
    head = collect(Iterators.take(rows, n))
    formatted = [[_cell(getproperty(r, c)) for c in cols] for r in head]
    headers = String.(cols)
    widths = [
        max(length(headers[i]), maximum(length(row[i]) for row in formatted; init = 0))
            for i in eachindex(cols)
    ]
    sep = "  "
    printstyled(
        "    first $n of $(length(rows)) $label:\n"; color = :light_black,
    )
    printstyled(
        "    " * join((rpad(headers[i], widths[i]) for i in eachindex(cols)), sep) * "\n";
        color = :light_black, bold = true,
    )
    printstyled(
        "    " * join(("─"^widths[i] for i in eachindex(cols)), sep) * "\n";
        color = :light_black,
    )
    for row in formatted
        println("    " * join((rpad(row[i], widths[i]) for i in eachindex(cols)), sep))
    end
    return rows
end

# ---------------------------------------------------------------------------
# Token resolution.

function resolve_token()
    tok = strip(get(ENV, "ENTSOE_API_TOKEN", ""))
    isempty(tok) || return String(tok)
    fallback = joinpath(@__DIR__, "..", "token.txt")
    isfile(fallback) || return ""
    return strip(read(fallback, String))
end

const TOKEN = resolve_token()
if isempty(TOKEN)
    println(
        """
        No token found. Set ENV["ENTSOE_API_TOKEN"] or drop a token.txt at
        the repo root (single line). Get one for free at
        https://transparency.entsoe.eu — register, then mail
        transparency@entsoe.eu requesting API access.
        """
    )
    exit(0)
end

# Standard analysis window — 2024-09-02 in CET (which is 2024-09-01 22:00
# UTC → 2024-09-02 22:00 UTC). One trading day; small enough to be cheap,
# large enough to show structure.
const T0 = DateTime("2024-09-01T22:00")
const T1 = DateTime("2024-09-02T22:00")

# ---------------------------------------------------------------------------
section("1. Client construction + token introspection")

subhead("is_uuid_token: catches typos before the network round-trip")
note("real UUID  → $(is_uuid_token("01234567-89ab-cdef-0123-456789abcdef"))")
note("typo       → $(is_uuid_token("not-a-uuid"))")
note(
    "the token we resolved (validate_token=true would " *
        (is_uuid_token(TOKEN) ? "accept" : "reject") * " it)"
)

subhead("ENTSOEClient — opt into validate_token=true for fail-fast on bad tokens")
const CLIENT = ENTSOEClient(TOKEN; validate_token = false)
note("client.base_url = $(CLIENT.base_url)")

subhead("ENTSOEConfig — module-level defaults (token, endpoint, validate_eic)")
ENTSOE.set_config(; token = TOKEN)
note("get_config().token is set: $(!isempty(ENTSOE.get_config().token))")

# ---------------------------------------------------------------------------
section("2. Time helpers — entsoe_period accepts everything sensible")

subhead("DateTime / Date / ZonedDateTime / Int → Int64 yyyymmddHHMM")
note("DateTime         → $(entsoe_period(DateTime("2024-09-01T22:00")))")
note("Date             → $(entsoe_period(Date("2024-09-02")))")
# ZonedDateTime works too — it's converted to UTC first.
using TimeZones: FixedTimeZone, ZonedDateTime
cet = FixedTimeZone("CET", 3600)
note("ZonedDateTime    → $(entsoe_period(ZonedDateTime(DateTime("2024-09-02T00:00"), cet)))")

# ---------------------------------------------------------------------------
section("3. EIC catalog — curated tuple, full registry, type filters")

subhead("EIC tuple — most-used 33 zones (Symbol-keyed NamedTuple)")
note("EIC.NL        = \"$(EIC.NL)\"")
note("EIC.DE_LU     = \"$(EIC.DE_LU)\"")
note("EIC.NO2       = \"$(EIC.NO2)\" (southern Norway)")

subhead("EIC_REGISTRY — every EIC mapped to (name, types)")
let nl = first(lookup_eic(EIC.NL))
    note("lookup_eic(EIC.NL).name  = \"$(nl.name)\"")
    note("lookup_eic(EIC.NL).types = $(nl.types)")
end
note("is_known_eic(\"10YNL----------L\") = $(is_known_eic("10YNL----------L"))")
note("is_known_eic(\"10YNOT-A-CODE---\") = $(is_known_eic("10YNOT-A-CODE---"))")

subhead("eics_of_type — filter by entity tag")
bzns = eics_of_type(:BZN)
note("$(length(bzns)) bidding zones (:BZN) total")

subhead("validate_eic — opt-in precondition for the wrappers")
note("validate_eic(EIC.NL; type=:BZN) → $(validate_eic(EIC.NL; type = :BZN))")
try
    validate_eic("10YNOT-A-CODE---"; type = :BZN)
catch err
    note("unknown EIC → $(typeof(err)): $(err.msg)")
end

# ---------------------------------------------------------------------------
section("4. Code lists — semantic constants + description labels")

subhead("Semantic-name → code (pass these directly into wrappers)")
note("PsrType.SOLAR             = \"$(PsrType.SOLAR)\"")
note("PsrType.WIND_ONSHORE      = \"$(PsrType.WIND_ONSHORE)\"")
note("BusinessType.PLANNED_OUTAGE = \"$(BusinessType.PLANNED_OUTAGE)\"")
note("ProcessType.REALISED      = \"$(ProcessType.REALISED)\"")
note("DocumentType.PRICE        = \"$(DocumentType.PRICE)\"")

subhead("Subset tuples — PsrGroup (for client-side filtering after fetch)")
note("PsrGroup.HYDRO   = $(PsrGroup.HYDRO)")
note("PsrGroup.WIND    = $(PsrGroup.WIND)")
note("PsrGroup.FOSSIL  = $(PsrGroup.FOSSIL)")

subhead("Code → description NamedTuples (for plot legends / pretty-printing)")
note("DOCUMENT_LABELS.A44 = \"$(DOCUMENT_LABELS.A44)\"")
note("PROCESS_LABELS.A16  = \"$(PROCESS_LABELS.A16)\"")
note("BUSINESS_LABELS.A33 = \"$(BUSINESS_LABELS.A33)\"")
note("PSR_LABELS.B19      = \"$(PSR_LABELS.B19)\"")

subhead("describe / code_for — case-insensitive substring search")
note("describe(PSR_LABELS, \"B16\") = \"$(ENTSOE.describe(PSR_LABELS, "B16"))\"")
note("code_for(PSR_LABELS, \"wind onshore\") = \"$(ENTSOE.code_for(PSR_LABELS, "wind onshore"))\"")
note(
    "code_for(DOCUMENT_LABELS, \"price document\") = " *
        "\"$(ENTSOE.code_for(DOCUMENT_LABELS, "price document"))\"  " *
        "(plain \"price\" would be ambiguous → A44/A84/A85/A89)"
)

# ---------------------------------------------------------------------------
section("5. Market — day-ahead prices (Parsed default + Raw escape hatch)")

subhead("day_ahead_prices(client, area, start, stop) — default Parsed()")
prices = try_call("day_ahead_prices(NL, 2024-09-02)") do
    day_ahead_prices(CLIENT, EIC.NL, T0, T1)
end
if prices !== nothing
    preview(prices; label = "price points")
    lo, hi = extrema(prices.value)
    note(
        "mean $(round(mean(prices.value); digits = 2)) EUR/MWh  " *
            "(min $(round(lo; digits = 2)), max $(round(hi; digits = 2)))"
    )
end

subhead("Same call with Raw() — type-stable String output")
xml = try_call("day_ahead_prices(NL, Raw())") do
    day_ahead_prices(CLIENT, EIC.NL, T0, T1, Raw())
end
if xml !== nothing
    note("typeof(xml) = $(typeof(xml)), length = $(length(xml)) chars")
    note("first tag in body: $(match(r"<\w+", xml).match)")
end

# ---------------------------------------------------------------------------
section("6. Load — actual + day-ahead forecast (Load 6.1.A & 6.1.B)")

subhead("actual_total_load — quarter-hour resolution (96 points / day)")
load = try_call("actual_total_load(NL)") do
    actual_total_load(CLIENT, EIC.NL, T0, T1)
end
if load !== nothing
    preview(load; label = "load points")
    note("peak NL load this day: $(round(Int, maximum(load.value))) MW")
end

subhead("day_ahead_load_forecast — same shape, processType=A01")
forecast = try_call("day_ahead_load_forecast(NL)") do
    day_ahead_load_forecast(CLIENT, EIC.NL, T0, T1)
end
forecast === nothing || note(
    "$(length(forecast)) forecast points, " *
        "mean $(round(Int, mean(forecast.value))) MW"
)

# Demonstrating the family without spamming every variant:
note("(week/month/year_ahead_load_forecast exist with identical signatures)")

# ---------------------------------------------------------------------------
section("7. Generation — installed capacity + actual per-PSR (16.1.B/C, 14.1.A)")

subhead("installed_capacity_per_production_type — year-ahead window")
caps = try_call("installed_capacity_per_production_type(NL, 2024)") do
    installed_capacity_per_production_type(
        CLIENT, EIC.NL,
        DateTime("2023-12-31T23:00"), DateTime("2024-12-31T23:00"),
    )
end
if caps !== nothing
    preview(caps; label = "capacity rows")
    note(
        "$(length(caps)) PSR types, total " *
            "$(round(Int, sum(caps.capacity_mw))) MW"
    )
    big_i = argmax(caps.capacity_mw)
    note(
        "largest: $(round(Int, caps.capacity_mw[big_i])) MW " *
            "(\"$(ENTSOE.describe(PSR_LABELS, caps.psr_type[big_i]))\")"
    )
end

subhead("actual_generation_per_production_type — per-PSR time series")
gen = try_call("actual_generation_per_production_type(NL)") do
    actual_generation_per_production_type(CLIENT, EIC.NL, T0, T1)
end
if gen !== nothing
    preview(gen; label = "generation rows")
    let psrs = unique(gen.psr_type)
        note("$(length(gen)) rows across $(length(psrs)) production types:")
        for code in psrs
            rows = filter(r -> r.psr_type == code, gen)
            mean_mw = round(Int, mean(r.value for r in rows))
            note(
                "    $code  $(rpad(ENTSOE.describe(PSR_LABELS, code), 35))" *
                    "  mean $(lpad(mean_mw, 6)) MW"
            )
        end
    end
end

# Server-side filter to one technology.
subhead("Server-side filter: psr_type = PsrType.SOLAR (B16)")
solar = try_call("actual_generation_per_production_type(NL, psr=SOLAR)") do
    actual_generation_per_production_type(CLIENT, EIC.NL, T0, T1; psr_type = PsrType.SOLAR)
end
solar === nothing || note(
    "$(length(solar)) solar points, " *
        "peak $(round(Int, maximum(solar.value))) MW"
)

subhead("wind_solar_forecast — per-PSR forecast document")
wsf = try_call("wind_solar_forecast(NL)") do
    wind_solar_forecast(CLIENT, EIC.NL, T0, T1)
end
if wsf !== nothing
    let techs = unique(wsf.psr_type)
        note("$(length(wsf)) forecast rows across $(length(techs)) technologies:")
        for code in techs
            note("    $code  $(ENTSOE.describe(PSR_LABELS, code))")
        end
    end
end

# ---------------------------------------------------------------------------
section("8. Transmission — cross-border flows + schedules + capacities")

subhead("cross_border_physical_flows: DE_LU → NL (positive = imports into NL)")
flow = try_call("cross_border_physical_flows(NL←DE_LU)") do
    cross_border_physical_flows(CLIENT, EIC.NL, EIC.DE_LU, T0, T1)
end
if flow !== nothing
    preview(flow; label = "flow points")
    note(
        "mean $(round(Int, mean(flow.value))) MW, " *
            "max import $(round(Int, maximum(flow.value))) MW"
    )
end

subhead("commercial_schedules: same direction, scheduled vs physical")
sched = try_call("commercial_schedules(NL←DE_LU)") do
    commercial_schedules(CLIENT, EIC.NL, EIC.DE_LU, T0, T1)
end
sched === nothing || note(
    "$(length(sched)) scheduled points, " *
        "mean $(round(Int, mean(sched.value))) MW"
)

subhead("commercial_schedules_net_positions: per-zone net schedule")
nets = try_call("commercial_schedules_net_positions(NL)") do
    commercial_schedules_net_positions(CLIENT, EIC.NL, T0, T1)
end
nets === nothing || note("$(length(nets)) NL net-position points")

subhead("forecasted_transfer_capacities: A61 NTC, daily (A01)")
ntc = try_call("forecasted_transfer_capacities(NL←DE_LU)") do
    forecasted_transfer_capacities(CLIENT, EIC.NL, EIC.DE_LU, T0, T1)
end
ntc === nothing || note(
    "$(length(ntc)) NTC forecast points, " *
        "mean $(round(Int, mean(ntc.value))) MW"
)

# ---------------------------------------------------------------------------
section("9. ENTSOEAcknowledgement — deliberately empty query")

subhead("day_ahead_prices for 1999/GR → reason 999 (no data) is a typed exception")
try
    day_ahead_prices(
        CLIENT, EIC.GR,
        DateTime("1999-01-01"), DateTime("1999-01-02"),
    )
catch err
    err isa ENTSOEAcknowledgement || rethrow()
    note("typed exception : $(typeof(err))")
    note("reason_code     : $(err.reason_code)")
    note("text            : $(err.text)")
end

# ---------------------------------------------------------------------------
section("10. Automatic window splitting — multi-year request in one call")

subhead("3-year NL day-ahead prices (splits into yearly windows internally)")
long = try_call("day_ahead_prices(NL, 2022→2025)") do
    day_ahead_prices(
        CLIENT, EIC.NL,
        DateTime("2022-01-01"), DateTime("2025-01-01"),
    )
end
if long !== nothing
    note("$(length(long)) total price points across the three windows")
    note("first day mean = $(round(mean(long.value[1:min(96, end)]); digits = 2)) EUR/MWh")
    note("(the wrapper splits internally and skips per-chunk ENTSOEAcknowledgements)")
end

# ---------------------------------------------------------------------------
section("11. Reliability stack — with_defaults composes retry/rate-limit/timeout")

subhead("Compose all three around any call")
result = try_call("with_defaults(day_ahead_prices NL)") do
    with_defaults(;
        retry = RetryPolicy(; max_attempts = 3, base_delay = 0.5),
        rate_limit = TokenBucket(; rate = 5.0, burst = 5.0),
        timeout = 30.0,
    ) do
        day_ahead_prices(CLIENT, EIC.NL, T0, T1)
    end
end
result === nothing || note(
    "under middleware: $(length(result)) rows back, " *
        "mean $(round(mean(result.value); digits = 2)) EUR/MWh"
)
note("(retry honours Retry-After; bucket rate-limits at 5 req/s; 30s total cap)")

# ---------------------------------------------------------------------------
section("12. Error types — typed APIError hierarchy")

subhead("check_response maps HTTP status → typed exception")
note("AuthError      ← 401/403   (.status, .message)")
note("RateLimitError ← 408/429   (.retry_after, .body, rate_limit_message())")
note("ClientError    ← other 4xx (.status, .body)")
note("ServerError    ← 5xx       (.status, .body)")
note("TimeoutError   ← timeout   (.phase ∈ :connect/:read/:total)")
note("NetworkError   ← transport (.cause)")

subhead("rate_limit_message: pull the human-readable text out of ENTSO-E's HTML 429")
sample_body = """
<!DOCTYPE html><html><body>
<h1>Too Many Requests</h1>
<p>Your request has exceeded the API throttling limit
   of 380 requests per minute.</p>
</body></html>
"""
synthetic = RateLimitError(; status = 429, retry_after = 60.0, body = sample_body)
note("rate_limit_message() = \"$(rate_limit_message(synthetic))\"")
note("showerror():")
println("    " * sprint(showerror, synthetic))

# ---------------------------------------------------------------------------
section("13. OMI — paginated wrapper over the Other Market Information endpoint")

subhead("omi_other_market_information with B47 — usually returns an Ack for NL")
pages = try_call("omi_other_market_information(NL, B47)") do
    omi_other_market_information(
        CLIENT, EIC.NL,
        DateTime("2024-09-23T22:00"), DateTime("2024-09-24T22:00");
        document_type = DocumentType.OTHER_MARKET_INFORMATION,
        page_size = 200, max_pages = 1,
    )
end
pages === nothing || note(
    "$(length(pages)) page(s), " *
        "first XML body $(length(first(pages))) chars"
)

# ---------------------------------------------------------------------------
section("14. Hydro state, balancing, and congestion management")

subhead("water_reservoirs_and_hydro_storage_plants — weekly MWh stored (Gen 16.1.D)")
hydro = try_call("water_reservoirs(AT)") do
    water_reservoirs_and_hydro_storage_plants(
        CLIENT, EIC.AT,
        DateTime("2024-09-01T22:00"), DateTime("2024-09-08T22:00"),
    )
end
if hydro !== nothing && !isempty(hydro.value)
    preview(hydro; label = "hydro reading(s)")
    note("most recent reading: $(round(Int, last(hydro.value))) MWh stored")
end

subhead("current_balancing_state — area control error per imbalance window")
acer = try_call("current_balancing_state(HU)") do
    current_balancing_state(
        CLIENT, EIC.HU,
        DateTime("2024-05-29T22:00"), DateTime("2024-05-30T22:00"),
    )
end
if acer !== nothing && !isempty(acer.value)
    preview(acer; label = "balancing-state samples")
    note(
        "$(length(acer)) samples in window; " *
            "|imbalance| max = $(round(Int, maximum(abs, acer.value))) MW"
    )
end

subhead("aggregated_balancing_energy_bids — aFRR bid volumes (process A51)")
bids = try_call("aggregated_balancing_energy_bids(AT)") do
    aggregated_balancing_energy_bids(
        CLIENT, EIC.AT,
        DateTime("2023-09-02T22:00"), DateTime("2023-09-03T22:00"),
    )
end
if bids !== nothing && !isempty(bids.value)
    preview(bids; label = "bid prices")
    note(
        "$(length(bids)) priced bid steps; " *
            "median $(round(mean(bids.value); digits = 2))"
    )
end

subhead("redispatching_internal — within-zone congestion relief (Transmission 13.1.A)")
rdi = try_call("redispatching_internal(NL)") do
    redispatching_internal(
        CLIENT, EIC.NL,
        DateTime("2023-10-31T23:00"), DateTime("2023-11-30T23:00"),
    )
end
if rdi !== nothing && !isempty(rdi.value)
    preview(rdi; label = "redispatch events")
    note(
        "$(length(rdi)) intervals, total " *
            "$(round(Int, sum(rdi.value))) MWh of redispatch"
    )
end

subhead("redispatching_cross_border — between-zone congestion relief")
rdx = try_call("redispatching_cross_border(FR←AT)") do
    redispatching_cross_border(
        CLIENT, EIC.FR, EIC.AT,
        DateTime("2023-11-01T00:00"), DateTime("2023-12-01T00:00"),
    )
end
rdx === nothing || (
    isempty(rdx.value) ? note("no cross-border redispatch in window") :
        note("$(length(rdx)) intervals, max $(round(Int, maximum(rdx.value))) MW")
)

subhead("countertrading — energy traded between zones to relieve congestion")
ct = try_call("countertrading(FR←ES)") do
    countertrading(
        CLIENT, EIC.FR, EIC.ES,
        DateTime("2023-09-12T22:00"), DateTime("2023-09-13T22:00"),
    )
end
ct === nothing || (
    isempty(ct.value) ? note("no countertrading in window") :
        note("$(length(ct)) intervals, total $(round(Int, sum(ct.value))) MWh countertraded")
)

subhead("costs_of_congestion_management — TSO redispatch + countertrade costs")
costs = try_call("costs_of_congestion_management(BE 2022)") do
    costs_of_congestion_management(
        CLIENT, EIC.BE,
        DateTime("2021-12-31T23:00"), DateTime("2022-12-31T23:00"),
    )
end
if costs !== nothing && !isempty(costs.value)
    preview(costs; label = "monthly cost samples")
    note(
        "$(length(costs)) intervals, total " *
            "$(round(Int, sum(costs.value))) (currency varies by TSO)"
    )
end

# ---------------------------------------------------------------------------
section("15. Outages — unavailability notices across all four resource families")

# All four use parse_unavailability under the hood — one row per outage
# event with start/stop, business_type, resource_name, psr_type,
# nominal_mw. The Postman defaults are picked precisely (specific
# resources, narrow update windows), so most calls hit Acknowledgements
# in the smoke cassettes; live traffic gets data far more often.

subhead("unavailability_of_generation_units — per-unit notices (Outages 15.1.A/B)")
gen_outages = try_call("unavailability_of_generation_units(BE)") do
    unavailability_of_generation_units(
        CLIENT, EIC.BE,
        DateTime("2024-01-01T00:00"), DateTime("2024-02-01T00:00");
        business_type = BusinessType.PLANNED_OUTAGE,
    )
end
if gen_outages !== nothing && !isempty(gen_outages.resource_name)
    preview(gen_outages; label = "outage notices", n = 2)
    rated = filter(!isnan, gen_outages.nominal_mw)
    note(
        "$(length(gen_outages)) planned outages in BE during Jan 2024" *
            (
            isempty(rated) ? "" :
                "; biggest unit: $(round(Int, maximum(rated))) MW rated"
        )
    )
end

subhead("unavailability_of_production_units — per-station outages (15.1.C/D)")
prod_outages = try_call("unavailability_of_production_units(BE)") do
    unavailability_of_production_units(
        CLIENT, EIC.BE,
        DateTime("2024-01-01T00:00"), DateTime("2024-02-01T00:00");
        business_type = BusinessType.PLANNED_OUTAGE,
    )
end
prod_outages === nothing || note("$(length(prod_outages)) planned production-unit outages")

subhead("unavailability_of_transmission_infrastructure — cross-border lines (10.1.A/B)")
tx_outages = try_call("unavailability_of_transmission_infrastructure(FR←BE)") do
    unavailability_of_transmission_infrastructure(
        CLIENT, EIC.FR, EIC.BE,
        DateTime("2023-12-01T23:00"), DateTime("2023-12-02T23:00"),
    )
end
tx_outages === nothing || note("$(length(tx_outages)) transmission outages on the FR↔BE border")

subhead("aggregated_unavailability_of_consumption_units (7.1.A/B)")
cons_outages = try_call("aggregated_unavailability_of_consumption_units(DE_LU)") do
    aggregated_unavailability_of_consumption_units(
        CLIENT, EIC.DE_LU,
        DateTime("2023-10-31T23:00"), DateTime("2023-11-30T23:00"),
    )
end
if cons_outages !== nothing && !isempty(cons_outages.business_type)
    note("$(length(cons_outages)) aggregated consumption-side notices for DE_LU in Nov 2023")
end

# ---------------------------------------------------------------------------
section("16. Master data — production + generation unit registry")

subhead("production_and_generation_units(BE, PRODUCTION_UNIT, Fossil Gas)")
units = try_call("production_and_generation_units(BE)") do
    production_and_generation_units(
        CLIENT, EIC.BE;
        implementation_date = Date(2017, 1, 1),
        business_type = BusinessType.PRODUCTION_UNIT,
        psr_type = PsrType.FOSSIL_GAS,
    )
end
if units !== nothing && !isempty(units.production_unit_mrid)
    preview(units; label = "generating units", n = 3)
    n_prod = length(unique(units.production_unit_mrid))
    n_gen = length(units)
    note(
        "$n_prod production unit(s) decomposed into $n_gen generating unit(s); " *
            "total $(round(Int, sum(units.nominal_mw))) MW rated"
    )
    biggest = argmax(units.nominal_mw)
    note(
        "largest: $(units.generating_unit_name[biggest]) — " *
            "$(round(Int, units.nominal_mw[biggest])) MW"
    )
end

# ---------------------------------------------------------------------------
section("17. Zipped balancing endpoints — unzipped transparently")

# These three endpoints serve `application/zip`. The wrappers detect the
# ZIP magic bytes, extract every XML member, and route each through
# `parse_timeseries` — concatenating the results.

subhead("imbalance_prices — clearing prices per imbalance window (17.1.G)")
imbal_p = try_call("imbalance_prices(AT, 2024-01)") do
    imbalance_prices(
        CLIENT, EIC.AT,
        DateTime("2024-01-01T00:00"), DateTime("2024-01-02T00:00");
        psr_type = PsrType.GENERATION,
    )
end
if imbal_p !== nothing && !isempty(imbal_p.value)
    preview(imbal_p; label = "imbalance price samples")
    note("$(length(imbal_p)) prices, mean $(round(mean(imbal_p.value); digits = 2)) EUR/MWh")
end

subhead("total_imbalance_volumes — system imbalance per window (17.1.H)")
imbal_v = try_call("total_imbalance_volumes(AT)") do
    total_imbalance_volumes(
        CLIENT, EIC.AT,
        DateTime("2023-11-03T23:00"), DateTime("2023-11-04T23:00"),
    )
end
if imbal_v !== nothing && !isempty(imbal_v.value)
    preview(imbal_v; label = "imbalance volume samples")
    note("$(length(imbal_v)) intervals, |max| = $(round(Int, maximum(abs, imbal_v.value))) MW")
end

subhead("procured_balancing_capacity — reserve auction results (1.2.3.F)")
proc = try_call("procured_balancing_capacity(DE)") do
    procured_balancing_capacity(
        CLIENT, "10YDE-VE-------2",   # 50Hertz CA — not in EIC tuple
        DateTime("2023-06-15T00:00"), DateTime("2023-06-15T01:00");
        process_type = ProcessType.AFRR,
        type_market_agreement_type = ContractType.DAILY,
        offset = 0,
    )
end
proc === nothing || (
    isempty(proc.value) ?
        note("no procured capacity in window") :
        note("$(length(proc)) reserved bid points, mean $(round(Int, mean(proc.value))) MW")
)

# ---------------------------------------------------------------------------
section("Done. Every public surface exercised.")

printstyled(
    """
    To explore further:
      - ?day_ahead_prices    docstrings cover the full parameter shape
      - using DataFrames; DataFrame(prices)   — Tables.jl interop is automatic
      - using Plots; plot(prices.time, prices.value)
      - test/test-queries.jl, test/test-cassettes.jl — offline replay patterns
    """; color = :light_black
)
