# Auto-generated from iec62325-451-6-balancing_v4_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-6:balancingdocument:4:1

module Balancing_v4_1

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

Base.@kwdef mutable struct Financial_Price
    amount::Float64 = 0.0
    direction::String = ""
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    quantity::Union{Nothing, Float64} = nothing
    secondaryQuantity::Union{Nothing, Float64} = nothing
    unavailable_Quantity_quantity::Union{Nothing, Float64} = nothing
    activation_Price_amount::Union{Nothing, Float64} = nothing
    procurement_Price_amount::Union{Nothing, Float64} = nothing
    min_Price_amount::Union{Nothing, Float64} = nothing
    max_Price_amount::Union{Nothing, Float64} = nothing
    imbalance_Price_amount::Union{Nothing, Float64} = nothing
    imbalance_Price_category::Union{Nothing, String} = nothing
    flowDirection_direction::Union{Nothing, String} = nothing
    Financial_Price::Vector{Financial_Price} = Financial_Price[]
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Action_Status
    value::String = ""
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Series_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    resolution::String = ""
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    businessType::String = ""
    acquiring_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    connecting_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    type_MarketAgreement_type::Union{Nothing, String} = nothing
    standard_MarketProduct_marketProductType::Union{Nothing, String} = nothing
    original_MarketProduct_marketProductType::Union{Nothing, String} = nothing
    mktPSRType_psrType::Union{Nothing, String} = nothing
    flowDirection_direction::Union{Nothing, String} = nothing
    currency_Unit_name::Union{Nothing, String} = nothing
    quantity_Measure_Unit_name::Union{Nothing, String} = nothing
    price_Measure_Unit_name::Union{Nothing, String} = nothing
    curveType::Union{Nothing, String} = nothing
    cancelledTS::Union{Nothing, String} = nothing
    Period::Vector{Series_Period} = Series_Period[]
end

Base.@kwdef mutable struct Balancing_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    docStatus::Union{Nothing, Action_Status} = nothing
    area_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    allocationDecision_DateAndOrTime_dateTime::Union{Nothing, DateTime} = nothing
    period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

function _parse(::Type{Financial_Price}, n::EzXML.Node)
    out = Financial_Price()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "amount"
            out.amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "direction"
            out.direction = String(strip(nodecontent(c)))
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
        elseif nm == "secondaryQuantity"
            out.secondaryQuantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "unavailable_Quantity.quantity"
            out.unavailable_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "activation_Price.amount"
            out.activation_Price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "procurement_Price.amount"
            out.procurement_Price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "min_Price.amount"
            out.min_Price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "max_Price.amount"
            out.max_Price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "imbalance_Price.amount"
            out.imbalance_Price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "imbalance_Price.category"
            out.imbalance_Price_category = String(strip(nodecontent(c)))
        elseif nm == "flowDirection.direction"
            out.flowDirection_direction = String(strip(nodecontent(c)))
        elseif nm == "Financial_Price"
            push!(out.Financial_Price, _parse(Financial_Price, c))
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

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
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

function _parse(::Type{TimeSeries}, n::EzXML.Node)
    out = TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "acquiring_Domain.mRID"
            out.acquiring_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "connecting_Domain.mRID"
            out.connecting_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "type_MarketAgreement.type"
            out.type_MarketAgreement_type = String(strip(nodecontent(c)))
        elseif nm == "standard_MarketProduct.marketProductType"
            out.standard_MarketProduct_marketProductType = String(strip(nodecontent(c)))
        elseif nm == "original_MarketProduct.marketProductType"
            out.original_MarketProduct_marketProductType = String(strip(nodecontent(c)))
        elseif nm == "mktPSRType.psrType"
            out.mktPSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "flowDirection.direction"
            out.flowDirection_direction = String(strip(nodecontent(c)))
        elseif nm == "currency_Unit.name"
            out.currency_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "quantity_Measure_Unit.name"
            out.quantity_Measure_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "price_Measure_Unit.name"
            out.price_Measure_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "cancelledTS"
            out.cancelledTS = String(strip(nodecontent(c)))
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        end
    end
    return out
end

function _parse(::Type{Balancing_MarketDocument}, n::EzXML.Node)
    out = Balancing_MarketDocument()
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
        elseif nm == "docStatus"
            out.docStatus = _parse(Action_Status, c)
        elseif nm == "area_Domain.mRID"
            out.area_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "allocationDecision_DateAndOrTime.dateTime"
            out.allocationDecision_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "period.timeInterval"
            out.period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::Balancing_MarketDocument
    return _parse(Balancing_MarketDocument, root(parsexml(xml)))
end

end  # module Balancing_v4_1
