# Auto-generated from iec62325-451-1-acknowledgement_v9_0.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-1:acknowledgementdocument:9:0

module Acknowledgement_v9_0

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

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct Time_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct MktActivityRecord
    mRID::String = ""
    InError_Period::Vector{Time_Period} = Time_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    version::Union{Nothing, String} = nothing
    InError_Period::Vector{Time_Period} = Time_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Series
    mRID::String = ""
    version::Union{Nothing, String} = nothing
    InError_Period::Vector{Time_Period} = Time_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Acknowledgement_MarketDocument
    mRID::String = ""
    createdDateTime::DateTime = DateTime(1970)
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    received_MarketDocument_mRID::Union{Nothing, String} = nothing
    received_MarketDocument_revisionNumber::Union{Nothing, String} = nothing
    received_MarketDocument_type::Union{Nothing, String} = nothing
    received_MarketDocument_process_processType::Union{Nothing, String} = nothing
    received_MarketDocument_title::Union{Nothing, String} = nothing
    received_MarketDocument_createdDateTime::Union{Nothing, DateTime} = nothing
    Rejected_TimeSeries::Vector{TimeSeries} = TimeSeries[]
    Reason::Vector{Reason} = Reason[]
    InError_Period::Vector{Time_Period} = Time_Period[]
    Rejected_Series::Vector{Series} = Series[]
    Rejected_MktActivityRecord::Vector{MktActivityRecord} = MktActivityRecord[]
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

function _parse(::Type{Time_Period}, n::EzXML.Node)
    out = Time_Period()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "timeInterval"
            out.timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

function _parse(::Type{MktActivityRecord}, n::EzXML.Node)
    out = MktActivityRecord()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "InError_Period"
            push!(out.InError_Period, _parse(Time_Period, c))
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

function _parse(::Type{TimeSeries}, n::EzXML.Node)
    out = TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "version"
            out.version = String(strip(nodecontent(c)))
        elseif nm == "InError_Period"
            push!(out.InError_Period, _parse(Time_Period, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

function _parse(::Type{Series}, n::EzXML.Node)
    out = Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "version"
            out.version = String(strip(nodecontent(c)))
        elseif nm == "InError_Period"
            push!(out.InError_Period, _parse(Time_Period, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

function _parse(::Type{Acknowledgement_MarketDocument}, n::EzXML.Node)
    out = Acknowledgement_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "createdDateTime"
            out.createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "sender_MarketParticipant.mRID"
            out.sender_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "sender_MarketParticipant.marketRole.type"
            out.sender_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "receiver_MarketParticipant.mRID"
            out.receiver_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "receiver_MarketParticipant.marketRole.type"
            out.receiver_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "received_MarketDocument.mRID"
            out.received_MarketDocument_mRID = String(strip(nodecontent(c)))
        elseif nm == "received_MarketDocument.revisionNumber"
            out.received_MarketDocument_revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "received_MarketDocument.type"
            out.received_MarketDocument_type = String(strip(nodecontent(c)))
        elseif nm == "received_MarketDocument.process.processType"
            out.received_MarketDocument_process_processType = String(strip(nodecontent(c)))
        elseif nm == "received_MarketDocument.title"
            out.received_MarketDocument_title = String(strip(nodecontent(c)))
        elseif nm == "received_MarketDocument.createdDateTime"
            out.received_MarketDocument_createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "Rejected_TimeSeries"
            push!(out.Rejected_TimeSeries, _parse(TimeSeries, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        elseif nm == "InError_Period"
            push!(out.InError_Period, _parse(Time_Period, c))
        elseif nm == "Rejected_Series"
            push!(out.Rejected_Series, _parse(Series, c))
        elseif nm == "Rejected_MktActivityRecord"
            push!(out.Rejected_MktActivityRecord, _parse(MktActivityRecord, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::Acknowledgement_MarketDocument
    return _parse(Acknowledgement_MarketDocument, root(parsexml(xml)))
end

end  # module Acknowledgement_v9_0
