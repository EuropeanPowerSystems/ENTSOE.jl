# Auto-generated from iec62325-451-n-measurementdatadocument_v_1_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:measurementdatadocument:1:1

module Measurementdatadocument_v_1_1

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

Base.@kwdef mutable struct Point
    position::Int64 = 0
    quantity::Float64 = 0.0
    quality::Union{Nothing, String} = nothing
    delta_Quantity_quantity::Union{Nothing, Float64} = nothing
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Series_Period
    resolution::String = ""
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct MarketParticipant
    mRID::PartyID_String = PartyID_String()
    marketRole_type::String = ""
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
end

Base.@kwdef mutable struct MeasurementPointID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ExchangePoint
    mRID::Union{Nothing, MeasurementPointID_String} = nothing
end

Base.@kwdef mutable struct AccountingPoint
    mRID::Union{Nothing, MeasurementPointID_String} = nothing
    flowCommodityOption::Union{Nothing, String} = nothing
    connectionCategory::Union{Nothing, String} = nothing
    usagePointLocation_geoInfoReference::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Reading
    position::Union{Nothing, Int64} = nothing
    value::Union{Nothing, Float64} = nothing
    timeStamp::Union{Nothing, DateTime} = nothing
    touTierName::Union{Nothing, String} = nothing
    valueMissing::Union{Nothing, Bool} = nothing
end

Base.@kwdef mutable struct MeterReading
    mRID::Union{Nothing, ResourceID_String} = nothing
    Readings::Vector{Reading} = Reading[]
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    original_MarketDocument_mRID::Union{Nothing, String} = nothing
    originalTransaction_Series_mRID::Union{Nothing, String} = nothing
    businessType::String = ""
    objectAggregation::Union{Nothing, String} = nothing
    product::String = ""
    AccountingPoint::Vector{AccountingPoint} = AccountingPoint[]
    ExchangePoint::Vector{ExchangePoint} = ExchangePoint[]
    domain_mRID::Union{Nothing, AreaID_String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    marketAgreement_mRID::Union{Nothing, String} = nothing
    marketAgreement_type::Union{Nothing, String} = nothing
    AccountingPointParty_MarketParticipant::Vector{MarketParticipant} = MarketParticipant[]
    RegisteredResource::Vector{RegisteredResource} = RegisteredResource[]
    registration_DateAndOrTime_dateTime::Union{Nothing, DateTime} = nothing
    flowDirection_direction::Union{Nothing, String} = nothing
    measurement_Unit_name::Union{Nothing, String} = nothing
    curveType::String = ""
    Period::Vector{Series_Period} = Series_Period[]
    MeterReading::Vector{MeterReading} = MeterReading[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Time_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
end

Base.@kwdef mutable struct MeasurementData_MarketDocument
    mRID::String = ""
    revisionNumber::Union{Nothing, String} = nothing
    type_::String = ""
    process_processType::String = ""
    Sender_MarketParticipant::MarketParticipant = MarketParticipant()
    Receiver_MarketParticipant::MarketParticipant = MarketParticipant()
    createdDateTime::DateTime = DateTime(1970)
    domain_mRID::Union{Nothing, AreaID_String} = nothing
    Period::Time_Period = Time_Period()
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
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

function _parse(::Type{Point}, n::EzXML.Node)
    out = Point()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "position"
            out.position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "quantity"
            out.quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "quality"
            out.quality = String(strip(nodecontent(c)))
        elseif nm == "delta_Quantity.quantity"
            out.delta_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
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
        if nm == "resolution"
            out.resolution = String(strip(nodecontent(c)))
        elseif nm == "timeInterval"
            out.timeInterval = _parse(ESMP_DateTimeInterval, c)
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

function _parse(::Type{MarketParticipant}, n::EzXML.Node)
    out = MarketParticipant()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(PartyID_String, c)
        elseif nm == "marketRole.type"
            out.marketRole_type = String(strip(nodecontent(c)))
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

function _parse(::Type{ExchangePoint}, n::EzXML.Node)
    out = ExchangePoint()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(MeasurementPointID_String, c)
        end
    end
    return out
end

function _parse(::Type{AccountingPoint}, n::EzXML.Node)
    out = AccountingPoint()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(MeasurementPointID_String, c)
        elseif nm == "flowCommodityOption"
            out.flowCommodityOption = String(strip(nodecontent(c)))
        elseif nm == "connectionCategory"
            out.connectionCategory = String(strip(nodecontent(c)))
        elseif nm == "usagePointLocation.geoInfoReference"
            out.usagePointLocation_geoInfoReference = String(strip(nodecontent(c)))
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

function _parse(::Type{Reading}, n::EzXML.Node)
    out = Reading()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "position"
            out.position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "value"
            out.value = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "timeStamp"
            out.timeStamp = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "touTierName"
            out.touTierName = String(strip(nodecontent(c)))
        elseif nm == "valueMissing"
            out.valueMissing = (x -> parse(Bool, x))(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{MeterReading}, n::EzXML.Node)
    out = MeterReading()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "Readings"
            push!(out.Readings, _parse(Reading, c))
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
        elseif nm == "original_MarketDocument.mRID"
            out.original_MarketDocument_mRID = String(strip(nodecontent(c)))
        elseif nm == "originalTransaction_Series.mRID"
            out.originalTransaction_Series_mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "objectAggregation"
            out.objectAggregation = String(strip(nodecontent(c)))
        elseif nm == "product"
            out.product = String(strip(nodecontent(c)))
        elseif nm == "AccountingPoint"
            push!(out.AccountingPoint, _parse(AccountingPoint, c))
        elseif nm == "ExchangePoint"
            push!(out.ExchangePoint, _parse(ExchangePoint, c))
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "marketAgreement.mRID"
            out.marketAgreement_mRID = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.type"
            out.marketAgreement_type = String(strip(nodecontent(c)))
        elseif nm == "AccountingPointParty_MarketParticipant"
            push!(out.AccountingPointParty_MarketParticipant, _parse(MarketParticipant, c))
        elseif nm == "RegisteredResource"
            push!(out.RegisteredResource, _parse(RegisteredResource, c))
        elseif nm == "registration_DateAndOrTime.dateTime"
            out.registration_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "flowDirection.direction"
            out.flowDirection_direction = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        elseif nm == "MeterReading"
            push!(out.MeterReading, _parse(MeterReading, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
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
        end
    end
    return out
end

function _parse(::Type{MeasurementData_MarketDocument}, n::EzXML.Node)
    out = MeasurementData_MarketDocument()
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
        elseif nm == "Sender_MarketParticipant"
            out.Sender_MarketParticipant = _parse(MarketParticipant, c)
        elseif nm == "Receiver_MarketParticipant"
            out.Receiver_MarketParticipant = _parse(MarketParticipant, c)
        elseif nm == "createdDateTime"
            out.createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "Period"
            out.Period = _parse(Time_Period, c)
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::MeasurementData_MarketDocument
    return _parse(MeasurementData_MarketDocument, root(parsexml(xml)))
end

end  # module Measurementdatadocument_v_1_1
