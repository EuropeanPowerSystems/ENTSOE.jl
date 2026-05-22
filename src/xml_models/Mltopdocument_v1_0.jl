# Auto-generated from iec62325-451-n-mltopdocument_v1_0.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:mltopdocument:1:0

module Mltopdocument_v1_0

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

Base.@kwdef mutable struct ESMP_Voltage
    value::String = ""
    unit::String = ""
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::String = ""
    pSRType_psrType::Union{Nothing, String} = nothing
    pSRType_powerSystemResources_highVoltageLimit::Union{Nothing, ESMP_Voltage} = nothing
    pSRType_powerSystemResources_lowVoltageLimit::Union{Nothing, ESMP_Voltage} = nothing
end

Base.@kwdef mutable struct Alternative_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
end

Base.@kwdef mutable struct SwitchedBack_Time_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    description::Union{Nothing, String} = nothing
    businessType::String = ""
    project_Names_name::Union{Nothing, String} = nothing
    caseReference_Names_name::Union{Nothing, String} = nothing
    outage_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    lastChange_MarketAgreement_createdDateTime::DateTime = DateTime(1970)
    positiveOffset_ConstraintDuration_duration::Union{Nothing, String} = nothing
    negativeOffset_ConstraintDuration_duration::Union{Nothing, String} = nothing
    noRestitution_ConstraintDuration_type::Union{Nothing, String} = nothing
    maximumRestitution_ConstraintDuration_duration::Union{Nothing, String} = nothing
    dayTimeRestitution_ConstraintDuration_duration::Union{Nothing, String} = nothing
    nightTimeRestitution_ConstraintDuration_duration::Union{Nothing, String} = nothing
    weekEndRestitution_ConstraintDuration_duration::Union{Nothing, String} = nothing
    marketObjectStatus_status::String = ""
    coordination_MarketObjectStatus_status::Union{Nothing, String} = nothing
    measurement_Unit_name::Union{Nothing, String} = nothing
    unavailableCapacity_Quantity_quantity::Union{Nothing, Float64} = nothing
    day_MarketObjectStatus_status::String = ""
    week_MarketObjectStatus_status::Union{Nothing, String} = nothing
    saturday_MarketObjectStatus_status::Union{Nothing, String} = nothing
    sunday_MarketObjectStatus_status::Union{Nothing, String} = nothing
    Reason::Vector{Reason} = Reason[]
    RegisteredResource::Vector{RegisteredResource} = RegisteredResource[]
    Alternative_RegisteredResource::Vector{Alternative_RegisteredResource} = Alternative_RegisteredResource[]
    SwitchedBack_Period::Vector{SwitchedBack_Time_Period} = SwitchedBack_Time_Period[]
end

Base.@kwdef mutable struct OutageSchedule_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    schedule_Period_timeInterval::Union{Nothing, ESMP_DateTimeInterval} = nothing
    domain_mRID::AreaID_String = AreaID_String()
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

function _parse(::Type{ESMP_Voltage}, n::EzXML.Node)
    out = ESMP_Voltage()
    if hasattribute(n, "unit")
        out.unit = String(n["unit"])
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

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
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
        elseif nm == "pSRType.powerSystemResources.highVoltageLimit"
            out.pSRType_powerSystemResources_highVoltageLimit = _parse(ESMP_Voltage, c)
        elseif nm == "pSRType.powerSystemResources.lowVoltageLimit"
            out.pSRType_powerSystemResources_lowVoltageLimit = _parse(ESMP_Voltage, c)
        end
    end
    return out
end

function _parse(::Type{Alternative_RegisteredResource}, n::EzXML.Node)
    out = Alternative_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        end
    end
    return out
end

function _parse(::Type{SwitchedBack_Time_Period}, n::EzXML.Node)
    out = SwitchedBack_Time_Period()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "timeInterval"
            out.timeInterval = _parse(ESMP_DateTimeInterval, c)
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
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "project_Names.name"
            out.project_Names_name = String(strip(nodecontent(c)))
        elseif nm == "caseReference_Names.name"
            out.caseReference_Names_name = String(strip(nodecontent(c)))
        elseif nm == "outage_Period.timeInterval"
            out.outage_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "lastChange_MarketAgreement.createdDateTime"
            out.lastChange_MarketAgreement_createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "positiveOffset_ConstraintDuration.duration"
            out.positiveOffset_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "negativeOffset_ConstraintDuration.duration"
            out.negativeOffset_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "noRestitution_ConstraintDuration.type"
            out.noRestitution_ConstraintDuration_type = String(strip(nodecontent(c)))
        elseif nm == "maximumRestitution_ConstraintDuration.duration"
            out.maximumRestitution_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "dayTimeRestitution_ConstraintDuration.duration"
            out.dayTimeRestitution_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "nightTimeRestitution_ConstraintDuration.duration"
            out.nightTimeRestitution_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "weekEndRestitution_ConstraintDuration.duration"
            out.weekEndRestitution_ConstraintDuration_duration = String(strip(nodecontent(c)))
        elseif nm == "marketObjectStatus.status"
            out.marketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "coordination_MarketObjectStatus.status"
            out.coordination_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "unavailableCapacity_Quantity.quantity"
            out.unavailableCapacity_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "day_MarketObjectStatus.status"
            out.day_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "week_MarketObjectStatus.status"
            out.week_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "saturday_MarketObjectStatus.status"
            out.saturday_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "sunday_MarketObjectStatus.status"
            out.sunday_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        elseif nm == "RegisteredResource"
            push!(out.RegisteredResource, _parse(RegisteredResource, c))
        elseif nm == "Alternative_RegisteredResource"
            push!(out.Alternative_RegisteredResource, _parse(Alternative_RegisteredResource, c))
        elseif nm == "SwitchedBack_Period"
            push!(out.SwitchedBack_Period, _parse(SwitchedBack_Time_Period, c))
        end
    end
    return out
end

function _parse(::Type{OutageSchedule_MarketDocument}, n::EzXML.Node)
    out = OutageSchedule_MarketDocument()
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
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::OutageSchedule_MarketDocument
    return _parse(OutageSchedule_MarketDocument, root(parsexml(xml)))
end

end  # module Mltopdocument_v1_0
