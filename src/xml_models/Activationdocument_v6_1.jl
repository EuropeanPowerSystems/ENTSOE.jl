# Auto-generated from iec62325-451-7-activationdocument_v6_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-7:activationdocument:6:1

module Activationdocument_v6_1

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

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    quantity::Float64 = 0.0
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
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
    resourceProvider_MarketParticipant_mRID::PartyID_String = PartyID_String()
    businessType::String = ""
    acquiring_Domain_mRID::AreaID_String = AreaID_String()
    connecting_Domain_mRID::AreaID_String = AreaID_String()
    measurement_Unit_name::String = ""
    flowDirection_direction::String = ""
    marketObjectStatus_status::String = ""
    registeredResource_mRID::Union{Nothing, ResourceID_String} = nothing
    Period::Vector{Series_Period} = Series_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Activation_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::Union{Nothing, String} = nothing
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    activation_Time_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    domain_mRID::Union{Nothing, AreaID_String} = nothing
    subject_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    subject_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    order_MarketDocument_mRID::Union{Nothing, String} = nothing
    order_MarketDocument_revisionNumber::Union{Nothing, String} = nothing
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

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
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
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
        elseif nm == "resourceProvider_MarketParticipant.mRID"
            out.resourceProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "acquiring_Domain.mRID"
            out.acquiring_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "connecting_Domain.mRID"
            out.connecting_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "flowDirection.direction"
            out.flowDirection_direction = String(strip(nodecontent(c)))
        elseif nm == "marketObjectStatus.status"
            out.marketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "registeredResource.mRID"
            out.registeredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

function _parse(::Type{Activation_MarketDocument}, n::EzXML.Node)
    out = Activation_MarketDocument()
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
        elseif nm == "activation_Time_Period.timeInterval"
            out.activation_Time_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "subject_MarketParticipant.mRID"
            out.subject_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "subject_MarketParticipant.marketRole.type"
            out.subject_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "order_MarketDocument.mRID"
            out.order_MarketDocument_mRID = String(strip(nodecontent(c)))
        elseif nm == "order_MarketDocument.revisionNumber"
            out.order_MarketDocument_revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::Activation_MarketDocument
    return _parse(Activation_MarketDocument, root(parsexml(xml)))
end

end  # module Activationdocument_v6_1
