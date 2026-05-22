# Auto-generated from iec62325-451-n-mltopconfigurationdocument_v1_0.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:mltopconfigurationdocument:1:0

module Mltopconfigurationdocument_v1_0

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

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Specific_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Domain
    mRID::AreaID_String = AreaID_String()
end

Base.@kwdef mutable struct Other_MarketParticipant
    mRID::PartyID_String = PartyID_String()
end

Base.@kwdef mutable struct ESMP_Voltage
    value::String = ""
    unit::String = ""
end

Base.@kwdef mutable struct TimeSeries
    registeredResource_mRID::ResourceID_String = ResourceID_String()
    registeredResource_name::String = ""
    registeredResource_location_name::Union{Nothing, String} = nothing
    registeredResource_pSRType_psrType::String = ""
    registeredResource_pSRType_powerSystemResources_highVoltageLimit::ESMP_Voltage = ESMP_Voltage()
    registeredResource_pSRType_powerSystemResources_lowVoltageLimit::Union{Nothing, ESMP_Voltage} = nothing
    cancelledTS::Union{Nothing, String} = nothing
    description::Union{Nothing, String} = nothing
    owner_MarketParticipant_mRID::PartyID_String = PartyID_String()
    startLifetime_DateAndOrTime_date::Date = Date(1970)
    endLifetime_DateAndOrTime_date::Union{Nothing, Date} = nothing
    implementation_DateAndOrTime_date::Union{Nothing, Date} = nothing
    active_Measurement_Unit_name::Union{Nothing, String} = nothing
    installedGeneration_Quantity_quantity::Union{Nothing, Float64} = nothing
    installedConsumption_Quantity_quantity::Union{Nothing, Float64} = nothing
    installedReactive_Quantity_quantity::Union{Nothing, Float64} = nothing
    reactive_Measurement_Unit_name::Union{Nothing, String} = nothing
    multipod_RegisteredResource_mRID::Union{Nothing, ResourceID_String} = nothing
    Domain::Vector{Domain} = Domain[]
    Coordination_MarketParticipant::Vector{Other_MarketParticipant} = Other_MarketParticipant[]
    Interested_MarketParticipant::Vector{Other_MarketParticipant} = Other_MarketParticipant[]
    Specific_RegisteredResource::Vector{Specific_RegisteredResource} = Specific_RegisteredResource[]
end

Base.@kwdef mutable struct Ref_MarketDocument
    mRID::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

function _parse(::Type{ResourceID_String}, n::EzXML.Node)
    out = ResourceID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{Specific_RegisteredResource}, n::EzXML.Node)
    out = Specific_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
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

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{Domain}, n::EzXML.Node)
    out = Domain()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(AreaID_String, c)
        end
    end
    return out
end

function _parse(::Type{Other_MarketParticipant}, n::EzXML.Node)
    out = Other_MarketParticipant()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(PartyID_String, c)
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

function _parse(::Type{TimeSeries}, n::EzXML.Node)
    out = TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "registeredResource.mRID"
            out.registeredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "registeredResource.name"
            out.registeredResource_name = String(strip(nodecontent(c)))
        elseif nm == "registeredResource.location.name"
            out.registeredResource_location_name = String(strip(nodecontent(c)))
        elseif nm == "registeredResource.pSRType.psrType"
            out.registeredResource_pSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "registeredResource.pSRType.powerSystemResources.highVoltageLimit"
            out.registeredResource_pSRType_powerSystemResources_highVoltageLimit = _parse(ESMP_Voltage, c)
        elseif nm == "registeredResource.pSRType.powerSystemResources.lowVoltageLimit"
            out.registeredResource_pSRType_powerSystemResources_lowVoltageLimit = _parse(ESMP_Voltage, c)
        elseif nm == "cancelledTS"
            out.cancelledTS = String(strip(nodecontent(c)))
        elseif nm == "description"
            out.description = String(strip(nodecontent(c)))
        elseif nm == "owner_MarketParticipant.mRID"
            out.owner_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "startLifetime_DateAndOrTime.date"
            out.startLifetime_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "endLifetime_DateAndOrTime.date"
            out.endLifetime_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "implementation_DateAndOrTime.date"
            out.implementation_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "active_Measurement_Unit.name"
            out.active_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "installedGeneration_Quantity.quantity"
            out.installedGeneration_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "installedConsumption_Quantity.quantity"
            out.installedConsumption_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "installedReactive_Quantity.quantity"
            out.installedReactive_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "reactive_Measurement_Unit.name"
            out.reactive_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "multipod_RegisteredResource.mRID"
            out.multipod_RegisteredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "Domain"
            push!(out.Domain, _parse(Domain, c))
        elseif nm == "Coordination_MarketParticipant"
            push!(out.Coordination_MarketParticipant, _parse(Other_MarketParticipant, c))
        elseif nm == "Interested_MarketParticipant"
            push!(out.Interested_MarketParticipant, _parse(Other_MarketParticipant, c))
        elseif nm == "Specific_RegisteredResource"
            push!(out.Specific_RegisteredResource, _parse(Specific_RegisteredResource, c))
        end
    end
    return out
end

function _parse(::Type{Ref_MarketDocument}, n::EzXML.Node)
    out = Ref_MarketDocument()
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
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::Ref_MarketDocument
    return _parse(Ref_MarketDocument, root(parsexml(xml)))
end

end  # module Mltopconfigurationdocument_v1_0
