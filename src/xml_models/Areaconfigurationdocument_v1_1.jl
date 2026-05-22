# Auto-generated from iec62325-451-n-areaconfigurationdocument_v1_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:areaconfigurationdocument:1:1

module Areaconfigurationdocument_v1_1

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

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ConsistOf_Domain
    mRID::AreaID_String = AreaID_String()
    name::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Connected_Domain
    mRID::AreaID_String = AreaID_String()
    name::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ConnectionDetail_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    areaIdentification_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    componentType_MktPSRType_psrType::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct BorderConnection_Series
    mRID::Union{Nothing, String} = nothing
    borderConnection_RegisteredResource_mRID::ResourceID_String = ResourceID_String()
    borderComponentType_MktPSRType_psrType::String = ""
    ConnectionDetail_RegisteredResource::Vector{ConnectionDetail_RegisteredResource} = ConnectionDetail_RegisteredResource[]
end

Base.@kwdef mutable struct AreaSpecification_Series
    mRID::String = ""
    marketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    marketParticipant_marketRole_type::Union{Nothing, String} = nothing
    area_Domain_mRID::AreaID_String = AreaID_String()
    area_Domain_name::Union{Nothing, String} = nothing
    objectAggregation::Union{Nothing, String} = nothing
    country_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    areaCharacteristics_Domain_name::Union{Nothing, String} = nothing
    validityStart_DateAndOrTime_dateTime::DateTime = DateTime(1970)
    validityEnd_DateAndOrTime_dateTime::Union{Nothing, DateTime} = nothing
    ConsistOf_Domain::Vector{ConsistOf_Domain} = ConsistOf_Domain[]
    Connected_Domain::Vector{Connected_Domain} = Connected_Domain[]
    BorderConnection_Series::Vector{BorderConnection_Series} = BorderConnection_Series[]
    AreaConnectionDetail_RegisteredResource::Vector{ConnectionDetail_RegisteredResource} = ConnectionDetail_RegisteredResource[]
end

Base.@kwdef mutable struct AreaConfiguration_MarketDocument
    mRID::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    AreaSpecification_Series::Vector{AreaSpecification_Series} = AreaSpecification_Series[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

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

function _parse(::Type{ConsistOf_Domain}, n::EzXML.Node)
    out = ConsistOf_Domain()
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

function _parse(::Type{Connected_Domain}, n::EzXML.Node)
    out = Connected_Domain()
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

function _parse(::Type{ResourceID_String}, n::EzXML.Node)
    out = ResourceID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{ConnectionDetail_RegisteredResource}, n::EzXML.Node)
    out = ConnectionDetail_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "areaIdentification_Domain.mRID"
            out.areaIdentification_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "componentType_MktPSRType.psrType"
            out.componentType_MktPSRType_psrType = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{BorderConnection_Series}, n::EzXML.Node)
    out = BorderConnection_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "borderConnection_RegisteredResource.mRID"
            out.borderConnection_RegisteredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "borderComponentType_MktPSRType.psrType"
            out.borderComponentType_MktPSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "ConnectionDetail_RegisteredResource"
            push!(out.ConnectionDetail_RegisteredResource, _parse(ConnectionDetail_RegisteredResource, c))
        end
    end
    return out
end

function _parse(::Type{AreaSpecification_Series}, n::EzXML.Node)
    out = AreaSpecification_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "marketParticipant.mRID"
            out.marketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "marketParticipant.marketRole.type"
            out.marketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "area_Domain.mRID"
            out.area_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "area_Domain.name"
            out.area_Domain_name = String(strip(nodecontent(c)))
        elseif nm == "objectAggregation"
            out.objectAggregation = String(strip(nodecontent(c)))
        elseif nm == "country_Domain.mRID"
            out.country_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "areaCharacteristics_Domain.name"
            out.areaCharacteristics_Domain_name = String(strip(nodecontent(c)))
        elseif nm == "validityStart_DateAndOrTime.dateTime"
            out.validityStart_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "validityEnd_DateAndOrTime.dateTime"
            out.validityEnd_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "ConsistOf_Domain"
            push!(out.ConsistOf_Domain, _parse(ConsistOf_Domain, c))
        elseif nm == "Connected_Domain"
            push!(out.Connected_Domain, _parse(Connected_Domain, c))
        elseif nm == "BorderConnection_Series"
            push!(out.BorderConnection_Series, _parse(BorderConnection_Series, c))
        elseif nm == "AreaConnectionDetail_RegisteredResource"
            push!(out.AreaConnectionDetail_RegisteredResource, _parse(ConnectionDetail_RegisteredResource, c))
        end
    end
    return out
end

function _parse(::Type{AreaConfiguration_MarketDocument}, n::EzXML.Node)
    out = AreaConfiguration_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
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
        elseif nm == "AreaSpecification_Series"
            push!(out.AreaSpecification_Series, _parse(AreaSpecification_Series, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::AreaConfiguration_MarketDocument
    return _parse(AreaConfiguration_MarketDocument, root(parsexml(xml)))
end

end  # module Areaconfigurationdocument_v1_1
