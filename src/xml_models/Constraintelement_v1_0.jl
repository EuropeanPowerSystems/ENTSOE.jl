# Auto-generated from iec62325-451-n-constraintelement_v1_0.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:constraintnetworkelementdocument:1:0

module Constraintelement_v1_0

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

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Domain
    mRID::AreaID_String = AreaID_String()
end

Base.@kwdef mutable struct Outage_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    Out_Domain::Union{Nothing, Domain} = nothing
    In_Domain::Union{Nothing, Domain} = nothing
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Party_MarketParticipant
    mRID::PartyID_String = PartyID_String()
end

Base.@kwdef mutable struct ExternalConstraint_Series
    mRID::String = ""
    businessType::String = ""
    name::Union{Nothing, String} = nothing
    measurement_Unit_name::String = ""
    in_Domain_mRID::AreaID_String = AreaID_String()
    out_Domain_mRID::AreaID_String = AreaID_String()
    quantity_quantity::Float64 = 0.0
    quantity_quality::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct MeasurementPointID_String
    value::String = ""
    codingScheme::String = ""
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
    Measurements::Vector{Analog} = Analog[]
    In_Domain::Union{Nothing, Domain} = nothing
    Out_Domain::Union{Nothing, Domain} = nothing
    in_AggregateNode_mRID::Union{Nothing, MeasurementPointID_String} = nothing
    out_AggregateNode_mRID::Union{Nothing, MeasurementPointID_String} = nothing
end

Base.@kwdef mutable struct RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    pSRType_psrType::String = ""
    In_Domain::Union{Nothing, Domain} = nothing
    Out_Domain::Union{Nothing, Domain} = nothing
    Shared_Domain::Vector{Domain} = Domain[]
    marketObjectStatus_status::String = ""
    resourceCapacity_capacityType::Union{Nothing, String} = nothing
    resourceCapacity_maximumCapacity::Union{Nothing, Float32} = nothing
    resourceCapacity_minimumCapacity::Union{Nothing, Float32} = nothing
    resourceCapacity_defaultCapacity::Union{Nothing, Float32} = nothing
end

Base.@kwdef mutable struct RemedialAction_Series
    mRID::String = ""
    name::Union{Nothing, String} = nothing
    In_Domain::Union{Nothing, Domain} = nothing
    Out_Domain::Union{Nothing, Domain} = nothing
    quantity_quantity::Union{Nothing, Float64} = nothing
    quantity_quality::Union{Nothing, String} = nothing
    applicationMode_MarketObjectStatus_status::String = ""
    RegisteredResource::Vector{RegisteredResource} = RegisteredResource[]
end

Base.@kwdef mutable struct Constraint_Series
    mRID::String = ""
    businessType::String = ""
    name::Union{Nothing, String} = nothing
    Party_MarketParticipant::Vector{Party_MarketParticipant} = Party_MarketParticipant[]
    ExternalConstraint_Series::Vector{ExternalConstraint_Series} = ExternalConstraint_Series[]
    Outage_RegisteredResource::Vector{Outage_RegisteredResource} = Outage_RegisteredResource[]
    Monitored_RegisteredResource::Vector{Monitored_RegisteredResource} = Monitored_RegisteredResource[]
    RemedialAction_Series::Vector{RemedialAction_Series} = RemedialAction_Series[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    Constraint_TimeSeries::Vector{Constraint_Series} = Constraint_Series[]
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
    In_Domain::Union{Nothing, Domain} = nothing
    Out_Domain::Union{Nothing, Domain} = nothing
    curveType::String = ""
    Period::Vector{Series_Period} = Series_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct ConstraintNetworkElement_MarketDocument
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
    Domain::Union{Nothing, Domain} = nothing
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

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

function _parse(::Type{Domain}, n::EzXML.Node)
    out = Domain()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(AreaID_String, c)
        end
    end
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
        elseif nm == "Out_Domain"
            out.Out_Domain = _parse(Domain, c)
        elseif nm == "In_Domain"
            out.In_Domain = _parse(Domain, c)
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

function _parse(::Type{ExternalConstraint_Series}, n::EzXML.Node)
    out = ExternalConstraint_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "quantity.quantity"
            out.quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "quantity.quality"
            out.quantity_quality = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{MeasurementPointID_String}, n::EzXML.Node)
    out = MeasurementPointID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
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
        elseif nm == "Measurements"
            push!(out.Measurements, _parse(Analog, c))
        elseif nm == "In_Domain"
            out.In_Domain = _parse(Domain, c)
        elseif nm == "Out_Domain"
            out.Out_Domain = _parse(Domain, c)
        elseif nm == "in_AggregateNode.mRID"
            out.in_AggregateNode_mRID = _parse(MeasurementPointID_String, c)
        elseif nm == "out_AggregateNode.mRID"
            out.out_AggregateNode_mRID = _parse(MeasurementPointID_String, c)
        end
    end
    return out
end

function _parse(::Type{RegisteredResource}, n::EzXML.Node)
    out = RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "pSRType.psrType"
            out.pSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "In_Domain"
            out.In_Domain = _parse(Domain, c)
        elseif nm == "Out_Domain"
            out.Out_Domain = _parse(Domain, c)
        elseif nm == "Shared_Domain"
            push!(out.Shared_Domain, _parse(Domain, c))
        elseif nm == "marketObjectStatus.status"
            out.marketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.capacityType"
            out.resourceCapacity_capacityType = String(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.maximumCapacity"
            out.resourceCapacity_maximumCapacity = (x -> parse(Float32, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.minimumCapacity"
            out.resourceCapacity_minimumCapacity = (x -> parse(Float32, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.defaultCapacity"
            out.resourceCapacity_defaultCapacity = (x -> parse(Float32, x))(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{RemedialAction_Series}, n::EzXML.Node)
    out = RemedialAction_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "In_Domain"
            out.In_Domain = _parse(Domain, c)
        elseif nm == "Out_Domain"
            out.Out_Domain = _parse(Domain, c)
        elseif nm == "quantity.quantity"
            out.quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "quantity.quality"
            out.quantity_quality = String(strip(nodecontent(c)))
        elseif nm == "applicationMode_MarketObjectStatus.status"
            out.applicationMode_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "RegisteredResource"
            push!(out.RegisteredResource, _parse(RegisteredResource, c))
        end
    end
    return out
end

function _parse(::Type{Constraint_Series}, n::EzXML.Node)
    out = Constraint_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "Party_MarketParticipant"
            push!(out.Party_MarketParticipant, _parse(Party_MarketParticipant, c))
        elseif nm == "ExternalConstraint_Series"
            push!(out.ExternalConstraint_Series, _parse(ExternalConstraint_Series, c))
        elseif nm == "Outage_RegisteredResource"
            push!(out.Outage_RegisteredResource, _parse(Outage_RegisteredResource, c))
        elseif nm == "Monitored_RegisteredResource"
            push!(out.Monitored_RegisteredResource, _parse(Monitored_RegisteredResource, c))
        elseif nm == "RemedialAction_Series"
            push!(out.RemedialAction_Series, _parse(RemedialAction_Series, c))
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
            push!(out.Constraint_TimeSeries, _parse(Constraint_Series, c))
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
        elseif nm == "In_Domain"
            out.In_Domain = _parse(Domain, c)
        elseif nm == "Out_Domain"
            out.Out_Domain = _parse(Domain, c)
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

function _parse(::Type{ConstraintNetworkElement_MarketDocument}, n::EzXML.Node)
    out = ConstraintNetworkElement_MarketDocument()
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
        elseif nm == "Domain"
            out.Domain = _parse(Domain, c)
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::ConstraintNetworkElement_MarketDocument
    return _parse(ConstraintNetworkElement_MarketDocument, root(parsexml(xml)))
end

end  # module Constraintelement_v1_0
