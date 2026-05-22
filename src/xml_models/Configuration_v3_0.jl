# Auto-generated from iec62325-451-6-configuration_v3_0.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-6:configurationdocument:3:0

module Configuration_v3_0

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

Base.@kwdef mutable struct ESMP_ActivePower
    value::String = ""
    unit::String = ""
end

Base.@kwdef mutable struct ESMP_Voltage
    value::String = ""
    unit::String = ""
end

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct ControlArea_Domain
    mRID::AreaID_String = AreaID_String()
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct MktGeneratingUnit
    mRID::ResourceID_String = ResourceID_String()
    name::String = ""
    nominalP::ESMP_ActivePower = ESMP_ActivePower()
    generatingUnit_PSRType_psrType::String = ""
    generatingUnit_Location_name::String = ""
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct MktPSRType
    psrType::String = ""
    production_PowerSystemResources_highVoltageLimit::Union{Nothing, ESMP_Voltage} = nothing
    nominalIP_PowerSystemResources_nominalP::Union{Nothing, ESMP_ActivePower} = nothing
    GeneratingUnit_PowerSystemResources::Vector{MktGeneratingUnit} = MktGeneratingUnit[]
end

Base.@kwdef mutable struct Provider_MarketParticipant
    mRID::PartyID_String = PartyID_String()
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    businessType::String = ""
    implementation_DateAndOrTime_date::Date = Date(1970)
    biddingZone_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    registeredResource_mRID::ResourceID_String = ResourceID_String()
    registeredResource_name::String = ""
    registeredResource_location_name::String = ""
    ControlArea_Domain::Vector{ControlArea_Domain} = ControlArea_Domain[]
    Provider_MarketParticipant::Vector{Provider_MarketParticipant} = Provider_MarketParticipant[]
    MktPSRType::MktPSRType = MktPSRType()
end

Base.@kwdef mutable struct Configuration_MarketDocument
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

function _parse(::Type{ESMP_ActivePower}, n::EzXML.Node)
    out = ESMP_ActivePower()
    if hasattribute(n, "unit")
        out.unit = String(n["unit"])
    end
    out.value = String(strip(nodecontent(n)))
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

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{ControlArea_Domain}, n::EzXML.Node)
    out = ControlArea_Domain()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(AreaID_String, c)
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

function _parse(::Type{MktGeneratingUnit}, n::EzXML.Node)
    out = MktGeneratingUnit()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "nominalP"
            out.nominalP = _parse(ESMP_ActivePower, c)
        elseif nm == "generatingUnit_PSRType.psrType"
            out.generatingUnit_PSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "generatingUnit_Location.name"
            out.generatingUnit_Location_name = String(strip(nodecontent(c)))
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

function _parse(::Type{MktPSRType}, n::EzXML.Node)
    out = MktPSRType()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "psrType"
            out.psrType = String(strip(nodecontent(c)))
        elseif nm == "production_PowerSystemResources.highVoltageLimit"
            out.production_PowerSystemResources_highVoltageLimit = _parse(ESMP_Voltage, c)
        elseif nm == "nominalIP_PowerSystemResources.nominalP"
            out.nominalIP_PowerSystemResources_nominalP = _parse(ESMP_ActivePower, c)
        elseif nm == "GeneratingUnit_PowerSystemResources"
            push!(out.GeneratingUnit_PowerSystemResources, _parse(MktGeneratingUnit, c))
        end
    end
    return out
end

function _parse(::Type{Provider_MarketParticipant}, n::EzXML.Node)
    out = Provider_MarketParticipant()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(PartyID_String, c)
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
        elseif nm == "implementation_DateAndOrTime.date"
            out.implementation_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "biddingZone_Domain.mRID"
            out.biddingZone_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "registeredResource.mRID"
            out.registeredResource_mRID = _parse(ResourceID_String, c)
        elseif nm == "registeredResource.name"
            out.registeredResource_name = String(strip(nodecontent(c)))
        elseif nm == "registeredResource.location.name"
            out.registeredResource_location_name = String(strip(nodecontent(c)))
        elseif nm == "ControlArea_Domain"
            push!(out.ControlArea_Domain, _parse(ControlArea_Domain, c))
        elseif nm == "Provider_MarketParticipant"
            push!(out.Provider_MarketParticipant, _parse(Provider_MarketParticipant, c))
        elseif nm == "MktPSRType"
            out.MktPSRType = _parse(MktPSRType, c)
        end
    end
    return out
end

function _parse(::Type{Configuration_MarketDocument}, n::EzXML.Node)
    out = Configuration_MarketDocument()
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

function parse_document(xml::AbstractString)::Configuration_MarketDocument
    return _parse(Configuration_MarketDocument, root(parsexml(xml)))
end

end  # module Configuration_v3_0
