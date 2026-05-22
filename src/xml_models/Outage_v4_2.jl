# Auto-generated from iec62325-451-6-outage_v4_2.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:ebix.eu:ProofOfConcept:1:0

module Outage_v4_2

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

Base.@kwdef mutable struct ESMP_ActivePower
    value::String = ""
    unit::String = ""
end

Base.@kwdef mutable struct Series_Period
    timeInterval::String = ""
    resolution::String = ""
    Point::Vector{String} = String[]
end

Base.@kwdef mutable struct PTDFDomain_Series
    pTDF_Domain_mRID::Union{Nothing, String} = nothing
    pTDF_Domain_unavailableImportCapability_Quantity_quantity::Union{Nothing, Float64} = nothing
    pTDF_Domain_unavailableExportCapability_Quantity_quantity::Union{Nothing, Float64} = nothing
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Asset_RegisteredResource
    mRID::String = ""
    name::Union{Nothing, String} = nothing
    asset_PSRType_psrType::Union{Nothing, String} = nothing
    location_name::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Action_Status
    value::String = ""
end

Base.@kwdef mutable struct Point
    position::String = ""
    quantity::Union{Nothing, Float64} = nothing
    installed_Quantity_quantity::Union{Nothing, Float64} = nothing
    PTDFDomain_Series::Vector{String} = String[]
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    businessType::String = ""
    biddingZone_Domain_mRID::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, String} = nothing
    out_Domain_mRID::Union{Nothing, String} = nothing
    start_DateAndOrTime_date::Date = Date(1970)
    start_DateAndOrTime_time::String = ""
    end_DateAndOrTime_date::Date = Date(1970)
    end_DateAndOrTime_time::String = ""
    quantity_Measurement_Unit_name::String = ""
    curveType::String = ""
    production_RegisteredResource_mRID::Union{Nothing, String} = nothing
    production_RegisteredResource_name::Union{Nothing, String} = nothing
    production_RegisteredResource_location_name::Union{Nothing, String} = nothing
    production_RegisteredResource_pSRType_psrType::Union{Nothing, String} = nothing
    production_RegisteredResource_pSRType_powerSystemResources_mRID::Union{Nothing, String} = nothing
    production_RegisteredResource_pSRType_powerSystemResources_name::Union{Nothing, String} = nothing
    production_RegisteredResource_pSRType_powerSystemResources_nominalP::Union{Nothing, String} = nothing
    Asset_RegisteredResource::Vector{String} = String[]
    Available_Period::Vector{String} = String[]
    WindPowerFeedin_Period::Vector{String} = String[]
    Reason::Vector{String} = String[]
end

Base.@kwdef mutable struct Unavailability_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::String = ""
    createdDateTime::String = ""
    sender_MarketParticipant_mRID::String = ""
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::String = ""
    receiver_MarketParticipant_marketRole_type::String = ""
    unavailability_Time_Period_timeInterval::String = ""
    docStatus::Union{Nothing, String} = nothing
    TimeSeries::Vector{String} = String[]
    Reason::Vector{String} = String[]
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

function _parse(::Type{ESMP_ActivePower}, n::EzXML.Node)
    out = ESMP_ActivePower()
    if hasattribute(n, "unit")
        out.unit = String(n["unit"])
    end
    out.value = String(strip(nodecontent(n)))
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

function _parse(::Type{PTDFDomain_Series}, n::EzXML.Node)
    out = PTDFDomain_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "pTDF_Domain.mRID"
            out.pTDF_Domain_mRID = String(strip(nodecontent(c)))
        elseif nm == "pTDF_Domain.unavailableImportCapability_Quantity.quantity"
            out.pTDF_Domain_unavailableImportCapability_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "pTDF_Domain.unavailableExportCapability_Quantity.quantity"
            out.pTDF_Domain_unavailableExportCapability_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
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

function _parse(::Type{Asset_RegisteredResource}, n::EzXML.Node)
    out = Asset_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "asset_PSRType.psrType"
            out.asset_PSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "location.name"
            out.location_name = String(strip(nodecontent(c)))
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

function _parse(::Type{Action_Status}, n::EzXML.Node)
    out = Action_Status()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "value"
            out.value = String(strip(nodecontent(c)))
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
        elseif nm == "installed_Quantity.quantity"
            out.installed_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "PTDFDomain_Series"
            push!(out.PTDFDomain_Series, String(strip(nodecontent(c))))
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
        elseif nm == "biddingZone_Domain.mRID"
            out.biddingZone_Domain_mRID = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = String(strip(nodecontent(c)))
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = String(strip(nodecontent(c)))
        elseif nm == "start_DateAndOrTime.date"
            out.start_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "start_DateAndOrTime.time"
            out.start_DateAndOrTime_time = String(strip(nodecontent(c)))
        elseif nm == "end_DateAndOrTime.date"
            out.end_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "end_DateAndOrTime.time"
            out.end_DateAndOrTime_time = String(strip(nodecontent(c)))
        elseif nm == "quantity_Measurement_Unit.name"
            out.quantity_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "production_RegisteredResource.mRID"
            out.production_RegisteredResource_mRID = String(strip(nodecontent(c)))
        elseif nm == "production_RegisteredResource.name"
            out.production_RegisteredResource_name = String(strip(nodecontent(c)))
        elseif nm == "production_RegisteredResource.location.name"
            out.production_RegisteredResource_location_name = String(strip(nodecontent(c)))
        elseif nm == "production_RegisteredResource.pSRType.psrType"
            out.production_RegisteredResource_pSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "production_RegisteredResource.pSRType.powerSystemResources.mRID"
            out.production_RegisteredResource_pSRType_powerSystemResources_mRID = String(strip(nodecontent(c)))
        elseif nm == "production_RegisteredResource.pSRType.powerSystemResources.name"
            out.production_RegisteredResource_pSRType_powerSystemResources_name = String(strip(nodecontent(c)))
        elseif nm == "production_RegisteredResource.pSRType.powerSystemResources.nominalP"
            out.production_RegisteredResource_pSRType_powerSystemResources_nominalP = String(strip(nodecontent(c)))
        elseif nm == "Asset_RegisteredResource"
            push!(out.Asset_RegisteredResource, String(strip(nodecontent(c))))
        elseif nm == "Available_Period"
            push!(out.Available_Period, String(strip(nodecontent(c))))
        elseif nm == "WindPowerFeedin_Period"
            push!(out.WindPowerFeedin_Period, String(strip(nodecontent(c))))
        elseif nm == "Reason"
            push!(out.Reason, String(strip(nodecontent(c))))
        end
    end
    return out
end

function _parse(::Type{Unavailability_MarketDocument}, n::EzXML.Node)
    out = Unavailability_MarketDocument()
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
        elseif nm == "unavailability_Time_Period.timeInterval"
            out.unavailability_Time_Period_timeInterval = String(strip(nodecontent(c)))
        elseif nm == "docStatus"
            out.docStatus = String(strip(nodecontent(c)))
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, String(strip(nodecontent(c))))
        elseif nm == "Reason"
            push!(out.Reason, String(strip(nodecontent(c))))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::Unavailability_MarketDocument
    return _parse(Unavailability_MarketDocument, root(parsexml(xml)))
end

end  # module Outage_v4_2
