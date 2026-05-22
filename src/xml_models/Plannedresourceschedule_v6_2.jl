# Auto-generated from iec62325-451-7-plannedresourceschedule_v6_2.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-7:plannedresourcescheduledocument:6:2

module Plannedresourceschedule_v6_2

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

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    quantity::Float64 = 0.0
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Series_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    resolution::String = ""
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct PlannedResource_TimeSeries
    mRID::String = ""
    businessType::String = ""
    flowDirection_direction::Union{Nothing, String} = nothing
    product::String = ""
    connecting_Domain_mRID::AreaID_String = AreaID_String()
    registeredResource_mRID::Union{Nothing, ResourceID_String} = nothing
    resourceProvider_MarketParticipant_mRID::PartyID_String = PartyID_String()
    acquiring_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    marketAgreement_type::Union{Nothing, String} = nothing
    marketAgreement_mRID::Union{Nothing, String} = nothing
    measurement_Unit_name::String = ""
    objectAggregation::Union{Nothing, String} = nothing
    mktPSRType_psrType::Union{Nothing, String} = nothing
    curveType::Union{Nothing, String} = nothing
    Series_Period::Vector{Series_Period} = Series_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct UnavailableReserve_TimeSeries
    mRID::String = ""
    businessType::String = ""
    flowDirection_direction::Union{Nothing, String} = nothing
    product::String = ""
    connecting_Domain_mRID::AreaID_String = AreaID_String()
    resourceProvider_MarketParticipant_mRID::PartyID_String = PartyID_String()
    substituteResourceProvider_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    acquiring_Domain_mRID::AreaID_String = AreaID_String()
    marketAgreement_type::Union{Nothing, String} = nothing
    marketAgreement_mRID::Union{Nothing, String} = nothing
    measurement_Unit_name::String = ""
    curveType::Union{Nothing, String} = nothing
    Series_Period::Vector{Series_Period} = Series_Period[]
end

Base.@kwdef mutable struct PlannedResourceSchedule_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    schedule_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    domain_mRID::Union{Nothing, AreaID_String} = nothing
    subject_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    subject_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    PlannedResource_TimeSeries::Vector{PlannedResource_TimeSeries} = PlannedResource_TimeSeries[]
    UnavailableReserves_TimeSeries::Vector{UnavailableReserve_TimeSeries} = UnavailableReserve_TimeSeries[]
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

function _parse(::Type{PlannedResource_TimeSeries}, n::EzXML.Node)
    out = PlannedResource_TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "flowDirection.direction"
            out.flowDirection_direction = String(strip(nodecontent(c)))
        elseif nm == "product"
            out.product = String(strip(nodecontent(c)))
        elseif nm == "connecting_Domain.mRID"
            out.connecting_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "registeredResource.mRID"
            out.registeredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "resourceProvider_MarketParticipant.mRID"
            out.resourceProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "acquiring_Domain.mRID"
            out.acquiring_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "marketAgreement.type"
            out.marketAgreement_type = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.mRID"
            out.marketAgreement_mRID = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "objectAggregation"
            out.objectAggregation = String(strip(nodecontent(c)))
        elseif nm == "mktPSRType.psrType"
            out.mktPSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "Series_Period"
            push!(out.Series_Period, _parse(Series_Period, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

function _parse(::Type{UnavailableReserve_TimeSeries}, n::EzXML.Node)
    out = UnavailableReserve_TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "flowDirection.direction"
            out.flowDirection_direction = String(strip(nodecontent(c)))
        elseif nm == "product"
            out.product = String(strip(nodecontent(c)))
        elseif nm == "connecting_Domain.mRID"
            out.connecting_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "resourceProvider_MarketParticipant.mRID"
            out.resourceProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "substituteResourceProvider_MarketParticipant.mRID"
            out.substituteResourceProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "acquiring_Domain.mRID"
            out.acquiring_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "marketAgreement.type"
            out.marketAgreement_type = String(strip(nodecontent(c)))
        elseif nm == "marketAgreement.mRID"
            out.marketAgreement_mRID = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "Series_Period"
            push!(out.Series_Period, _parse(Series_Period, c))
        end
    end
    return out
end

function _parse(::Type{PlannedResourceSchedule_MarketDocument}, n::EzXML.Node)
    out = PlannedResourceSchedule_MarketDocument()
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
        elseif nm == "schedule_Period.timeInterval"
            out.schedule_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "subject_MarketParticipant.mRID"
            out.subject_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "subject_MarketParticipant.marketRole.type"
            out.subject_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "PlannedResource_TimeSeries"
            push!(out.PlannedResource_TimeSeries, _parse(PlannedResource_TimeSeries, c))
        elseif nm == "UnavailableReserves_TimeSeries"
            push!(out.UnavailableReserves_TimeSeries, _parse(UnavailableReserve_TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::PlannedResourceSchedule_MarketDocument
    return _parse(PlannedResourceSchedule_MarketDocument, root(parsexml(xml)))
end

end  # module Plannedresourceschedule_v6_2
