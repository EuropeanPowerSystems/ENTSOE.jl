# Auto-generated from iec62325-451-3-capacityAuction_v7_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: iec62325.351:tc57wg16:451-3:capacityspecificationdocument:7:1

module CapacityAuction_v7_1

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

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct RightsCharacteristics_Auction
    rights::String = ""
end

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    quantity::Float64 = 0.0
end

Base.@kwdef mutable struct Series_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    resolution::String = ""
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AttributeInstanceComponent
    position::Int64 = 0
    attribute::String = ""
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Auction_TimeSeries
    mRID::String = ""
    businessType::String = ""
    auction_category::String = ""
    auction_type::String = ""
    auction_allocationMode::String = ""
    auction_paymentTerms::String = ""
    auction_cancelled::Union{Nothing, String} = nothing
    bidding_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    in_Domain_mRID::AreaID_String = AreaID_String()
    out_Domain_mRID::AreaID_String = AreaID_String()
    marketAgreement_type::String = ""
    delivery_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    quantity_Measure_Unit_name::String = ""
    price_Measure_Unit_name::String = ""
    currency_Unit_name::String = ""
    notification_MarketAgreement_createdDateTime::DateTime = DateTime(1970)
    contestation_MarketAgreement_createdDateTime::DateTime = DateTime(1970)
    publication_MarketAgreement_createdDateTime::DateTime = DateTime(1970)
    resale_MarketAgreement_createdDateTime::Union{Nothing, DateTime} = nothing
    curveType::String = ""
    connectingLine_RegisteredResource_mRID::Union{Nothing, ResourceID_String} = nothing
    Period::Vector{Series_Period} = Series_Period[]
    AuctionDescription_AttributeInstanceComponent::Vector{AttributeInstanceComponent} = AttributeInstanceComponent[]
    RightsCharacteristics_Auction::Vector{RightsCharacteristics_Auction} = RightsCharacteristics_Auction[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct CapacityAuctionSpecification_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    receiver_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    createdDateTime::DateTime = DateTime(1970)
    period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    domain_mRID::AreaID_String = AreaID_String()
    Auction_TimeSeries::Vector{Auction_TimeSeries} = Auction_TimeSeries[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

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

function _parse(::Type{RightsCharacteristics_Auction}, n::EzXML.Node)
    out = RightsCharacteristics_Auction()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "rights"
            out.rights = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Reason}, n::EzXML.Node)
    out = Reason()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "code"
            out.code = String(strip(nodecontent(c)))
        elseif nm == "text"
            out.text = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Point}, n::EzXML.Node)
    out = Point()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "position"
            out.position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "quantity"
            out.quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Series_Period}, n::EzXML.Node)
    out = Series_Period()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "timeInterval"
            out.timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "resolution"
            out.resolution = String(strip(nodecontent(c)))
        elseif nm == "Point"
            push!(out.Point, _parse(Point, c))
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

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{AttributeInstanceComponent}, n::EzXML.Node)
    out = AttributeInstanceComponent()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "position"
            out.position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "attribute"
            out.attribute = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{ResourceID_String}, n::EzXML.Node)
    out = ResourceID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{Auction_TimeSeries}, n::EzXML.Node)
    out = Auction_TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "auction.category"
            out.auction_category = String(strip(nodecontent(c)))
        elseif nm == "auction.type"
            out.auction_type = String(strip(nodecontent(c)))
        elseif nm == "auction.allocationMode"
            out.auction_allocationMode = String(strip(nodecontent(c)))
        elseif nm == "auction.paymentTerms"
            out.auction_paymentTerms = String(strip(nodecontent(c)))
        elseif nm == "auction.cancelled"
            out.auction_cancelled = String(strip(nodecontent(c)))
        elseif nm == "bidding_Period.timeInterval"
            out.bidding_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "marketAgreement.type"
            out.marketAgreement_type = String(strip(nodecontent(c)))
        elseif nm == "delivery_Period.timeInterval"
            out.delivery_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "quantity_Measure_Unit.name"
            out.quantity_Measure_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "price_Measure_Unit.name"
            out.price_Measure_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "currency_Unit.name"
            out.currency_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "notification_MarketAgreement.createdDateTime"
            out.notification_MarketAgreement_createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "contestation_MarketAgreement.createdDateTime"
            out.contestation_MarketAgreement_createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "publication_MarketAgreement.createdDateTime"
            out.publication_MarketAgreement_createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "resale_MarketAgreement.createdDateTime"
            out.resale_MarketAgreement_createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "connectingLine_RegisteredResource.mRID"
            out.connectingLine_RegisteredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        elseif nm == "AuctionDescription_AttributeInstanceComponent"
            push!(out.AuctionDescription_AttributeInstanceComponent, _parse(AttributeInstanceComponent, c))
        elseif nm == "RightsCharacteristics_Auction"
            push!(out.RightsCharacteristics_Auction, _parse(RightsCharacteristics_Auction, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

function _parse(::Type{CapacityAuctionSpecification_MarketDocument}, n::EzXML.Node)
    out = CapacityAuctionSpecification_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "revisionNumber"
            out.revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "type"
            out.type_ = String(strip(nodecontent(c)))
        elseif nm == "process.processType"
            out.process_processType = String(strip(nodecontent(c)))
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
        elseif nm == "period.timeInterval"
            out.period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "Auction_TimeSeries"
            push!(out.Auction_TimeSeries, _parse(Auction_TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::CapacityAuctionSpecification_MarketDocument
    return _parse(CapacityAuctionSpecification_MarketDocument, root(parsexml(xml)))
end

end  # module CapacityAuction_v7_1
