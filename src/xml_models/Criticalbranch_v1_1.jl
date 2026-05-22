# Auto-generated from iec62325-451-n-criticalbranch_v1_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:criticalnetworkelementdocument:1:1

module Criticalbranch_v1_1

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

Base.@kwdef mutable struct MeasurementPointID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Outage_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    in_AggregateNode_mRID::Union{Nothing, MeasurementPointID_String} = nothing
    out_AggregateNode_mRID::Union{Nothing, MeasurementPointID_String} = nothing
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

Base.@kwdef mutable struct Party_MarketParticipant
    mRID::PartyID_String = PartyID_String()
end

Base.@kwdef mutable struct PTDF_Domain
    mRID::AreaID_String = AreaID_String()
    pTDF_Quantity_quantity::Float64 = 0.0
    pTDF_Quantity_quality::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct AnalogValue
    value::Float32 = 0.0
    timeStamp::Union{Nothing, DateTime} = nothing
    description::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Analog
    measurementType::String = ""
    unitSymbol::String = ""
    positiveFlowIn::Union{Nothing, String} = nothing
    AnalogValues::Vector{AnalogValue} = AnalogValue[]
end

Base.@kwdef mutable struct Monitored_RegisteredResource
    mRID::Union{Nothing, ResourceID_String} = nothing
    name::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    in_AggregateNode_mRID::Union{Nothing, MeasurementPointID_String} = nothing
    out_AggregateNode_mRID::Union{Nothing, MeasurementPointID_String} = nothing
    flowBasedStudy_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    flowBasedStudy_Domain_flowBasedMargin_Quantity_quantity::Union{Nothing, Float64} = nothing
    flowBasedStudy_Domain_flowBasedMargin_Quantity_quality::Union{Nothing, String} = nothing
    marketCoupling_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    marketCoupling_Domain_shadow_Price_amount::Union{Nothing, Float64} = nothing
    PTDF_Domain::Vector{PTDF_Domain} = PTDF_Domain[]
    Measurements::Vector{Analog} = Analog[]
end

Base.@kwdef mutable struct RemedialAction_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    in_AggregateNode_mRID::Union{Nothing, MeasurementPointID_String} = nothing
    out_AggregateNode_mRID::Union{Nothing, MeasurementPointID_String} = nothing
    pSRType_psrType::String = ""
    marketObjectStatus_status::String = ""
end

Base.@kwdef mutable struct Constraint_TimeSeries
    mRID::String = ""
    businessType::String = ""
    name::Union{Nothing, String} = nothing
    quantity_Measurement_Unit_name::Union{Nothing, String} = nothing
    externalConstraint_Quantity_quantity::Union{Nothing, Float64} = nothing
    externalConstraint_Quantity_quality::Union{Nothing, String} = nothing
    pTDF_Measurement_Unit_name::Union{Nothing, String} = nothing
    shadowPrice_Measurement_Unit_name::Union{Nothing, String} = nothing
    currency_Unit_name::Union{Nothing, String} = nothing
    Party_MarketParticipant::Vector{Party_MarketParticipant} = Party_MarketParticipant[]
    Outage_RegisteredResource::Vector{Outage_RegisteredResource} = Outage_RegisteredResource[]
    RemedialAction_RegisteredResource::Vector{RemedialAction_RegisteredResource} = RemedialAction_RegisteredResource[]
    Monitored_RegisteredResource::Vector{Monitored_RegisteredResource} = Monitored_RegisteredResource[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    Constraint_TimeSeries::Vector{Constraint_TimeSeries} = Constraint_TimeSeries[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Series_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    resolution::String = ""
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    businessType::String = ""
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    curveType::String = ""
    Period::Vector{Series_Period} = Series_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct CriticalNetworkElement_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    time_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    domain_mRID::Union{Nothing, AreaID_String} = nothing
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

function _parse(::Type{MeasurementPointID_String}, n::EzXML.Node)
    out = MeasurementPointID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
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

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{Outage_RegisteredResource}, n::EzXML.Node)
    out = Outage_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "in_AggregateNode.mRID"
            out.in_AggregateNode_mRID = _parse(MeasurementPointID_String, c)
        elseif nm == "out_AggregateNode.mRID"
            out.out_AggregateNode_mRID = _parse(MeasurementPointID_String, c)
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

function _parse(::Type{Party_MarketParticipant}, n::EzXML.Node)
    out = Party_MarketParticipant()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(PartyID_String, c)
        end
    end
    return out
end

function _parse(::Type{PTDF_Domain}, n::EzXML.Node)
    out = PTDF_Domain()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(AreaID_String, c)
        elseif nm == "pTDF_Quantity.quantity"
            out.pTDF_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "pTDF_Quantity.quality"
            out.pTDF_Quantity_quality = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{AnalogValue}, n::EzXML.Node)
    out = AnalogValue()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "value"
            out.value = (x -> parse(Float32, x))(strip(nodecontent(c)))
        elseif nm == "timeStamp"
            out.timeStamp = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "description"
            out.description = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Analog}, n::EzXML.Node)
    out = Analog()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "measurementType"
            out.measurementType = String(strip(nodecontent(c)))
        elseif nm == "unitSymbol"
            out.unitSymbol = String(strip(nodecontent(c)))
        elseif nm == "positiveFlowIn"
            out.positiveFlowIn = String(strip(nodecontent(c)))
        elseif nm == "AnalogValues"
            push!(out.AnalogValues, _parse(AnalogValue, c))
        end
    end
    return out
end

function _parse(::Type{Monitored_RegisteredResource}, n::EzXML.Node)
    out = Monitored_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "in_AggregateNode.mRID"
            out.in_AggregateNode_mRID = _parse(MeasurementPointID_String, c)
        elseif nm == "out_AggregateNode.mRID"
            out.out_AggregateNode_mRID = _parse(MeasurementPointID_String, c)
        elseif nm == "flowBasedStudy_Domain.mRID"
            out.flowBasedStudy_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "flowBasedStudy_Domain.flowBasedMargin_Quantity.quantity"
            out.flowBasedStudy_Domain_flowBasedMargin_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "flowBasedStudy_Domain.flowBasedMargin_Quantity.quality"
            out.flowBasedStudy_Domain_flowBasedMargin_Quantity_quality = String(strip(nodecontent(c)))
        elseif nm == "marketCoupling_Domain.mRID"
            out.marketCoupling_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "marketCoupling_Domain.shadow_Price.amount"
            out.marketCoupling_Domain_shadow_Price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "PTDF_Domain"
            push!(out.PTDF_Domain, _parse(PTDF_Domain, c))
        elseif nm == "Measurements"
            push!(out.Measurements, _parse(Analog, c))
        end
    end
    return out
end

function _parse(::Type{RemedialAction_RegisteredResource}, n::EzXML.Node)
    out = RemedialAction_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "in_AggregateNode.mRID"
            out.in_AggregateNode_mRID = _parse(MeasurementPointID_String, c)
        elseif nm == "out_AggregateNode.mRID"
            out.out_AggregateNode_mRID = _parse(MeasurementPointID_String, c)
        elseif nm == "pSRType.psrType"
            out.pSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "marketObjectStatus.status"
            out.marketObjectStatus_status = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Constraint_TimeSeries}, n::EzXML.Node)
    out = Constraint_TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "quantity_Measurement_Unit.name"
            out.quantity_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "externalConstraint_Quantity.quantity"
            out.externalConstraint_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "externalConstraint_Quantity.quality"
            out.externalConstraint_Quantity_quality = String(strip(nodecontent(c)))
        elseif nm == "pTDF_Measurement_Unit.name"
            out.pTDF_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "shadowPrice_Measurement_Unit.name"
            out.shadowPrice_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "currency_Unit.name"
            out.currency_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "Party_MarketParticipant"
            push!(out.Party_MarketParticipant, _parse(Party_MarketParticipant, c))
        elseif nm == "Outage_RegisteredResource"
            push!(out.Outage_RegisteredResource, _parse(Outage_RegisteredResource, c))
        elseif nm == "RemedialAction_RegisteredResource"
            push!(out.RemedialAction_RegisteredResource, _parse(RemedialAction_RegisteredResource, c))
        elseif nm == "Monitored_RegisteredResource"
            push!(out.Monitored_RegisteredResource, _parse(Monitored_RegisteredResource, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
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
        elseif nm == "Constraint_TimeSeries"
            push!(out.Constraint_TimeSeries, _parse(Constraint_TimeSeries, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
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

function _parse(::Type{TimeSeries}, n::EzXML.Node)
    out = TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

function _parse(::Type{CriticalNetworkElement_MarketDocument}, n::EzXML.Node)
    out = CriticalNetworkElement_MarketDocument()
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
        elseif nm == "time_Period.timeInterval"
            out.time_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::CriticalNetworkElement_MarketDocument
    return _parse(CriticalNetworkElement_MarketDocument, root(parsexml(xml)))
end

end  # module Criticalbranch_v1_1
