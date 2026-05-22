# Auto-generated from iec62325-451-7-reservebiddocument_v7_2.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-7:reservebiddocument:7:2

module Reservebiddocument_v7_2

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

Base.@kwdef mutable struct BiddingZone_Domain
    mRID::AreaID_String = AreaID_String()
    name::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Origin_MarketParticipant
    mRID::PartyID_String = PartyID_String()
end

Base.@kwdef mutable struct Action_Status
    value::String = ""
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    quantity_quantity::Float64 = 0.0
    minimum_Quantity_quantity::Union{Nothing, Float64} = nothing
    price_amount::Union{Nothing, Float64} = nothing
    energy_Price_amount::Union{Nothing, Float64} = nothing
end

Base.@kwdef mutable struct Series_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    resolution::String = ""
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct Linked_BidTimeSeries
    mRID::String = ""
    status::Union{Nothing, Action_Status} = nothing
end

Base.@kwdef mutable struct BidTimeSeries
    mRID::String = ""
    auction_mRID::Union{Nothing, String} = nothing
    businessType::String = ""
    acquiring_Domain_mRID::AreaID_String = AreaID_String()
    connecting_Domain_mRID::AreaID_String = AreaID_String()
    provider_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    quantity_Measure_Unit_name::String = ""
    currency_Unit_name::Union{Nothing, String} = nothing
    price_Measure_Unit_name::Union{Nothing, String} = nothing
    divisible::String = ""
    linkedBidsIdentification::Union{Nothing, String} = nothing
    multipartBidIdentification::Union{Nothing, String} = nothing
    exclusiveBidsIdentification::Union{Nothing, String} = nothing
    blockBid::Union{Nothing, String} = nothing
    status::Union{Nothing, Action_Status} = nothing
    priority::Union{Nothing, Int64} = nothing
    registeredResource_mRID::Union{Nothing, ResourceID_String} = nothing
    flowDirection_direction::String = ""
    stepIncrementQuantity::Union{Nothing, Float64} = nothing
    energyPrice_Measure_Unit_name::Union{Nothing, String} = nothing
    marketAgreement_type::Union{Nothing, String} = nothing
    marketAgreement_mRID::Union{Nothing, String} = nothing
    marketAgreement_createdDateTime::Union{Nothing, DateTime} = nothing
    activation_ConstraintDuration_duration::Union{Nothing, String} = nothing
    resting_ConstraintDuration_duration::Union{Nothing, String} = nothing
    minimum_ConstraintDuration_duration::Union{Nothing, String} = nothing
    maximum_ConstraintDuration_duration::Union{Nothing, String} = nothing
    standard_MarketProduct_marketProductType::Union{Nothing, String} = nothing
    original_MarketProduct_marketProductType::Union{Nothing, String} = nothing
    validity_Period_timeInterval::Union{Nothing, ESMP_DateTimeInterval} = nothing
    Period::Vector{Series_Period} = Series_Period[]
    AvailableBiddingZone_Domain::Vector{BiddingZone_Domain} = BiddingZone_Domain[]
    Reason::Vector{Reason} = Reason[]
    Linked_BidTimeSeries::Vector{Linked_BidTimeSeries} = Linked_BidTimeSeries[]
    ProcuredFor_MarketParticipant::Union{Nothing, Origin_MarketParticipant} = nothing
    SharedWith_MarketParticipant::Vector{Origin_MarketParticipant} = Origin_MarketParticipant[]
    ExchangedWith_MarketParticipant::Vector{Origin_MarketParticipant} = Origin_MarketParticipant[]
end

Base.@kwdef mutable struct ReserveBid_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::Union{Nothing, String} = nothing
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    reserveBid_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    domain_mRID::AreaID_String = AreaID_String()
    subject_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    subject_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    Bid_TimeSeries::Vector{BidTimeSeries} = BidTimeSeries[]
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

function _parse(::Type{BiddingZone_Domain}, n::EzXML.Node)
    out = BiddingZone_Domain()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(AreaID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
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

function _parse(::Type{PartyID_String}, n::EzXML.Node)
    out = PartyID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{Origin_MarketParticipant}, n::EzXML.Node)
    out = Origin_MarketParticipant()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(PartyID_String, c)
        end
    end
    return out
end

function _parse(::Type{Action_Status}, n::EzXML.Node)
    out = Action_Status()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "value"
            out.value = String(strip(nodecontent(c)))
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

function _parse(::Type{Point}, n::EzXML.Node)
    out = Point()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "position"
            out.position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "quantity.quantity"
            out.quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "minimum_Quantity.quantity"
            out.minimum_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "price.amount"
            out.price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "energy_Price.amount"
            out.energy_Price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
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

function _parse(::Type{Linked_BidTimeSeries}, n::EzXML.Node)
    out = Linked_BidTimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "status"
            out.status = _parse(Action_Status, c)
        end
    end
    return out
end

function _parse(::Type{BidTimeSeries}, n::EzXML.Node)
    out = BidTimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "auction.mRID"
            out.auction_mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "acquiring_Domain.mRID"
            out.acquiring_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "connecting_Domain.mRID"
            out.connecting_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "provider_MarketParticipant.mRID"
            out.provider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "quantity_Measure_Unit.name"
            out.quantity_Measure_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "currency_Unit.name"
            out.currency_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "price_Measure_Unit.name"
            out.price_Measure_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "divisible"
            out.divisible = String(strip(nodecontent(c)))
        elseif nm == "linkedBidsIdentification"
            out.linkedBidsIdentification = String(strip(nodecontent(c)))
        elseif nm == "multipartBidIdentification"
            out.multipartBidIdentification = String(strip(nodecontent(c)))
        elseif nm == "exclusiveBidsIdentification"
            out.exclusiveBidsIdentification = String(strip(nodecontent(c)))
        elseif nm == "blockBid"
            out.blockBid = String(strip(nodecontent(c)))
        elseif nm == "status"
            out.status = _parse(Action_Status, c)
        elseif nm == "priority"
            out.priority = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "registeredResource.mRID"
            out.registeredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "flowDirection.direction"
            out.flowDirection_direction = String(strip(nodecontent(c)))
        elseif nm == "stepIncrementQuantity"
            out.stepIncrementQuantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "energyPrice_Measure_Unit.name"
            out.energyPrice_Measure_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.type"
            out.marketAgreement_type = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.mRID"
            out.marketAgreement_mRID = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.createdDateTime"
            out.marketAgreement_createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "activation_ConstraintDuration.duration"
            out.activation_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "resting_ConstraintDuration.duration"
            out.resting_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "minimum_ConstraintDuration.duration"
            out.minimum_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "maximum_ConstraintDuration.duration"
            out.maximum_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "standard_MarketProduct.marketProductType"
            out.standard_MarketProduct_marketProductType = String(strip(nodecontent(c)))
        elseif nm == "original_MarketProduct.marketProductType"
            out.original_MarketProduct_marketProductType = String(strip(nodecontent(c)))
        elseif nm == "validity_Period.timeInterval"
            out.validity_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        elseif nm == "AvailableBiddingZone_Domain"
            push!(out.AvailableBiddingZone_Domain, _parse(BiddingZone_Domain, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        elseif nm == "Linked_BidTimeSeries"
            push!(out.Linked_BidTimeSeries, _parse(Linked_BidTimeSeries, c))
        elseif nm == "ProcuredFor_MarketParticipant"
            out.ProcuredFor_MarketParticipant = _parse(Origin_MarketParticipant, c)
        elseif nm == "SharedWith_MarketParticipant"
            push!(out.SharedWith_MarketParticipant, _parse(Origin_MarketParticipant, c))
        elseif nm == "ExchangedWith_MarketParticipant"
            push!(out.ExchangedWith_MarketParticipant, _parse(Origin_MarketParticipant, c))
        end
    end
    return out
end

function _parse(::Type{ReserveBid_MarketDocument}, n::EzXML.Node)
    out = ReserveBid_MarketDocument()
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
        elseif nm == "reserveBid_Period.timeInterval"
            out.reserveBid_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "subject_MarketParticipant.mRID"
            out.subject_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "subject_MarketParticipant.marketRole.type"
            out.subject_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "Bid_TimeSeries"
            push!(out.Bid_TimeSeries, _parse(BidTimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::ReserveBid_MarketDocument
    return _parse(ReserveBid_MarketDocument, root(parsexml(xml)))
end

end  # module Reservebiddocument_v7_2
