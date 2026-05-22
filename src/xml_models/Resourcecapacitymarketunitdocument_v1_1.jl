# Auto-generated from iec62325-451-n-resourcecapacitymarketunitdocument_v1_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:resourcecapacitymarketunitdocument:1:1

module Resourcecapacitymarketunitdocument_v1_1

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

Base.@kwdef mutable struct Action_Status
    value::String = ""
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    quantity::Float64 = 0.0
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct Series_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    resolution::String = ""
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct ElectronicAddress
    email1::String = ""
end

Base.@kwdef mutable struct Analog
    measurementType::String = ""
    unitSymbol::String = ""
    analogValues_value::Float32 = 0.0
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Fuel
    fuel::String = ""
end

Base.@kwdef mutable struct MeasurementPointID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct MarketEvaluationPoint
    mRID::MeasurementPointID_String = MeasurementPointID_String()
end

Base.@kwdef mutable struct Unit_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    resourceCapacity_maximumCapacity::Union{Nothing, Float64} = nothing
    resourceCapacity_unitSymbol::Union{Nothing, String} = nothing
    street_Location_name::Union{Nothing, String} = nothing
    streetNumber_Location_name::Union{Nothing, String} = nothing
    city_Location_name::Union{Nothing, String} = nothing
    postalCode_Location_name::Union{Nothing, String} = nothing
    country_Location_name::Union{Nothing, String} = nothing
    gPS_Location_gPS_CoordinateSystem_mRID::Union{Nothing, String} = nothing
    gPS_Location_gPS_PositionPoints_xPosition::Union{Nothing, String} = nothing
    gPS_Location_gPS_PositionPoints_yPosition::Union{Nothing, String} = nothing
    gPS_Location_gPS_PositionPoints_zPosition::Union{Nothing, String} = nothing
    technology_PSRType_psrType::Union{Nothing, String} = nothing
    Fuel::Vector{Fuel} = Fuel[]
    Measurements::Vector{Analog} = Analog[]
    MarketEvaluationPoint::Vector{MarketEvaluationPoint} = MarketEvaluationPoint[]
end

Base.@kwdef mutable struct StreetDetail
    addressGeneral::Union{Nothing, String} = nothing
    addressGeneral2::Union{Nothing, String} = nothing
    addressGeneral3::Union{Nothing, String} = nothing
    floorIdentification::String = ""
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

Base.@kwdef mutable struct Time_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
end

Base.@kwdef mutable struct ResourceCapacityMarketUnit_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    resourceCapacity_maximumCapacity::Union{Nothing, Float64} = nothing
    resourceCapacity_unitSymbol::Union{Nothing, String} = nothing
    location_name::Union{Nothing, String} = nothing
    MarketEvaluationPoint::Vector{MarketEvaluationPoint} = MarketEvaluationPoint[]
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    businessType::String = ""
    product::String = ""
    ResourceCapacityMarketUnit_RegisteredResource::ResourceCapacityMarketUnit_RegisteredResource = ResourceCapacityMarketUnit_RegisteredResource()
    curveType::Union{Nothing, String} = nothing
    resourceProvider_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    resourceProvider_MarketParticipant_name::Union{Nothing, String} = nothing
    resourceProvider_MarketParticipant_streetAddress::Union{Nothing, StreetAddress} = nothing
    resourceProvider_MarketParticipant_phone1::Union{Nothing, TelephoneNumber} = nothing
    resourceProvider_MarketParticipant_electronicAddress::Union{Nothing, ElectronicAddress} = nothing
    networkOperator_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    resourceCapacityMechanismOperator_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    memberState_MarketParticipant_mRID::Union{Nothing, PartyID_String} = nothing
    initialRegistration_DateAndOrTime_dateTime::Union{Nothing, DateTime} = nothing
    registration_DateAndOrTime_dateTime::Union{Nothing, DateTime} = nothing
    lastVerification_DateAndOrTime_dateTime::Union{Nothing, DateTime} = nothing
    primaryMarketParticipation_MarketObjectStatus_status::Union{Nothing, String} = nothing
    secondaryMarketParticipation_MarketObjectStatus_status::Union{Nothing, String} = nothing
    capacityMechanism_MarketProduct_marketProductType::Union{Nothing, String} = nothing
    clearanceNumber_Names_name::Union{Nothing, String} = nothing
    measurement_Unit_name::Union{Nothing, String} = nothing
    Unit_RegisteredResource::Vector{Unit_RegisteredResource} = Unit_RegisteredResource[]
    Elegibility_Period::Vector{Time_Period} = Time_Period[]
    Period::Vector{Series_Period} = Series_Period[]
end

Base.@kwdef mutable struct ResourceCapacityMarketUnit_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    Time_Period::Time_Period = Time_Period()
    docStatus::Union{Nothing, Action_Status} = nothing
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
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
            out.position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        elseif nm == "quantity"
            out.quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        end
    end
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

function _parse(::Type{Analog}, n::EzXML.Node)
    out = Analog()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "measurementType"
            out.measurementType = String(strip(nodecontent(c)))
        elseif nm == "unitSymbol"
            out.unitSymbol = String(strip(nodecontent(c)))
        elseif nm == "analogValues.value"
            out.analogValues_value = (x -> parse(Float32, x))(strip(nodecontent(c)))
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

function _parse(::Type{Fuel}, n::EzXML.Node)
    out = Fuel()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "fuel"
            out.fuel = String(strip(nodecontent(c)))
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

function _parse(::Type{MarketEvaluationPoint}, n::EzXML.Node)
    out = MarketEvaluationPoint()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(MeasurementPointID_String, c)
        end
    end
    return out
end

function _parse(::Type{Unit_RegisteredResource}, n::EzXML.Node)
    out = Unit_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "resourceCapacity.maximumCapacity"
            out.resourceCapacity_maximumCapacity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.unitSymbol"
            out.resourceCapacity_unitSymbol = String(strip(nodecontent(c)))
        elseif nm == "street_Location.name"
            out.street_Location_name = String(strip(nodecontent(c)))
        elseif nm == "streetNumber_Location.name"
            out.streetNumber_Location_name = String(strip(nodecontent(c)))
        elseif nm == "city_Location.name"
            out.city_Location_name = String(strip(nodecontent(c)))
        elseif nm == "postalCode_Location.name"
            out.postalCode_Location_name = String(strip(nodecontent(c)))
        elseif nm == "country_Location.name"
            out.country_Location_name = String(strip(nodecontent(c)))
        elseif nm == "gPS_Location.gPS_CoordinateSystem.mRID"
            out.gPS_Location_gPS_CoordinateSystem_mRID = String(strip(nodecontent(c)))
        elseif nm == "gPS_Location.gPS_PositionPoints.xPosition"
            out.gPS_Location_gPS_PositionPoints_xPosition = String(strip(nodecontent(c)))
        elseif nm == "gPS_Location.gPS_PositionPoints.yPosition"
            out.gPS_Location_gPS_PositionPoints_yPosition = String(strip(nodecontent(c)))
        elseif nm == "gPS_Location.gPS_PositionPoints.zPosition"
            out.gPS_Location_gPS_PositionPoints_zPosition = String(strip(nodecontent(c)))
        elseif nm == "technology_PSRType.psrType"
            out.technology_PSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "Fuel"
            push!(out.Fuel, _parse(Fuel, c))
        elseif nm == "Measurements"
            push!(out.Measurements, _parse(Analog, c))
        elseif nm == "MarketEvaluationPoint"
            push!(out.MarketEvaluationPoint, _parse(MarketEvaluationPoint, c))
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

function _parse(::Type{ResourceCapacityMarketUnit_RegisteredResource}, n::EzXML.Node)
    out = ResourceCapacityMarketUnit_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "resourceCapacity.maximumCapacity"
            out.resourceCapacity_maximumCapacity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.unitSymbol"
            out.resourceCapacity_unitSymbol = String(strip(nodecontent(c)))
        elseif nm == "location.name"
            out.location_name = String(strip(nodecontent(c)))
        elseif nm == "MarketEvaluationPoint"
            push!(out.MarketEvaluationPoint, _parse(MarketEvaluationPoint, c))
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
        elseif nm == "ResourceCapacityMarketUnit_RegisteredResource"
            out.ResourceCapacityMarketUnit_RegisteredResource = _parse(ResourceCapacityMarketUnit_RegisteredResource, c)
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "resourceProvider_MarketParticipant.mRID"
            out.resourceProvider_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "resourceProvider_MarketParticipant.name"
            out.resourceProvider_MarketParticipant_name = String(strip(nodecontent(c)))
        elseif nm == "resourceProvider_MarketParticipant.streetAddress"
            out.resourceProvider_MarketParticipant_streetAddress = _parse(StreetAddress, c)
        elseif nm == "resourceProvider_MarketParticipant.phone1"
            out.resourceProvider_MarketParticipant_phone1 = _parse(TelephoneNumber, c)
        elseif nm == "resourceProvider_MarketParticipant.electronicAddress"
            out.resourceProvider_MarketParticipant_electronicAddress = _parse(ElectronicAddress, c)
        elseif nm == "networkOperator_MarketParticipant.mRID"
            out.networkOperator_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "resourceCapacityMechanismOperator_MarketParticipant.mRID"
            out.resourceCapacityMechanismOperator_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "memberState_MarketParticipant.mRID"
            out.memberState_MarketParticipant_mRID = _parse(PartyID_String, c)
        elseif nm == "initialRegistration_DateAndOrTime.dateTime"
            out.initialRegistration_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "registration_DateAndOrTime.dateTime"
            out.registration_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "lastVerification_DateAndOrTime.dateTime"
            out.lastVerification_DateAndOrTime_dateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "primaryMarketParticipation_MarketObjectStatus.status"
            out.primaryMarketParticipation_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "secondaryMarketParticipation_MarketObjectStatus.status"
            out.secondaryMarketParticipation_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "capacityMechanism_MarketProduct.marketProductType"
            out.capacityMechanism_MarketProduct_marketProductType = String(strip(nodecontent(c)))
        elseif nm == "clearanceNumber_Names.name"
            out.clearanceNumber_Names_name = String(strip(nodecontent(c)))
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "Unit_RegisteredResource"
            push!(out.Unit_RegisteredResource, _parse(Unit_RegisteredResource, c))
        elseif nm == "Elegibility_Period"
            push!(out.Elegibility_Period, _parse(Time_Period, c))
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        end
    end
    return out
end

function _parse(::Type{ResourceCapacityMarketUnit_MarketDocument}, n::EzXML.Node)
    out = ResourceCapacityMarketUnit_MarketDocument()
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
        elseif nm == "Time_Period"
            out.Time_Period = _parse(Time_Period, c)
        elseif nm == "docStatus"
            out.docStatus = _parse(Action_Status, c)
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::ResourceCapacityMarketUnit_MarketDocument
    return _parse(ResourceCapacityMarketUnit_MarketDocument, root(parsexml(xml)))
end

end  # module Resourcecapacitymarketunitdocument_v1_1
