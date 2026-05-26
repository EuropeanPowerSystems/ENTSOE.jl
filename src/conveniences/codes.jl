# ENTSO-E "code list" reference tables.
#
# Every Transparency Platform query takes one or more codes —
# `documentType=A44`, `processType=A16`, `businessType=B33`, `psrType=B19`,
# etc. — drawn from a fixed enumeration published in the IEC 62325
# standard. The generated wrapper takes them as raw `String`s.
#
# This file exposes the codes in two complementary shapes:
#
#   - **Semantic-name → code lookups** (`PsrType.SOLAR == "B16"`,
#     `BusinessType.PLANNED_OUTAGE == "A53"`, …). Pass these directly
#     to named wrappers — the underlying `String()` conversion in the
#     wrapper bodies makes them indistinguishable from raw code strings.
#
#   - **Code → description lookups** (`PSR_LABELS.B16 == "Solar"`).
#     These are NamedTuples keyed by the canonical code symbol, used
#     for pretty-printing, plot legends, and `code_for(..., "wind onshore")`
#     reverse lookup.
#
# A third shape, **code groups**, lives in `PsrGroup`: subset tuples
# like `PsrGroup.HYDRO == ("B10", "B11", "B12")` for filtering result
# tables client-side (e.g. `caps[in.(caps.psr_type, Ref(PsrGroup.HYDRO))]`).

# ---------------------------------------------------------------------------
# Generic CodeTable struct — `EICTable`-style wrapper, shared by
# `PsrType`, `BusinessType`, … below.

"""
    CodeTable

Lookup wrapper around a curated ENTSO-E code list. Owned by ENTSOE.jl
so the `(::CodeTable)(name)` call method isn't piracy on `Base.NamedTuple`.

Supports the same surface as a NamedTuple:

  - Field access — `PsrType.SOLAR`
  - Callable lookup — `PsrType("SOLAR")` (case-insensitive name) or
    `PsrType("B16")` (raw-code pass-through, validated)
  - Iteration over values — `for v in PsrType; ...; end`
  - `propertynames(PsrType)`, `keys`, `values`, `pairs`, `haskey`, `length`

The first field of each constant is the table name (for error
messages); the second is the underlying `NamedTuple` of entries.
"""
struct CodeTable{NT <: NamedTuple}
    name::String
    entries::NT
end

# Forward NamedTuple-like introspection. Use `getfield` on the struct
# directly so `getproperty(t, :SOLAR)` reaches into `.entries` rather
# than recursing into itself.
Base.getproperty(t::CodeTable, sym::Symbol) =
    getproperty(getfield(t, :entries), sym)
Base.propertynames(t::CodeTable, private::Bool = false) =
    propertynames(getfield(t, :entries), private)
Base.haskey(t::CodeTable, sym::Symbol) = haskey(getfield(t, :entries), sym)
Base.keys(t::CodeTable) = keys(getfield(t, :entries))
Base.values(t::CodeTable) = values(getfield(t, :entries))
Base.pairs(t::CodeTable) = pairs(getfield(t, :entries))
Base.length(t::CodeTable) = length(getfield(t, :entries))
Base.iterate(t::CodeTable, st...) = iterate(getfield(t, :entries), st...)
Base.show(io::IO, t::CodeTable) =
    print(io, getfield(t, :name), "(", getfield(t, :entries), ")")

# Callable form: case-insensitive name lookup, with pass-through for
# raw codes already present as values. Tuples (subset groups) are
# returned as-is when their name matches; pass-through ignores them.
function (t::CodeTable)(key::AbstractString)
    s = String(key)
    sym = Symbol(uppercase(s))
    haskey(t, sym) && return getproperty(t, sym)
    for v in values(t)
        v isa AbstractString && v == s && return v
    end
    throw(
        ArgumentError(
            "Unknown $(getfield(t, :name)) key or code: $(repr(s)). " *
                "Use one of `propertynames($(getfield(t, :name)))` " *
                "or pass a known code string."
        ),
    )
end

# ---------------------------------------------------------------------------
# Code → description tables (the historical `*_TYPE` constants, renamed
# to `*_LABELS` so the unsuffixed names are free for the semantic-name
# tables below).

"""
    DOCUMENT_LABELS

Canonical ENTSO-E `documentType` code → description NamedTuple, keyed
by the IEC code symbol (e.g. `:A44`). Used for human-readable output
and `code_for(DOCUMENT_LABELS, "price document")` reverse lookup.

For passing a documentType *into* a query, prefer the semantic
[`DocumentType`](@ref) constant (`DocumentType.PRICE == "A44"`).

```jldoctest
julia> DOCUMENT_LABELS.A44
"Price document"
```
"""
const DOCUMENT_LABELS = (
    A09 = "Finalised schedule",
    A11 = "Aggregated energy data report",
    A15 = "Acquiring system operator reserve schedule",
    A24 = "Bid document",
    A25 = "Allocation result document",
    A26 = "Capacity document",
    A31 = "Agreed capacity",
    A36 = "Capacity allocation considering reliability margin",
    A37 = "Reliability margin",
    A38 = "Reserve allocation result document",
    A44 = "Price document",
    A60 = "MOL capacity allocation",
    A61 = "MOL document",
    A62 = "Bid availability document",
    A63 = "Reserve plan",
    A64 = "Acquiring system operator reserve schedule",
    A65 = "System total load",
    A68 = "Installed generation per type",
    A69 = "Wind and solar forecast",
    A70 = "Load forecast margin",
    A71 = "Generation forecast",
    A72 = "Reservoir filling information",
    A73 = "Actual generation",
    A74 = "Wind and solar generation",
    A75 = "Actual generation per type",
    A76 = "Load unavailability",
    A77 = "Production unavailability",
    A78 = "Transmission unavailability",
    A79 = "Offshore grid infrastructure unavailability",
    A80 = "Generation unavailability",
    A81 = "Contracted reserves",
    A82 = "Accepted offers",
    A83 = "Activated balancing quantities",
    A84 = "Activated balancing prices",
    A85 = "Imbalance prices",
    A86 = "Imbalance volume",
    A87 = "Financial situation",
    A88 = "Cross border balancing",
    A89 = "Contracted reserve prices",
    A90 = "Interconnection network expansion",
    A91 = "Counter trade notice",
    A92 = "Congestion costs",
    A93 = "DC link capacity",
    A94 = "Non EU allocations",
    A95 = "Configuration document",
    A96 = "Settlement document",
    A97 = "Capacity available for non market activities",
    B11 = "Production unit",
)

"""
    PROCESS_LABELS

Canonical ENTSO-E `processType` code → description NamedTuple.
Use [`ProcessType`](@ref) (`ProcessType.REALISED == "A16"`) when
passing a processType into a query.

```jldoctest
julia> PROCESS_LABELS.A16
"Realised"
```
"""
const PROCESS_LABELS = (
    A01 = "Day ahead",
    A02 = "Intra day incremental",
    A16 = "Realised",
    A18 = "Intraday total",
    A31 = "Week ahead",
    A32 = "Month ahead",
    A33 = "Year ahead",
    A39 = "Synchronisation process",
    A40 = "Intraday process",
    A46 = "Replacement reserve",
    A47 = "Manual frequency restoration reserve",
    A51 = "Automatic frequency restoration reserve",
    A52 = "Frequency containment reserve",
    A56 = "Frequency restoration reserve",
)

"""
    BUSINESS_LABELS

Canonical ENTSO-E `businessType` code → description NamedTuple — the
most heavily overloaded code list in the standard. These describe the
*purpose* of a document or TimeSeries (energy, capacity, reserve,
balancing, redispatch …).

Use [`BusinessType`](@ref) (`BusinessType.PLANNED_OUTAGE == "A53"`)
when passing a businessType into a query.

```jldoctest
julia> BUSINESS_LABELS.A33
"Outage"
```
"""
const BUSINESS_LABELS = (
    A01 = "Production",
    A02 = "Internal trade",
    A03 = "External trade explicit allocation",
    A04 = "Consumption",
    A05 = "External trade total",
    A06 = "Resulting imbalance",
    A07 = "Inadvertent energy",
    A25 = "General Capacity Information",
    A29 = "Already allocated capacity (AAC)",
    A33 = "Outage",
    A37 = "Installed generation",
    A38 = "Available margin",
    A39 = "Generation forecast",
    A43 = "Requested capacity (without price)",
    A44 = "Compensation for absolute decrease",
    A45 = "Compensation for relative decrease",
    A46 = "System operator redispatching",
    A48 = "Cross-border redispatching",
    A52 = "Common reserve allocation",
    A53 = "Planned maintenance",
    A54 = "Unplanned outage",
    A55 = "Other operative information",
    A56 = "Frequency containment reserve",
    A60 = "Min margin",
    A61 = "Max margin",
    A62 = "Spot price",
    A63 = "Minimum possible",
    A64 = "Maximum possible",
    A66 = "Power system resource type",
    A85 = "Internal redispatch",
    A95 = "FCR contracted",
    A96 = "Automatic frequency restoration reserve",
    A97 = "Manual frequency restoration reserve",
    A98 = "Replacement reserve",
    B01 = "Activation",
    B02 = "Capacity",
    B03 = "Auction revenue",
    B04 = "Cost",
    B05 = "Counter trade",
    B07 = "Volume contracted",
    B08 = "Reliability margin",
    B09 = "Specific information not necessarily defined elsewhere",
    B10 = "Congestion income",
    B11 = "Production unit",
    B33 = "Area Control Error",
    B95 = "Procured capacity",
)

"""
    PSR_LABELS

Canonical ENTSO-E `psrType` code → description NamedTuple — the
production / consumption / infrastructure type taxonomy used by the
generation, capacity, and balancing endpoints.

Use [`PsrType`](@ref) (`PsrType.SOLAR == "B16"`) when passing a
psrType into a query, and [`PsrGroup`](@ref) for subset filters
(`PsrGroup.HYDRO == ("B10", "B11", "B12")`).

```jldoctest
julia> PSR_LABELS.B16
"Solar"
```
"""
const PSR_LABELS = (
    A03 = "Mixed",
    A04 = "Generation",
    A05 = "Load",
    B01 = "Biomass",
    B02 = "Fossil Brown coal/Lignite",
    B03 = "Fossil Coal-derived gas",
    B04 = "Fossil Gas",
    B05 = "Fossil Hard coal",
    B06 = "Fossil Oil",
    B07 = "Fossil Oil shale",
    B08 = "Fossil Peat",
    B09 = "Geothermal",
    B10 = "Hydro Pumped Storage",
    B11 = "Hydro Run-of-river and poundage",
    B12 = "Hydro Water Reservoir",
    B13 = "Marine",
    B14 = "Nuclear",
    B15 = "Other renewable",
    B16 = "Solar",
    B17 = "Waste",
    B18 = "Wind Offshore",
    B19 = "Wind Onshore",
    B20 = "Other",
    B21 = "AC Link",
    B22 = "DC Link",
    B23 = "Substation",
    B24 = "Transformer",
    B25 = "Battery storage",
)

# ---------------------------------------------------------------------------
# Semantic-name → code tables. These are what callers pass to wrappers.
# Values are plain `String`s, so the wrappers' `String()` conversion
# carries them through unchanged.

"""
    PsrType

ENTSO-E `psrType` codes (production / consumption / infrastructure
taxonomy) keyed by semantic name. Each value is a `String` holding
the IEC code:

```jldoctest
julia> PsrType.SOLAR
"B16"

julia> PsrType.WIND_ONSHORE
"B19"
```

Pass directly to any wrapper that accepts `psr_type`:

```julia
wind_solar_forecast(client, EIC.NL, t1, t2; psr_type = PsrType.SOLAR)
```

For filtering result tables *after* a fetch, use [`PsrGroup`](@ref)
subset tuples instead — `PsrGroup.HYDRO` returns `("B10", "B11", "B12")`,
which works with `in.(rows.psr_type, Ref(...))`.

See [`PSR_LABELS`](@ref) for code → description lookup.
"""
const PsrType = CodeTable(
    "PsrType",
    (
        # Aggregations
        MIXED = "A03",
        GENERATION = "A04",
        LOAD = "A05",
        # Fossil
        BIOMASS = "B01",
        FOSSIL_BROWN_COAL = "B02",
        FOSSIL_COAL_DERIVED_GAS = "B03",
        FOSSIL_GAS = "B04",
        FOSSIL_HARD_COAL = "B05",
        FOSSIL_OIL = "B06",
        FOSSIL_OIL_SHALE = "B07",
        FOSSIL_PEAT = "B08",
        # Renewables and other generation
        GEOTHERMAL = "B09",
        HYDRO_PUMPED_STORAGE = "B10",
        HYDRO_RUN_OF_RIVER = "B11",
        HYDRO_WATER_RESERVOIR = "B12",
        MARINE = "B13",
        NUCLEAR = "B14",
        OTHER_RENEWABLE = "B15",
        SOLAR = "B16",
        WASTE = "B17",
        WIND_OFFSHORE = "B18",
        WIND_ONSHORE = "B19",
        OTHER = "B20",
        # Grid infrastructure (used by transmission / outage docs)
        AC_LINK = "B21",
        DC_LINK = "B22",
        SUBSTATION = "B23",
        TRANSFORMER = "B24",
        BATTERY_STORAGE = "B25",
    ),
)

"""
    PsrGroup

Curated subset tuples for grouped client-side filtering of PSR codes.
Each value is a `Tuple{Vararg{String}}` holding the IEC codes in the
group:

```jldoctest
julia> PsrGroup.HYDRO
("B10", "B11", "B12")
```

Typical use — filter a result table to a family of technologies:

```julia
caps = installed_capacity_per_production_type(client, EIC.NL, t1, t2)
hydro_caps = caps[in.(caps.psr_type, Ref(PsrGroup.HYDRO))]
```

The groups are not exhaustive partitions — `OTHER`, `OTHER_RENEWABLE`,
aggregations (`MIXED` / `GENERATION` / `LOAD`), and infrastructure types
are deliberately excluded. Extend in user code by building your own
tuple.

ENTSO-E accepts only a *single* `psr_type` per server-side query, so
groups are useful **after** a fetch; passing a `PsrGroup` value
directly as the `psr_type` kwarg will raise.
"""
const PsrGroup = CodeTable(
    "PsrGroup",
    (
        HYDRO = ("B10", "B11", "B12"),
        WIND = ("B18", "B19"),
        FOSSIL = ("B02", "B03", "B04", "B05", "B06", "B07", "B08"),
        RENEWABLE = (
            "B01", "B09", "B11", "B12", "B13", "B15", "B16", "B17", "B18", "B19",
        ),
        STORAGE = ("B10", "B25"),
        INFRASTRUCTURE = ("B21", "B22", "B23", "B24"),
    ),
)

"""
    BusinessType

ENTSO-E `businessType` codes keyed by semantic name. Pass directly to
any wrapper that accepts `business_type`:

```julia
unavailability_of_generation_units(client, EIC.BE, t1, t2;
    business_type = BusinessType.PLANNED_OUTAGE)
```

See [`BUSINESS_LABELS`](@ref) for code → description lookup.

```jldoctest
julia> BusinessType.AREA_CONTROL_ERROR
"B33"
```
"""
const BusinessType = CodeTable(
    "BusinessType",
    (
        PRODUCTION = "A01",
        INTERNAL_TRADE = "A02",
        EXTERNAL_TRADE_EXPLICIT_ALLOCATION = "A03",
        CONSUMPTION = "A04",
        EXTERNAL_TRADE_TOTAL = "A05",
        RESULTING_IMBALANCE = "A06",
        INADVERTENT_ENERGY = "A07",
        BALANCE_ENERGY_DEVIATION = "A19",
        GENERAL_CAPACITY_INFORMATION = "A25",
        AVAILABLE_TRANSFER_CAPACITY = "A26",
        ALREADY_ALLOCATED_CAPACITY = "A29",
        OUTAGE = "A33",
        INSTALLED_GENERATION = "A37",
        AVAILABLE_MARGIN = "A38",
        GENERATION_FORECAST = "A39",
        REQUESTED_CAPACITY = "A43",
        COMPENSATION_ABSOLUTE_DECREASE = "A44",
        COMPENSATION_RELATIVE_DECREASE = "A45",
        SYSTEM_OPERATOR_REDISPATCH = "A46",
        CROSS_BORDER_REDISPATCH = "A48",
        COMMON_RESERVE_ALLOCATION = "A52",
        PLANNED_OUTAGE = "A53",
        UNPLANNED_OUTAGE = "A54",
        OTHER_OPERATIVE_INFORMATION = "A55",
        FCR = "A56",
        MIN_MARGIN = "A60",
        MAX_MARGIN = "A61",
        SPOT_PRICE = "A62",
        MINIMUM_POSSIBLE = "A63",
        MAXIMUM_POSSIBLE = "A64",
        POWER_SYSTEM_RESOURCE_TYPE = "A66",
        AUCTION_CANCELLATION = "A83",
        INTERNAL_REDISPATCH = "A85",
        FCR_CONTRACTED = "A95",
        AFRR = "A96",
        MFRR = "A97",
        RR = "A98",
        ACTIVATION = "B01",
        CAPACITY = "B02",
        AUCTION_REVENUE = "B03",
        COST = "B04",
        COUNTER_TRADE = "B05",  # also "Capacity allocated" on some allocation endpoints
        DC_LINK_CONSTRAINT = "B06",
        VOLUME_CONTRACTED = "B07",  # also "Total nominated capacity" on some endpoints
        RELIABILITY_MARGIN = "B08",
        OTHER = "B09",  # also "Net position" on some endpoints
        CONGESTION_INCOME = "B10",
        PRODUCTION_UNIT = "B11",
        AREA_CONTROL_ERROR = "B33",
        OFFER = "B74",
        NEED = "B75",
        PROCURED_CAPACITY = "B95",
        EXCHANGED_BALANCING_RESERVE_CAPACITY = "C21",
        SHARED_BALANCING_RESERVE_CAPACITY = "C22",
        SHARE_OF_RESERVE_CAPACITY = "C23",
        # C40–C46: Inter-platform mFRR/aFRR change-of-bid limit types
        CONDITIONAL_BID = "C40",
        THERMAL_LIMIT = "C41",
        FREQUENCY_LIMIT = "C42",
        VOLTAGE_LIMIT = "C43",
        CURRENT_LIMIT = "C44",
        SHORT_CIRCUIT_CURRENT_LIMIT = "C45",
        DYNAMIC_STABILITY_LIMIT = "C46",
        DISCONNECTION = "C47",
        FORECASTED_CAPACITY = "C76",
        MIN = "C77",
        AVG = "C78",
        MAX = "C79",
    ),
)

"""
    ProcessType

ENTSO-E `processType` codes keyed by semantic name. Pass directly to
any wrapper that accepts `process_type`:

```julia
volumes_and_prices_of_contracted_reserves(client, EIC.DE_LU, t1, t2;
    process_type = ProcessType.AFRR)
```

See [`PROCESS_LABELS`](@ref) for code → description lookup.

```jldoctest
julia> ProcessType.REALISED
"A16"
```
"""
const ProcessType = CodeTable(
    "ProcessType",
    (
        DAY_AHEAD = "A01",
        INTRADAY_INCREMENTAL = "A02",
        REALISED = "A16",
        INTRADAY_TOTAL = "A18",
        WEEK_AHEAD = "A31",
        MONTH_AHEAD = "A32",
        YEAR_AHEAD = "A33",
        SYNCHRONISATION = "A39",
        INTRADAY = "A40",
        DAY_AHEAD_FLOW_BASED = "A43",  # flow-based-allocations alternate (= A01 day-ahead)
        INTRADAY_FLOW_BASED = "A44",  # flow-based-allocations endpoint overload
        RR = "A46",
        MFRR = "A47",
        AFRR = "A51",
        FCR = "A52",
        FRR = "A56",
        SCHEDULED_ACTIVATION_MFRR = "A60",
        DIRECT_ACTIVATION_MFRR = "A61",
        IMBALANCE_NETTING = "A63",
        CRITERIA_INSTANTANEOUS_FREQUENCY = "A64",
        CRITERIA_FREQUENCY_RESTORATION = "A65",
        CENTRAL_SELECTION_AFRR = "A67",
        LOCAL_SELECTION_AFRR = "A68",
    ),
)

"""
    DocumentType

ENTSO-E `documentType` codes keyed by semantic name. Most named
wrappers fill `document_type` for you — reach for this when calling
the generated layer directly or post-processing `Raw()` responses.

See [`DOCUMENT_LABELS`](@ref) for code → description lookup.

```jldoctest
julia> DocumentType.PRICE
"A44"
```
"""
const DocumentType = CodeTable(
    "DocumentType",
    (
        FINALISED_SCHEDULE = "A09",
        AGGREGATED_ENERGY_DATA_REPORT = "A11",
        ACQUIRING_RESERVE_SCHEDULE = "A15",
        BID = "A24",
        ALLOCATION_RESULT = "A25",
        CAPACITY = "A26",
        CROSS_BORDER_SCHEDULE = "A30",
        AGREED_CAPACITY = "A31",
        CAPACITY_ALLOCATION_RELIABILITY_MARGIN = "A36",
        RELIABILITY_MARGIN = "A37",  # also "Reserve bid document" on some endpoints
        RESERVE_ALLOCATION_RESULT = "A38",
        PRICE = "A44",
        MEASUREMENT_VALUE = "A45",
        OUTAGE_PUBLICATION = "A53",  # collides with BusinessType.PLANNED_OUTAGE (A53)
        MOL_CAPACITY_ALLOCATION = "A60",
        MOL = "A61",  # also "Estimated Net Transfer Capacity" on some endpoints
        BID_AVAILABILITY = "A62",
        RESERVE_PLAN = "A63",  # also "Redispatch notice" on some endpoints
        SYSTEM_TOTAL_LOAD = "A65",
        INSTALLED_GENERATION_PER_TYPE = "A68",
        WIND_AND_SOLAR_FORECAST = "A69",
        LOAD_FORECAST_MARGIN = "A70",
        GENERATION_FORECAST = "A71",
        RESERVOIR_FILLING = "A72",
        ACTUAL_GENERATION = "A73",
        WIND_AND_SOLAR_GENERATION = "A74",
        ACTUAL_GENERATION_PER_TYPE = "A75",
        LOAD_UNAVAILABILITY = "A76",
        PRODUCTION_UNAVAILABILITY = "A77",
        TRANSMISSION_UNAVAILABILITY = "A78",
        OFFSHORE_GRID_UNAVAILABILITY = "A79",
        GENERATION_UNAVAILABILITY = "A80",
        CONTRACTED_RESERVES = "A81",
        ACCEPTED_OFFERS = "A82",
        ACTIVATED_BALANCING_QUANTITIES = "A83",
        ACTIVATED_BALANCING_PRICES = "A84",
        IMBALANCE_PRICES = "A85",
        IMBALANCE_VOLUME = "A86",
        FINANCIAL_SITUATION = "A87",
        CROSS_BORDER_BALANCING = "A88",
        CONTRACTED_RESERVE_PRICES = "A89",
        INTERCONNECTION_NETWORK_EXPANSION = "A90",
        COUNTER_TRADE_NOTICE = "A91",
        CONGESTION_COSTS = "A92",
        DC_LINK_CAPACITY = "A93",
        NON_EU_ALLOCATIONS = "A94",
        CONFIGURATION = "A95",
        SETTLEMENT = "A96",
        CAPACITY_NON_MARKET = "A97",
        HVDC_LINK_CONSTRAINTS = "A99",
        FLOW_BASED_DOMAIN_PUBLICATION = "B09",
        PRODUCTION_UNIT = "B11",
        AGGREGATED_NETTED_EXTERNAL_TSO_SCHEDULE = "B17",
        PUBLISHED_OFFERED_CAPACITY = "B33",  # collides with BusinessType.AREA_CONTROL_ERROR (B33)
        BID_AVAILABILITY_B45 = "B45",  # distinct from BID_AVAILABILITY (A62)
        OTHER_MARKET_INFORMATION = "B47",
    ),
)

# ---------------------------------------------------------------------------
# Tier-2 code lists — auction / contract / status. Less heavily used
# from the named-wrapper layer but still worth a typed constant.

"""
    AuctionType

ENTSO-E `auction.Type` codes (Market allocation endpoints).

```jldoctest
julia> AuctionType.IMPLICIT
"A01"
```
"""
const AuctionType = CodeTable(
    "AuctionType",
    (
        IMPLICIT = "A01",
        EXPLICIT = "A02",
        CONTINUOUS = "A08",
    ),
)

"""
    AuctionCategory

ENTSO-E `auction.Category` codes (Market allocation endpoints).

```jldoctest
julia> AuctionCategory.HOURLY
"A04"
```
"""
const AuctionCategory = CodeTable(
    "AuctionCategory",
    (
        BASE = "A01",
        PEAK = "A02",
        OFF_PEAK = "A03",
        HOURLY = "A04",
    ),
)

"""
    ContractType

ENTSO-E `contract_MarketAgreement.Type` codes — the agreement horizon
of a market document. Same code shared across day-ahead / intraday /
forward variants.

```jldoctest
julia> ContractType.DAILY
"A01"
```
"""
const ContractType = CodeTable(
    "ContractType",
    (
        DAILY = "A01",
        WEEKLY = "A02",
        MONTHLY = "A03",
        YEARLY = "A04",
        TOTAL = "A05",
        LONG_TERM = "A06",
        INTRADAY = "A07",
        QUARTERLY = "A08",
        HOURLY = "A13",
    ),
)

"""
    StandardProduct

ENTSO-E `standard_MarketProduct` codes — selects the standard balancing
product family on the contracted-reserves / balancing-energy-bids
endpoints.

```jldoctest
julia> StandardProduct.STANDARD
"A01"
```
"""
const StandardProduct = CodeTable(
    "StandardProduct",
    (
        STANDARD = "A01",
        STANDARD_MFRR_SCHEDULED_ACTIVATION = "A05",
        STANDARD_MFRR_DIRECT_ACTIVATION = "A07",
    ),
)

"""
    DocStatus

ENTSO-E `docStatus` codes — used by the Outages endpoints to slice
notices by status (active vs cancelled vs withdrawn).

```jldoctest
julia> DocStatus.WITHDRAWN
"A13"
```
"""
const DocStatus = CodeTable(
    "DocStatus",
    (
        INTERMEDIATE = "A01",
        FINAL = "A02",
        ACTIVE = "A05",
        CANCELLED = "A09",
        WITHDRAWN = "A13",
        ESTIMATED = "X01",
    ),
)

# ---------------------------------------------------------------------------
# Description-lookup helpers (kept compatible with the renamed `*_LABELS`
# tables).

"""
    describe(table, code) -> String

Resolve a code (string or symbol) against one of the description
NamedTuples [`DOCUMENT_LABELS`](@ref), [`PROCESS_LABELS`](@ref),
[`BUSINESS_LABELS`](@ref), [`PSR_LABELS`](@ref). Throws `KeyError` if
the code isn't in the table.

```jldoctest
julia> ENTSOE.describe(DOCUMENT_LABELS, "A44")
"Price document"

julia> ENTSOE.describe(PSR_LABELS, :B19)
"Wind Onshore"
```
"""
describe(table::NamedTuple, code::AbstractString) = describe(table, Symbol(code))
function describe(table::NamedTuple, code::Symbol)
    haskey(table, code) ||
        throw(KeyError("$(code) not found in this code list"))
    return table[code]
end

"""
    code_for(table, label) -> String

Reverse-lookup: case-insensitive substring match on the human-readable
description; returns the *string* code (e.g. `"A44"`). Useful for
quickly finding a code from a fragment of the official label.

```jldoctest
julia> ENTSOE.code_for(PSR_LABELS, "wind onshore")
"B19"

julia> ENTSOE.code_for(DOCUMENT_LABELS, "price document")
"A44"
```

Throws if zero or multiple entries match.
"""
function code_for(table::NamedTuple, label::AbstractString)
    needle = lowercase(label)
    matches = Pair{Symbol, String}[]
    for (k, v) in pairs(table)
        occursin(needle, lowercase(v)) && push!(matches, k => v)
    end
    isempty(matches) &&
        throw(KeyError("no code in this list matches `$label`"))
    length(matches) == 1 ||
        error(
        "ambiguous: $(label) matches " *
            join(("$(k) ($(v))" for (k, v) in matches), ", ")
    )
    return String(first(matches[1]))
end
