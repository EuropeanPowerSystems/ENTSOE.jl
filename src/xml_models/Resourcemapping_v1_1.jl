# Auto-generated from iec62325-451-n-resourcemapping_v1_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:resourcemappingdocument:1:1

module Resourcemapping_v1_1

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

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    description::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    description::Union{Nothing, String} = nothing
    cancelledTS::Union{Nothing, String} = nothing
    start_DateAndOrTime_date::Date = Date(1970)
    start_DateAndOrTime_time::Union{Nothing, String} = nothing
    end_DateAndOrTime_date::Union{Nothing, Date} = nothing
    end_DateAndOrTime_time::Union{Nothing, String} = nothing
    market_RegisteredResource_mRID::ResourceID_String = ResourceID_String()
    market_RegisteredResource_name::Union{Nothing, String} = nothing
    market_RegisteredResource_description::Union{Nothing, String} = nothing
    RegisteredResource::Vector{RegisteredResource} = RegisteredResource[]
end

Base.@kwdef mutable struct ResourceMapping_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
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
        elseif nm == "description"
            out.description = String(strip(nodecontent(c)))
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
        elseif nm == "description"
            out.description = String(strip(nodecontent(c)))
        elseif nm == "cancelledTS"
            out.cancelledTS = String(strip(nodecontent(c)))
        elseif nm == "start_DateAndOrTime.date"
            out.start_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "start_DateAndOrTime.time"
            out.start_DateAndOrTime_time = String(strip(nodecontent(c)))
        elseif nm == "end_DateAndOrTime.date"
            out.end_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "end_DateAndOrTime.time"
            out.end_DateAndOrTime_time = String(strip(nodecontent(c)))
        elseif nm == "market_RegisteredResource.mRID"
            out.market_RegisteredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "market_RegisteredResource.name"
            out.market_RegisteredResource_name = String(strip(nodecontent(c)))
        elseif nm == "market_RegisteredResource.description"
            out.market_RegisteredResource_description = String(strip(nodecontent(c)))
        elseif nm == "RegisteredResource"
            push!(out.RegisteredResource, _parse(RegisteredResource, c))
        end
    end
    return out
end

function _parse(::Type{ResourceMapping_MarketDocument}, n::EzXML.Node)
    out = ResourceMapping_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "revisionNumber"
            out.revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "type"
            out.type_ = String(strip(nodecontent(c)))
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
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::ResourceMapping_MarketDocument
    return _parse(ResourceMapping_MarketDocument, root(parsexml(xml)))
end

end  # module Resourcemapping_v1_1
