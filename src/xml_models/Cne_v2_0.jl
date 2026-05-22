# Auto-generated from iec62325-451-n-cne_v2_0.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-n:cnedocument:2:0

module Cne_v2_0

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

Base.@kwdef mutable struct AreaID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Border_Series
    mRID::String = ""
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    flow_Quantity_quantity::Union{Nothing, Float64} = nothing
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct Series_Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Shared_Domain
    mRID::AreaID_String = AreaID_String()
end

Base.@kwdef mutable struct ResourceID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct RegisteredResource_Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct RemedialAction_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    pSRType_psrType::String = ""
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    in_AggregateNode_mRID::Union{Nothing, ResourceID_String} = nothing
    out_AggregateNode_mRID::Union{Nothing, ResourceID_String} = nothing
    marketObjectStatus_status::String = ""
    resourceCapacity_maximumCapacity::Union{Nothing, Float64} = nothing
    resourceCapacity_minimumCapacity::Union{Nothing, Float64} = nothing
    resourceCapacity_defaultCapacity::Union{Nothing, Float64} = nothing
    resourceCapacity_unitSymbol::Union{Nothing, String} = nothing
    Reason::Vector{RegisteredResource_Reason} = RegisteredResource_Reason[]
end

Base.@kwdef mutable struct RemedialAction_Series
    mRID::String = ""
    name::Union{Nothing, String} = nothing
    businessType::Union{Nothing, String} = nothing
    applicationMode_MarketObjectStatus_status::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    measurement_Unit_name::Union{Nothing, String} = nothing
    quantity_quantity::Union{Nothing, Float64} = nothing
    RegisteredResource::Vector{RemedialAction_RegisteredResource} = RemedialAction_RegisteredResource[]
    Shared_Domain::Vector{Shared_Domain} = Shared_Domain[]
    Reason::Vector{Series_Reason} = Series_Reason[]
end

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Contingency_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    Reason::Vector{RegisteredResource_Reason} = RegisteredResource_Reason[]
end

Base.@kwdef mutable struct AdditionalConstraint_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    Reason::Vector{RegisteredResource_Reason} = RegisteredResource_Reason[]
end

Base.@kwdef mutable struct AdditionalConstraint_Series
    mRID::String = ""
    businessType::Union{Nothing, String} = nothing
    name::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    measurement_Unit_name::Union{Nothing, String} = nothing
    quantity_quantity::Union{Nothing, Float64} = nothing
    RegisteredResource::Vector{AdditionalConstraint_RegisteredResource} = AdditionalConstraint_RegisteredResource[]
    Reason::Vector{Series_Reason} = Series_Reason[]
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Party_MarketParticipant
    mRID::PartyID_String = PartyID_String()
end

Base.@kwdef mutable struct Contingency_Series
    mRID::String = ""
    name::Union{Nothing, String} = nothing
    RegisteredResource::Vector{Contingency_RegisteredResource} = Contingency_RegisteredResource[]
    Reason::Vector{Series_Reason} = Series_Reason[]
end

Base.@kwdef mutable struct PTDF_Domain
    mRID::AreaID_String = AreaID_String()
    pTDF_Quantity_quantity::Float64 = 0.0
    pTDF_Quantity_quality::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Analog
    measurementType::String = ""
    unitSymbol::String = ""
    positiveFlowIn::Union{Nothing, String} = nothing
    analogValues_value::Float32 = 0.0
    analogValues_timeStamp::Union{Nothing, DateTime} = nothing
    analogValues_description::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct Monitored_RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
    name::Union{Nothing, String} = nothing
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    in_AggregateNode_mRID::Union{Nothing, ResourceID_String} = nothing
    out_AggregateNode_mRID::Union{Nothing, ResourceID_String} = nothing
    flowBasedStudy_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    flowBasedStudy_Domain_flowBasedMargin_Quantity_quantity::Union{Nothing, Float64} = nothing
    flowBasedStudy_Domain_flowBasedMargin_Quantity_quality::Union{Nothing, String} = nothing
    marketCoupling_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    marketCoupling_Domain_shadow_Price_amount::Union{Nothing, Float64} = nothing
    PTDF_Domain::Vector{PTDF_Domain} = PTDF_Domain[]
    Measurements::Vector{Analog} = Analog[]
    Reason::Vector{RegisteredResource_Reason} = RegisteredResource_Reason[]
end

Base.@kwdef mutable struct Constraint_Series
    mRID::String = ""
    businessType::String = ""
    name::Union{Nothing, String} = nothing
    referenceCalculation_DateAndOrTime_date::Union{Nothing, Date} = nothing
    referenceCalculation_DateAndOrTime_time::Union{Nothing, String} = nothing
    quantity_Measurement_Unit_name::Union{Nothing, String} = nothing
    externalConstraint_Quantity_quantity::Union{Nothing, Float64} = nothing
    externalConstraint_Quantity_quality::Union{Nothing, String} = nothing
    pTDF_Measurement_Unit_name::Union{Nothing, String} = nothing
    shadowPrice_Measurement_Unit_name::Union{Nothing, String} = nothing
    currency_Unit_name::Union{Nothing, String} = nothing
    Party_MarketParticipant::Vector{Party_MarketParticipant} = Party_MarketParticipant[]
    optimization_MarketObjectStatus_status::Union{Nothing, String} = nothing
    Border_Series::Vector{Border_Series} = Border_Series[]
    AdditionalConstraint_Series::Vector{AdditionalConstraint_Series} = AdditionalConstraint_Series[]
    Contingency_Series::Vector{Contingency_Series} = Contingency_Series[]
    Monitored_RegisteredResource::Vector{Monitored_RegisteredResource} = Monitored_RegisteredResource[]
    RemedialAction_Series::Vector{RemedialAction_Series} = RemedialAction_Series[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    Constraint_Series::Vector{Constraint_Series} = Constraint_Series[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Series_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    resolution::String = ""
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
end

Base.@kwdef mutable struct Action_Status
    value::String = ""
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    businessType::String = ""
    in_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    out_Domain_mRID::Union{Nothing, AreaID_String} = nothing
    curveType::String = ""
    Period::Vector{Series_Period} = Series_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct CriticalNetworkElement_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    process_processType::String = ""
    sender_MarketParticipant_mRID::PartyID_String = PartyID_String()
    sender_MarketParticipant_marketRole_type::String = ""
    receiver_MarketParticipant_mRID::PartyID_String = PartyID_String()
    receiver_MarketParticipant_marketRole_type::String = ""
    createdDateTime::DateTime = DateTime(1970)
    docStatus::Union{Nothing, Action_Status} = nothing
    Received_MarketDocument::Union{Nothing, MarketDocument} = nothing
    Related_MarketDocument::Vector{MarketDocument} = MarketDocument[]
    time_Period_timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    domain_mRID::Union{Nothing, AreaID_String} = nothing
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
    Reason::Vector{Reason} = Reason[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

function _parse(::Type{AreaID_String}, n::EzXML.Node)
    out = AreaID_String()
    if hasattribute(n, "codingScheme")
        out.codingScheme = String(n["codingScheme"])
    end
    out.value = String(strip(nodecontent(n)))
    return out
end

function _parse(::Type{Border_Series}, n::EzXML.Node)
    out = Border_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "flow_Quantity.quantity"
            out.flow_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
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

function _parse(::Type{Series_Reason}, n::EzXML.Node)
    out = Series_Reason()
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

function _parse(::Type{Shared_Domain}, n::EzXML.Node)
    out = Shared_Domain()
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

function _parse(::Type{RegisteredResource_Reason}, n::EzXML.Node)
    out = RegisteredResource_Reason()
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

function _parse(::Type{RemedialAction_RegisteredResource}, n::EzXML.Node)
    out = RemedialAction_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "pSRType.psrType"
            out.pSRType_psrType = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "in_AggregateNode.mRID"
            out.in_AggregateNode_mRID = _parse(ResourceID_String, c)
        elseif nm == "out_AggregateNode.mRID"
            out.out_AggregateNode_mRID = _parse(ResourceID_String, c)
        elseif nm == "marketObjectStatus.status"
            out.marketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.maximumCapacity"
            out.resourceCapacity_maximumCapacity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.minimumCapacity"
            out.resourceCapacity_minimumCapacity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.defaultCapacity"
            out.resourceCapacity_defaultCapacity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "resourceCapacity.unitSymbol"
            out.resourceCapacity_unitSymbol = String(strip(nodecontent(c)))
        elseif nm == "Reason"
            push!(out.Reason, _parse(RegisteredResource_Reason, c))
        end
    end
    return out
end

function _parse(::Type{RemedialAction_Series}, n::EzXML.Node)
    out = RemedialAction_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "applicationMode_MarketObjectStatus.status"
            out.applicationMode_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "quantity.quantity"
            out.quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "RegisteredResource"
            push!(out.RegisteredResource, _parse(RemedialAction_RegisteredResource, c))
        elseif nm == "Shared_Domain"
            push!(out.Shared_Domain, _parse(Shared_Domain, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Series_Reason, c))
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

function _parse(::Type{Contingency_RegisteredResource}, n::EzXML.Node)
    out = Contingency_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "Reason"
            push!(out.Reason, _parse(RegisteredResource_Reason, c))
        end
    end
    return out
end

function _parse(::Type{AdditionalConstraint_RegisteredResource}, n::EzXML.Node)
    out = AdditionalConstraint_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "Reason"
            push!(out.Reason, _parse(RegisteredResource_Reason, c))
        end
    end
    return out
end

function _parse(::Type{AdditionalConstraint_Series}, n::EzXML.Node)
    out = AdditionalConstraint_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "measurement_Unit.name"
            out.measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "quantity.quantity"
            out.quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "RegisteredResource"
            push!(out.RegisteredResource, _parse(AdditionalConstraint_RegisteredResource, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Series_Reason, c))
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

function _parse(::Type{Party_MarketParticipant}, n::EzXML.Node)
    out = Party_MarketParticipant()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(PartyID_String, c)
        end
    end
    return out
end

function _parse(::Type{Contingency_Series}, n::EzXML.Node)
    out = Contingency_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "RegisteredResource"
            push!(out.RegisteredResource, _parse(Contingency_RegisteredResource, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Series_Reason, c))
        end
    end
    return out
end

function _parse(::Type{PTDF_Domain}, n::EzXML.Node)
    out = PTDF_Domain()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(AreaID_String, c)
        elseif nm == "pTDF_Quantity.quantity"
            out.pTDF_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "pTDF_Quantity.quality"
            out.pTDF_Quantity_quality = String(strip(nodecontent(c)))
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
        elseif nm == "positiveFlowIn"
            out.positiveFlowIn = String(strip(nodecontent(c)))
        elseif nm == "analogValues.value"
            out.analogValues_value = (x -> parse(Float32, x))(strip(nodecontent(c)))
        elseif nm == "analogValues.timeStamp"
            out.analogValues_timeStamp = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "analogValues.description"
            out.analogValues_description = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Monitored_RegisteredResource}, n::EzXML.Node)
    out = Monitored_RegisteredResource()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(ResourceID_String, c)
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "in_AggregateNode.mRID"
            out.in_AggregateNode_mRID = _parse(ResourceID_String, c)
        elseif nm == "out_AggregateNode.mRID"
            out.out_AggregateNode_mRID = _parse(ResourceID_String, c)
        elseif nm == "flowBasedStudy_Domain.mRID"
            out.flowBasedStudy_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "flowBasedStudy_Domain.flowBasedMargin_Quantity.quantity"
            out.flowBasedStudy_Domain_flowBasedMargin_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "flowBasedStudy_Domain.flowBasedMargin_Quantity.quality"
            out.flowBasedStudy_Domain_flowBasedMargin_Quantity_quality = String(strip(nodecontent(c)))
        elseif nm == "marketCoupling_Domain.mRID"
            out.marketCoupling_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "marketCoupling_Domain.shadow_Price.amount"
            out.marketCoupling_Domain_shadow_Price_amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "PTDF_Domain"
            push!(out.PTDF_Domain, _parse(PTDF_Domain, c))
        elseif nm == "Measurements"
            push!(out.Measurements, _parse(Analog, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(RegisteredResource_Reason, c))
        end
    end
    return out
end

function _parse(::Type{Constraint_Series}, n::EzXML.Node)
    out = Constraint_Series()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "name"
            out.name = String(strip(nodecontent(c)))
        elseif nm == "referenceCalculation_DateAndOrTime.date"
            out.referenceCalculation_DateAndOrTime_date = (x -> Date(String(x)))(strip(nodecontent(c)))
        elseif nm == "referenceCalculation_DateAndOrTime.time"
            out.referenceCalculation_DateAndOrTime_time = String(strip(nodecontent(c)))
        elseif nm == "quantity_Measurement_Unit.name"
            out.quantity_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "externalConstraint_Quantity.quantity"
            out.externalConstraint_Quantity_quantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "externalConstraint_Quantity.quality"
            out.externalConstraint_Quantity_quality = String(strip(nodecontent(c)))
        elseif nm == "pTDF_Measurement_Unit.name"
            out.pTDF_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "shadowPrice_Measurement_Unit.name"
            out.shadowPrice_Measurement_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "currency_Unit.name"
            out.currency_Unit_name = String(strip(nodecontent(c)))
        elseif nm == "Party_MarketParticipant"
            push!(out.Party_MarketParticipant, _parse(Party_MarketParticipant, c))
        elseif nm == "optimization_MarketObjectStatus.status"
            out.optimization_MarketObjectStatus_status = String(strip(nodecontent(c)))
        elseif nm == "Border_Series"
            push!(out.Border_Series, _parse(Border_Series, c))
        elseif nm == "AdditionalConstraint_Series"
            push!(out.AdditionalConstraint_Series, _parse(AdditionalConstraint_Series, c))
        elseif nm == "Contingency_Series"
            push!(out.Contingency_Series, _parse(Contingency_Series, c))
        elseif nm == "Monitored_RegisteredResource"
            push!(out.Monitored_RegisteredResource, _parse(Monitored_RegisteredResource, c))
        elseif nm == "RemedialAction_Series"
            push!(out.RemedialAction_Series, _parse(RemedialAction_Series, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
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
        elseif nm == "Constraint_Series"
            push!(out.Constraint_Series, _parse(Constraint_Series, c))
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

function _parse(::Type{MarketDocument}, n::EzXML.Node)
    out = MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "revisionNumber"
            out.revisionNumber = String(strip(nodecontent(c)))
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

function _parse(::Type{TimeSeries}, n::EzXML.Node)
    out = TimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "in_Domain.mRID"
            out.in_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "out_Domain.mRID"
            out.out_Domain_mRID = _parse(AreaID_String, c)
        elseif nm == "curveType"
            out.curveType = String(strip(nodecontent(c)))
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

function _parse(::Type{CriticalNetworkElement_MarketDocument}, n::EzXML.Node)
    out = CriticalNetworkElement_MarketDocument()
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
        elseif nm == "docStatus"
            out.docStatus = _parse(Action_Status, c)
        elseif nm == "Received_MarketDocument"
            out.Received_MarketDocument = _parse(MarketDocument, c)
        elseif nm == "Related_MarketDocument"
            push!(out.Related_MarketDocument, _parse(MarketDocument, c))
        elseif nm == "time_Period.timeInterval"
            out.time_Period_timeInterval = _parse(ESMP_DateTimeInterval, c)
        elseif nm == "domain.mRID"
            out.domain_mRID = _parse(AreaID_String, c)
        elseif nm == "TimeSeries"
            push!(out.TimeSeries, _parse(TimeSeries, c))
        elseif nm == "Reason"
            push!(out.Reason, _parse(Reason, c))
        end
    end
    return out
end

# ---------------------------------------------------------------------------
# Entry point — parse the XML body and return the root document.

function parse_document(xml::AbstractString)::CriticalNetworkElement_MarketDocument
    return _parse(CriticalNetworkElement_MarketDocument, root(parsexml(xml)))
end

end  # module Cne_v2_0
