# Auto-generated from iec62325-451-6-capacityallocationconfiguration_v1_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-6:capacityallocationconfigurationdocument:1:1

module Capacityallocationconfiguration_v1_1

using Dates: Dates, DateTime, Date
using EzXML: EzXML, parsexml, root, elements, nodename, nodecontent

# EzXML treats attribute lookup as dict-style — `node["x"]` /
# `haskey(node, "x")`. Alias `hasattribute` for readability.
hasattribute(node, name) = haskey(node, name)

# ---------------------------------------------------------------------------
# Complex types (mutable kwdef structs, all fields with safe defaults).
#
# Simple-type aliases (e.g. `ID_String`, `Position_Integer`) are inlined
# to their underlying primitives (`String`, `Int64`, `Float64`, `DateTime`)
# at codegen time — saves ~3 500 lines of `const X = String` boilerplate
# across the schema family and removes a layer of indirection. The
# original XSD simpleType names live in the source schema for reference.

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    timeSeries_name::String = ""
    timeSeries_in_Domain_mRID::AreaID_String = AreaID_String()
    timeSeries_out_Domain_mRID::AreaID_String = AreaID_String()
    timeSeries_currency_Unit_name::String = ""
    timeSeries_auction_category::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Allocation_TimeSeries
    name::String = ""
    cancelledTS::Union{Nothing, String} = nothing
    description::Union{Nothing, String} = nothing
    auction_type::String = ""
    auction_allocationMode::Union{Nothing, String} = nothing
    subType_Auction_type::Union{Nothing, String} = nothing
    marketAgreement_type::String = ""
    timeZone_AttributeInstanceComponent_attribute::String = ""
    delivery_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    allocation_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    bidding_Period_timeInterval::Union{Nothing, ESMP_DateTimeInterval} = nothing
    offeredCapacityProvider_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    useOfCapacityProvider_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    alreadyAllocatedCapacityProvider_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    auctionRevenueProvider_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    capacityThirdCountriesProvider_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    congestionIncome_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    conductingParty_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct CapacityAllocationConfiguration_MarketDocument
    mRID::String = ""
    type_::String = ""
    process_processType::String = ""
    process_classificationType::Union{Nothing, String} = nothing
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    Allocation_TimeSeries::Vector{Allocation_TimeSeries} = Allocation_TimeSeries[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{Point}, n::EzXML.Node)
    out = Point()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "position"
            out.position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "timeSeries.name"
            out.timeSeries_name = String(strip(nodecontent(c)))
        elseif nm == "timeSeries.in_Domain.mRID"
            out.timeSeries_in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "timeSeries.out_Domain.mRID"
            out.timeSeries_out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "timeSeries.currency_Unit.name"
            out.timeSeries_currency_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "timeSeries.auction.category"
            out.timeSeries_auction_category = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{ESMP_DateTimeInterval}, n::EzXML.Node)
    out = ESMP_DateTimeInterval()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "start"
            out.start = String(strip(nodecontent(c)))
        elseif nm == "end"
            out.end_ = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{PartyID_String}, n::EzXML.Node)
    out = PartyID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{Allocation_TimeSeries}, n::EzXML.Node)
    out = Allocation_TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "cancelledTS"
            out.cancelledTS = String(strip(nodecontent(c)))
        elseif nm == "description"
            out.description = String(strip(nodecontent(c)))
        elseif nm == "auction.type"
            out.auction_type = String(strip(nodecontent(c)))
        elseif nm == "auction.allocationMode"
            out.auction_allocationMode = String(strip(nodecontent(c)))
        elseif nm == "subType_Auction.type"
            out.subType_Auction_type = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.type"
            out.marketAgreement_type = String(strip(nodecontent(c)))
        elseif nm == "timeZone_AttributeInstanceComponent.attribute"
            out.timeZone_AttributeInstanceComponent_attribute = String(strip(nodecontent(c)))
        elseif nm == "delivery_Period.timeInterval"
            out.delivery_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "allocation_Period.timeInterval"
            out.allocation_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "bidding_Period.timeInterval"
            out.bidding_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "offeredCapacityProvider_MarketParticipant.mRID"
            out.offeredCapacityProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "useOfCapacityProvider_MarketParticipant.mRID"
            out.useOfCapacityProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "alreadyAllocatedCapacityProvider_MarketParticipant.mRID"
            out.alreadyAllocatedCapacityProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "auctionRevenueProvider_MarketParticipant.mRID"
            out.auctionRevenueProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "capacityThirdCountriesProvider_MarketParticipant.mRID"
            out.capacityThirdCountriesProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "congestionIncome_MarketParticipant.mRID"
            out.congestionIncome_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "conductingParty_MarketParticipant.mRID"
            out.conductingParty_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "Point"
            push!(out.Point, _parse(Point, c))
        end
    end
    return out
end

function _parse(::Type{CapacityAllocationConfiguration_MarketDocument}, n::EzXML.Node)
    out = CapacityAllocationConfiguration_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "type"
            out.type_ = String(strip(nodecontent(c)))
        elseif nm == "process.processType"
            out.process_processType = String(strip(nodecontent(c)))
        elseif nm == "process.classificationType"
            out.process_classificationType = String(strip(nodecontent(c)))
        elseif nm == "sender_MarketParticipant.mRID"
            out.sender_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "sender_MarketParticipant.marketRole.type"
            out.sender_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "receiver_MarketParticipant.mRID"
            out.receiver_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "receiver_MarketParticipant.marketRole.type"
            out.receiver_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "createdDateTime"
            out.createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "Allocation_TimeSeries"
            push!(out.Allocation_TimeSeries, _parse(Allocation_TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::CapacityAllocationConfiguration_MarketDocument
    return _parse(CapacityAllocationConfiguration_MarketDocument, root(parsexml(xml)))
end

end  # module Capacityallocationconfiguration_v1_1
