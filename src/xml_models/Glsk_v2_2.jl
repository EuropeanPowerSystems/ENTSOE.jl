# Auto-generated from iec62325-451-n-glsk_v2_2.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:glskdocument:2:2

module Glsk_v2_2

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

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    sK_ResourceCapacity_defaultCapacity::Union{Nothing, Float64} = nothing
    resourceCapacity_maximumCapacity::Union{Nothing, Float64} = nothing
    resourceCapacity_minimumCapacity::Union{Nothing, Float64} = nothing
    marketObjectStatus_status::Union{Nothing, String} = nothing
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct SKBlock_TimeSeries
    businessType::String = ""
    mktPSRType_psrType::String = ""
    quantity_quantity::Union{Nothing, Float64} = nothing
    flowDirection_direction::Union{Nothing, String} = nothing
    measurement_Unit_name::Union{Nothing, String} = nothing
    attributeInstanceComponent_position::Union{Nothing, Int64} = nothing
    domain_mRID::Union{Nothing, AreaID_String} = nothing
    maximum_Quantity_quantity::Union{Nothing, Float64} = nothing
    maximum_Measurement_Unit_name::Union{Nothing, String} = nothing
    RegisteredResource::Vector{RegisteredResource} = RegisteredResource[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    SKBlock_TimeSeries::Vector{SKBlock_TimeSeries} = SKBlock_TimeSeries[]
    Reason::Vector{Reason} = Reason[]
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

Base.@kwdef mutable struct Action_Status
    value::String = ""
end

Base.@kwdef mutable struct TimeSeries
    mRID::Union{Nothing, String} = nothing
    name::Union{Nothing, String} = nothing
    subject_Domain_mRID::AreaID_String = AreaID_String()
    curveType::String = ""
    Period::Vector{Series_Period} = Series_Period[]
end

Base.@kwdef mutable struct GLSK_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::Union{Nothing, String} = nothing
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    docStatus::Union{Nothing, Action_Status} = nothing
    status::Union{Nothing, Action_Status} = nothing
    received_MarketDocument_mRID::Union{Nothing, String} = nothing
    received_MarketDocument_revisionNumber::Union{Nothing, String} = nothing
    time_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    domain_mRID::AreaID_String = AreaID_String()
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
    Reason::Vector{Reason} = Reason[]
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

function _parse(::Type{ResourceID_String}, n::EzXML.Node)
    out = ResourceID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
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
        elseif nm == "sK_ResourceCapacity.defaultCapacity"
            out.sK_ResourceCapacity_defaultCapacity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.maximumCapacity"
            out.resourceCapacity_maximumCapacity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.minimumCapacity"
            out.resourceCapacity_minimumCapacity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "marketObjectStatus.status"
            out.marketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
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

function _parse(::Type{SKBlock_TimeSeries}, n::EzXML.Node)
    out = SKBlock_TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "mktPSRType.psrType"
            out.mktPSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "quantity.quantity"
            out.quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "flowDirection.direction"
            out.flowDirection_direction = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "attributeInstanceComponent.position"
            out.attributeInstanceComponent_position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "maximum_Quantity.quantity"
            out.maximum_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "maximum_Measurement_Unit.name"
            out.maximum_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "RegisteredResource"
            push!(out.RegisteredResource, _parse(RegisteredResource, c))
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
        elseif nm == "SKBlock_TimeSeries"
            push!(out.SKBlock_TimeSeries, _parse(SKBlock_TimeSeries, c))
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

function _parse(::Type{TimeSeries}, n::EzXML.Node)
    out = TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "subject_Domain.mRID"
            out.subject_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        end
    end
    return out
end

function _parse(::Type{GLSK_MarketDocument}, n::EzXML.Node)
    out = GLSK_MarketDocument()
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
        elseif nm == "status"
            out.status = _parse(Action_Status, c)
        elseif nm == "received_MarketDocument.mRID"
            out.received_MarketDocument_mRID = String(strip(nodecontent(c)))
        elseif nm == "received_MarketDocument.revisionNumber"
            out.received_MarketDocument_revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "time_Period.timeInterval"
            out.time_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::GLSK_MarketDocument
    return _parse(GLSK_MarketDocument, root(parsexml(xml)))
end

end  # module Glsk_v2_2
