# Auto-generated from iec62325-451-n-measurementdatadocument_v_1_0.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:measurementdatadocument:1:0

module Measurementdatadocument_v_1_0

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

Base.@kwdef mutable struct MeasurementData_MarketDocument
    mRID::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::String = ""
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::String = ""
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::String = ""
    period_timeInterval::String = ""
    TimeSeries::Vector{String} = String[]
end

Base.@kwdef mutable struct Point
    position::String = ""
    quantity::Float64 = 0.0
    quality::String = ""
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    businessType::String = ""
    product::String = ""
    reading_Period_timeInterval::Union{Nothing, String} = nothing
    accountingPointParty_MarketParticipant_mRID::Union{Nothing, String} = nothing
    accountingPointParty_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    measurement_Unit_name::Union{Nothing, String} = nothing
    AccountingPoint::Vector{String} = String[]
    domain_mRID::Union{Nothing, String} = nothing
    Period::Vector{String} = String[]
end

Base.@kwdef mutable struct AccountingPoint
    mRID::Union{Nothing, String} = nothing
    flowCommodityOption::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Series_Period
    resolution::String = ""
    timeInterval::String = ""
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

function _parse(::Type{MeasurementData_MarketDocument}, n::EzXML.Node)
    out = MeasurementData_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "type"
            out.type_ = String(strip(nodecontent(c)))
        elseif nm == "process.processType"
            out.process_processType = String(strip(nodecontent(c)))
        elseif nm == "sender_MarketParticipant.mRID"
            out.sender_MarketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "sender_MarketParticipant.marketRole.type"
            out.sender_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "receiver_MarketParticipant.mRID"
            out.receiver_MarketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "receiver_MarketParticipant.marketRole.type"
            out.receiver_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "createdDateTime"
            out.createdDateTime = String(strip(nodecontent(c)))
        elseif nm == "period.timeInterval"
            out.period_timeInterval = String(strip(nodecontent(c)))
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, String(strip(nodecontent(c))))
        end
    end
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
        elseif nm == "quality"
            out.quality = String(strip(nodecontent(c)))
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

function _parse(::Type{TimeSeries}, n::EzXML.Node)
    out = TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "product"
            out.product = String(strip(nodecontent(c)))
        elseif nm == "reading_Period.timeInterval"
            out.reading_Period_timeInterval = String(strip(nodecontent(c)))
        elseif nm == "accountingPointParty_MarketParticipant.mRID"
            out.accountingPointParty_MarketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "accountingPointParty_MarketParticipant.marketRole.type"
            out.accountingPointParty_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "AccountingPoint"
            push!(out.AccountingPoint, String(strip(nodecontent(c))))
        elseif nm == "domain.mRID"
            out.domain_mRID = String(strip(nodecontent(c)))
        elseif nm == "Period"
            push!(out.Period, String(strip(nodecontent(c))))
        end
    end
    return out
end

function _parse(::Type{AccountingPoint}, n::EzXML.Node)
    out = AccountingPoint()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "flowCommodityOption"
            out.flowCommodityOption = String(strip(nodecontent(c)))
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
        if nm == "resolution"
            out.resolution = String(strip(nodecontent(c)))
        elseif nm == "timeInterval"
            out.timeInterval = String(strip(nodecontent(c)))
        elseif nm == "Point"
            push!(out.Point, String(strip(nodecontent(c))))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::MeasurementData_MarketDocument
    return _parse(MeasurementData_MarketDocument, root(parsexml(xml)))
end

end  # module Measurementdatadocument_v_1_0
