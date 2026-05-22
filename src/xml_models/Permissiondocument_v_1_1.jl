# Auto-generated from iec62325-451-n-permissiondocument_v_1_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:permissiondocument:1:1

module Permissiondocument_v_1_1

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

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct Series
    mRID::Union{Nothing, String} = nothing
    businessType::Union{Nothing, String} = nothing
    product::Union{Nothing, String} = nothing
    curveType::Union{Nothing, String} = nothing
    measurement_Unit_name::Union{Nothing, String} = nothing
    reading_Period_resolution::Union{Nothing, String} = nothing
    reading_Period_timeInterval::Union{Nothing, ESMP_DateTimeInterval} = nothing
end

Base.@kwdef mutable struct Permission
    mRID::Union{Nothing, String} = nothing
    createdDateTime::Union{Nothing, DateTime} = nothing
    permissionEnd_DateAndOrTime_dateTime::Union{Nothing, DateTime} = nothing
    maxLifetimePermission_DateAndOrTime_dateTime::Union{Nothing, DateTime} = nothing
    permitting_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    permitting_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    permitted_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    permitted_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    Series::Vector{Series} = Series[]
    transmissionSchedule_Period_resolution::Union{Nothing, String} = nothing
    transmissionSchedule_Period_timeInterval::Union{Nothing, ESMP_DateTimeInterval} = nothing
    purpose_Reason_code::Union{Nothing, String} = nothing
    purpose_Reason_text::Union{Nothing, String} = nothing
    endOfPermission_Reason_code::Union{Nothing, String} = nothing
    endOfPermission_Reason_text::Union{Nothing, String} = nothing
    permission_MarketObjectStatus_status::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct AccountingPoint
    mRID::Union{Nothing, MeasurementPointID_String} = nothing
    flowCommodityOption::Union{Nothing, String} = nothing
    Permission::Vector{Permission} = Permission[]
end

Base.@kwdef mutable struct MktActivityRecord
    mRID::String = ""
    type_::String = ""
    AccountingPoint::Vector{AccountingPoint} = AccountingPoint[]
end

Base.@kwdef mutable struct Permission_MarketDocument
    mRID::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    MktActivityRecord::Vector{MktActivityRecord} = MktActivityRecord[]
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

function _parse(::Type{Series}, n::EzXML.Node)
    out = Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "product"
            out.product = String(strip(nodecontent(c)))
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "reading_Period.resolution"
            out.reading_Period_resolution = String(strip(nodecontent(c)))
        elseif nm == "reading_Period.timeInterval"
            out.reading_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        end
    end
    return out
end

function _parse(::Type{Permission}, n::EzXML.Node)
    out = Permission()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "createdDateTime"
            out.createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "permissionEnd_DateAndOrTime.dateTime"
            out.permissionEnd_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "maxLifetimePermission_DateAndOrTime.dateTime"
            out.maxLifetimePermission_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "permitting_MarketParticipant.mRID"
            out.permitting_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "permitting_MarketParticipant.marketRole.type"
            out.permitting_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "permitted_MarketParticipant.mRID"
            out.permitted_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "permitted_MarketParticipant.marketRole.type"
            out.permitted_MarketParticipant_marketRole_type = String(strip(nodecontent(c)))
        elseif nm == "Series"
            push!(out.Series, _parse(Series, c))
        elseif nm == "transmissionSchedule_Period.resolution"
            out.transmissionSchedule_Period_resolution = String(strip(nodecontent(c)))
        elseif nm == "transmissionSchedule_Period.timeInterval"
            out.transmissionSchedule_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "purpose_Reason.code"
            out.purpose_Reason_code = String(strip(nodecontent(c)))
        elseif nm == "purpose_Reason.text"
            out.purpose_Reason_text = String(strip(nodecontent(c)))
        elseif nm == "endOfPermission_Reason.code"
            out.endOfPermission_Reason_code = String(strip(nodecontent(c)))
        elseif nm == "endOfPermission_Reason.text"
            out.endOfPermission_Reason_text = String(strip(nodecontent(c)))
        elseif nm == "permission_MarketObjectStatus.status"
            out.permission_MarketObjectStatus_status = String(strip(nodecontent(c)))
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
        elseif nm == "Permission"
            push!(out.Permission, _parse(Permission, c))
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
        elseif nm == "type"
            out.type_ = String(strip(nodecontent(c)))
        elseif nm == "AccountingPoint"
            push!(out.AccountingPoint, _parse(AccountingPoint, c))
        end
    end
    return out
end

function _parse(::Type{Permission_MarketDocument}, n::EzXML.Node)
    out = Permission_MarketDocument()
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
        elseif nm == "period.timeInterval"
            out.period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "MktActivityRecord"
            push!(out.MktActivityRecord, _parse(MktActivityRecord, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::Permission_MarketDocument
    return _parse(Permission_MarketDocument, root(parsexml(xml)))
end

end  # module Permissiondocument_v_1_1
