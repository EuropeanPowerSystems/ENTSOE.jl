# Auto-generated from iec62325-451-2-anomaly_v5_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-2:anomalydocument:5:1

module Anomaly_v5_1

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

Base.@kwdef mutable struct Point
    position::String = ""
    quantity::Float64 = 0.0
    Reason::Vector{String} = String[]
end

Base.@kwdef mutable struct Anomaly_TimeSeries
    mRID::String = ""
    version::String = ""
    businessType::String = ""
    product::String = ""
    objectAggregation::String = ""
    in_Domain_mRID::Union{Nothing, String} = nothing
    out_Domain_mRID::Union{Nothing, String} = nothing
    marketEvaluationPoint_mRID::Union{Nothing, String} = nothing
    in_MarketParticipant_mRID::Union{Nothing, String} = nothing
    out_MarketParticipant_mRID::Union{Nothing, String} = nothing
    marketAgreement_type::Union{Nothing, String} = nothing
    marketAgreement_mRID::Union{Nothing, String} = nothing
    measurement_Unit_name::String = ""
    curveType::Union{Nothing, String} = nothing
    Period::Vector{String} = String[]
    Reason::Vector{String} = String[]
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct Original_MarketDocument
    marketParticipant_mRID::String = ""
    mRID::String = ""
    revisionNumber::String = ""
    TimeSeries::String = ""
end

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AnomalyReport_MarketDocument
    mRID::String = ""
    createdDateTime::String = ""
    sender_MarketParticipant_mRID::String = ""
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::String = ""
    receiver_MarketParticipant_marketRole_type::String = ""
    schedule_Time_Period_timeInterval::String = ""
    domain_mRID::String = ""
    Anomaly_MarketDocument::Vector{String} = String[]
end

Base.@kwdef mutable struct Series_Period
    timeInterval::String = ""
    resolution::String = ""
    Point::Vector{String} = String[]
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

function _parse(::Type{Point}, n::EzXML.Node)
    out = Point()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "position"
            out.position = String(strip(nodecontent(c)))
        elseif nm == "quantity"
            out.quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "Reason"
            push!(out.Reason, String(strip(nodecontent(c))))
        end
    end
    return out
end

function _parse(::Type{Anomaly_TimeSeries}, n::EzXML.Node)
    out = Anomaly_TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "version"
            out.version = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "product"
            out.product = String(strip(nodecontent(c)))
        elseif nm == "objectAggregation"
            out.objectAggregation = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = String(strip(nodecontent(c)))
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = String(strip(nodecontent(c)))
        elseif nm == "marketEvaluationPoint.mRID"
            out.marketEvaluationPoint_mRID = String(strip(nodecontent(c)))
        elseif nm == "in_MarketParticipant.mRID"
            out.in_MarketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "out_MarketParticipant.mRID"
            out.out_MarketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.type"
            out.marketAgreement_type = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.mRID"
            out.marketAgreement_mRID = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "Period"
            push!(out.Period, String(strip(nodecontent(c))))
        elseif nm == "Reason"
            push!(out.Reason, String(strip(nodecontent(c))))
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

function _parse(::Type{Original_MarketDocument}, n::EzXML.Node)
    out = Original_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "marketParticipant.mRID"
            out.marketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "revisionNumber"
            out.revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "TimeSeries"
            out.TimeSeries = String(strip(nodecontent(c)))
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

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{AnomalyReport_MarketDocument}, n::EzXML.Node)
    out = AnomalyReport_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "createdDateTime"
            out.createdDateTime = String(strip(nodecontent(c)))
        elseif nm == "sender_MarketParticipant.mRID"
            out.sender_MarketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "sender_MarketParticipant.marketRole.type"
            out.sender_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "receiver_MarketParticipant.mRID"
            out.receiver_MarketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "receiver_MarketParticipant.marketRole.type"
            out.receiver_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "schedule_Time_Period.timeInterval"
            out.schedule_Time_Period_timeInterval = String(strip(nodecontent(c)))
        elseif nm == "domain.mRID"
            out.domain_mRID = String(strip(nodecontent(c)))
        elseif nm == "Anomaly_MarketDocument"
            push!(out.Anomaly_MarketDocument, String(strip(nodecontent(c))))
        end
    end
    return out
end

function _parse(::Type{Series_Period}, n::EzXML.Node)
    out = Series_Period()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "timeInterval"
            out.timeInterval = String(strip(nodecontent(c)))
        elseif nm == "resolution"
            out.resolution = String(strip(nodecontent(c)))
        elseif nm == "Point"
            push!(out.Point, String(strip(nodecontent(c))))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::AnomalyReport_MarketDocument
    return _parse(AnomalyReport_MarketDocument, root(parsexml(xml)))
end

end  # module Anomaly_v5_1
