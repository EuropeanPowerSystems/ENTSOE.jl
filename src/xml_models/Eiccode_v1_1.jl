# Auto-generated from iec62325-451-n-eiccode_v1_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:eicdocument:1:1

module Eiccode_v1_1

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

Base.@kwdef mutable struct Function_Name
    name::String = ""
end

Base.@kwdef mutable struct ElectronicAddress
    email1::String = ""
end

Base.@kwdef mutable struct StreetDetail
    addressGeneral::Union{Nothing, String} = nothing
    addressGeneral2::Union{Nothing, String} = nothing
    addressGeneral3::Union{Nothing, String} = nothing
    floorIdentification::String = ""
end

Base.@kwdef mutable struct Action_Status
    value::String = ""
end

Base.@kwdef mutable struct TownDetail
    name::String = ""
    country::String = ""
end

Base.@kwdef mutable struct StreetAddress
    streetDetail::StreetDetail = StreetDetail()
    postalCode::String = ""
    townDetail::TownDetail = TownDetail()
    language::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct TelephoneNumber
    ituPhone::String = ""
end

Base.@kwdef mutable struct EICCode_MarketDocument
    mRID::Union{Nothing, String} = nothing
    status::Union{Nothing, Action_Status} = nothing
    docStatus::Union{Nothing, Action_Status} = nothing
    attributeInstanceComponent_attribute::Union{Nothing, String} = nothing
    long_Names_name::String = ""
    display_Names_name::String = ""
    lastRequest_DateAndOrTime_date::Date = Date(1970)
    deactivationRequested_DateAndOrTime_date::Union{Nothing, Date} = nothing
    eICContact_MarketParticipant_name::Union{Nothing, String} = nothing
    eICContact_MarketParticipant_phone1::Union{Nothing, TelephoneNumber} = nothing
    eICContact_MarketParticipant_electronicAddress::Union{Nothing, ElectronicAddress} = nothing
    eICCode_MarketParticipant_streetAddress::Union{Nothing, StreetAddress} = nothing
    eICCode_MarketParticipant_aCERCode_Names_name::Union{Nothing, String} = nothing
    eICCode_MarketParticipant_vATCode_Names_name::Union{Nothing, String} = nothing
    eICParent_MarketDocument_mRID::Union{Nothing, String} = nothing
    eICResponsible_MarketParticipant_mRID::Union{Nothing, String} = nothing
    description::Union{Nothing, String} = nothing
    Function_Names::Vector{Function_Name} = Function_Name[]
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct EIC_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    sender_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    sender_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    receiver_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    receiver_MarketParticipant_marketRole_type::Union{Nothing, String} = nothing
    createdDateTime::DateTime = DateTime(1970)
    EICCode_MarketDocument::Vector{EICCode_MarketDocument} = EICCode_MarketDocument[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

function _parse(::Type{Function_Name}, n::EzXML.Node)
    out = Function_Name()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "name"
            out.name = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{ElectronicAddress}, n::EzXML.Node)
    out = ElectronicAddress()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "email1"
            out.email1 = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{StreetDetail}, n::EzXML.Node)
    out = StreetDetail()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "addressGeneral"
            out.addressGeneral = String(strip(nodecontent(c)))
        elseif nm == "addressGeneral2"
            out.addressGeneral2 = String(strip(nodecontent(c)))
        elseif nm == "addressGeneral3"
            out.addressGeneral3 = String(strip(nodecontent(c)))
        elseif nm == "floorIdentification"
            out.floorIdentification = String(strip(nodecontent(c)))
        end
    end
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

function _parse(::Type{TownDetail}, n::EzXML.Node)
    out = TownDetail()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "country"
            out.country = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{StreetAddress}, n::EzXML.Node)
    out = StreetAddress()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "streetDetail"
            out.streetDetail = _parse(StreetDetail, c)
        elseif nm == "postalCode"
            out.postalCode = String(strip(nodecontent(c)))
        elseif nm == "townDetail"
            out.townDetail = _parse(TownDetail, c)
        elseif nm == "language"
            out.language = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{TelephoneNumber}, n::EzXML.Node)
    out = TelephoneNumber()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "ituPhone"
            out.ituPhone = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{EICCode_MarketDocument}, n::EzXML.Node)
    out = EICCode_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "status"
            out.status = _parse(Action_Status, c)
        elseif nm == "docStatus"
            out.docStatus = _parse(Action_Status, c)
        elseif nm == "attributeInstanceComponent.attribute"
            out.attributeInstanceComponent_attribute = String(strip(nodecontent(c)))
        elseif nm == "long_Names.name"
            out.long_Names_name = String(strip(nodecontent(c)))
        elseif nm == "display_Names.name"
            out.display_Names_name = String(strip(nodecontent(c)))
        elseif nm == "lastRequest_DateAndOrTime.date"
            out.lastRequest_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "deactivationRequested_DateAndOrTime.date"
            out.deactivationRequested_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "eICContact_MarketParticipant.name"
            out.eICContact_MarketParticipant_name = String(strip(nodecontent(c)))
        elseif nm == "eICContact_MarketParticipant.phone1"
            out.eICContact_MarketParticipant_phone1 = _parse(TelephoneNumber, c)
        elseif nm == "eICContact_MarketParticipant.electronicAddress"
            out.eICContact_MarketParticipant_electronicAddress = _parse(ElectronicAddress, c)
        elseif nm == "eICCode_MarketParticipant.streetAddress"
            out.eICCode_MarketParticipant_streetAddress = _parse(StreetAddress, c)
        elseif nm == "eICCode_MarketParticipant.aCERCode_Names.name"
            out.eICCode_MarketParticipant_aCERCode_Names_name = String(strip(nodecontent(c)))
        elseif nm == "eICCode_MarketParticipant.vATCode_Names.name"
            out.eICCode_MarketParticipant_vATCode_Names_name = String(strip(nodecontent(c)))
        elseif nm == "eICParent_MarketDocument.mRID"
            out.eICParent_MarketDocument_mRID = String(strip(nodecontent(c)))
        elseif nm == "eICResponsible_MarketParticipant.mRID"
            out.eICResponsible_MarketParticipant_mRID = String(strip(nodecontent(c)))
        elseif nm == "description"
            out.description = String(strip(nodecontent(c)))
        elseif nm == "Function_Names"
            push!(out.Function_Names, _parse(Function_Name, c))
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

function _parse(::Type{EIC_MarketDocument}, n::EzXML.Node)
    out = EIC_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "revisionNumber"
            out.revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "type"
            out.type_ = String(strip(nodecontent(c)))
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
        elseif nm == "EICCode_MarketDocument"
            push!(out.EICCode_MarketDocument, _parse(EICCode_MarketDocument, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::EIC_MarketDocument
    return _parse(EIC_MarketDocument, root(parsexml(xml)))
end

end  # module Eiccode_v1_1
