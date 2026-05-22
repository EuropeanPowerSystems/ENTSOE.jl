# Auto-generated from iec62325-451-7-reservationallocationresult_v6_1.xsd — DO NOT EDIT
# Re-run `gen/regenerate_xml_models.jl` to regenerate.
# Source schema namespace: urn:iec62325.351:tc57wg16:451-7:reserveallocationresultdocument:6:1

module Reservationallocationresult_v6_1

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

Base.@kwdef mutable struct Quantity
    quantity::Float64 = 0.0
end

Base.@kwdef mutable struct ESMP_DateTimeInterval
    start::String = ""
    end_::String = ""
end

Base.@kwdef mutable struct Reason
    code::String = ""
    text::Union{Nothing, String} = nothing
end

Base.@kwdef mutable struct ConstraintDuration
    duration::String = ""
end

Base.@kwdef mutable struct Price
    amount::Float64 = 0.0
end

Base.@kwdef mutable struct Point
    position::Int64 = 0
    quantity::Float64 = 0.0
    Price::Union{Nothing, Price} = nothing
    secondaryQuantity::Union{Nothing, Float64} = nothing
    Bid_Price::Union{Nothing, Price} = nothing
    BidEnergy_Price::Union{Nothing, Price} = nothing
    Energy_Price::Union{Nothing, Price} = nothing
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Series_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
    resolution::String = ""
    Point::Vector{Point} = Point[]
end

Base.@kwdef mutable struct Contract_MarketAgreement
    type_::String = ""
    mRID::String = ""
    createdDateTime::Union{Nothing, DateTime} = nothing
end

Base.@kwdef mutable struct ResourceID_String
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

Base.@kwdef mutable struct BidTimeSeries
    mRID::String = ""
end

Base.@kwdef mutable struct MarketRole
    type_::String = ""
end

Base.@kwdef mutable struct Currency_Unit
    name::String = ""
end

Base.@kwdef mutable struct AttributeInstanceComponent
    position::Int64 = 0
end

Base.@kwdef mutable struct Process
    processType::String = ""
end

Base.@kwdef mutable struct PartyID_String
    value::String = ""
    codingScheme::String = ""
end

Base.@kwdef mutable struct Auction
    mRID::String = ""
end

Base.@kwdef mutable struct Tendering_MarketParticipant
    mRID::PartyID_String = PartyID_String()
end

Base.@kwdef mutable struct FlowDirection
    direction::String = ""
end

Base.@kwdef mutable struct Measure_Unit
    name::String = ""
end

Base.@kwdef mutable struct MarketParticipant
    mRID::PartyID_String = PartyID_String()
    MarketRole::MarketRole = MarketRole()
end

Base.@kwdef mutable struct RegisteredResource
    mRID::ResourceID_String = ResourceID_String()
end

Base.@kwdef mutable struct Original_MarketDocument
    mRID::Union{Nothing, String} = nothing
    revisionNumber::Union{Nothing, String} = nothing
    Bid_BidTimeSeries::Union{Nothing, BidTimeSeries} = nothing
    Tendering_MarketParticipant::Tendering_MarketParticipant = Tendering_MarketParticipant()
end

Base.@kwdef mutable struct TimeSeries
    mRID::String = ""
    Bid_Original_MarketDocument::Original_MarketDocument = Original_MarketDocument()
    Auction::Auction = Auction()
    businessType::String = ""
    Acquiring_Domain::Domain = Domain()
    Connecting_Domain::Domain = Domain()
    MarketAgreement::Contract_MarketAgreement = Contract_MarketAgreement()
    Quantity_Measure_Unit::Measure_Unit = Measure_Unit()
    Currency_Unit::Union{Nothing, Currency_Unit} = nothing
    Price_Measure_Unit::Union{Nothing, Measure_Unit} = nothing
    Energy_Measurement_Unit::Union{Nothing, Measure_Unit} = nothing
    RegisteredResource::Union{Nothing, RegisteredResource} = nothing
    FlowDirection::FlowDirection = FlowDirection()
    MinimumActivation_Quantity::Union{Nothing, Quantity} = nothing
    StepIncrement_Quantity::Union{Nothing, Quantity} = nothing
    OrderNumber_AttributeInstanceComponent::Union{Nothing, AttributeInstanceComponent} = nothing
    Activation_ConstraintDuration::Union{Nothing, ConstraintDuration} = nothing
    Resting_ConstraintDuration::Union{Nothing, ConstraintDuration} = nothing
    Minimum_ConstraintDuration::Union{Nothing, ConstraintDuration} = nothing
    Maximum_ConstraintDuration::Union{Nothing, ConstraintDuration} = nothing
    Period::Vector{Series_Period} = Series_Period[]
    Reason::Vector{Reason} = Reason[]
end

Base.@kwdef mutable struct Time_Period
    timeInterval::ESMP_DateTimeInterval = ESMP_DateTimeInterval()
end

Base.@kwdef mutable struct ReserveAllocationResult_MarketDocument
    mRID::String = ""
    revisionNumber::String = ""
    type_::String = ""
    Process::Union{Nothing, Process} = nothing
    Sender_MarketParticipant::MarketParticipant = MarketParticipant()
    Receiver_MarketParticipant::MarketParticipant = MarketParticipant()
    createdDateTime::DateTime = DateTime(1970)
    ReserveBid_Period::Time_Period = Time_Period()
    Domain::Domain = Domain()
    TimeSeries::Vector{TimeSeries} = TimeSeries[]
    Reason::Vector{Reason} = Reason[]
end

# ---------------------------------------------------------------------------
# Parsers — walk an EzXML node and fill the corresponding struct.

function _parse(::Type{Quantity}, n::EzXML.Node)
    out = Quantity()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "quantity"
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

function _parse(::Type{ConstraintDuration}, n::EzXML.Node)
    out = ConstraintDuration()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "duration"
            out.duration = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Price}, n::EzXML.Node)
    out = Price()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "amount"
            out.amount = (x -> parse(Float64, x))(strip(nodecontent(c)))
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
        elseif nm == "Price"
            out.Price = _parse(Price, c)
        elseif nm == "secondaryQuantity"
            out.secondaryQuantity = (x -> parse(Float64, x))(strip(nodecontent(c)))
        elseif nm == "Bid_Price"
            out.Bid_Price = _parse(Price, c)
        elseif nm == "BidEnergy_Price"
            out.BidEnergy_Price = _parse(Price, c)
        elseif nm == "Energy_Price"
            out.Energy_Price = _parse(Price, c)
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

function _parse(::Type{Contract_MarketAgreement}, n::EzXML.Node)
    out = Contract_MarketAgreement()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "type"
            out.type_ = String(strip(nodecontent(c)))
        elseif nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "createdDateTime"
            out.createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
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

function _parse(::Type{BidTimeSeries}, n::EzXML.Node)
    out = BidTimeSeries()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{MarketRole}, n::EzXML.Node)
    out = MarketRole()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "type"
            out.type_ = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Currency_Unit}, n::EzXML.Node)
    out = Currency_Unit()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "name"
            out.name = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{AttributeInstanceComponent}, n::EzXML.Node)
    out = AttributeInstanceComponent()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "position"
            out.position = (x -> parse(Int64, x))(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Process}, n::EzXML.Node)
    out = Process()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "processType"
            out.processType = String(strip(nodecontent(c)))
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

function _parse(::Type{Auction}, n::EzXML.Node)
    out = Auction()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Tendering_MarketParticipant}, n::EzXML.Node)
    out = Tendering_MarketParticipant()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(PartyID_String, c)
        end
    end
    return out
end

function _parse(::Type{FlowDirection}, n::EzXML.Node)
    out = FlowDirection()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "direction"
            out.direction = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{Measure_Unit}, n::EzXML.Node)
    out = Measure_Unit()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "name"
            out.name = String(strip(nodecontent(c)))
        end
    end
    return out
end

function _parse(::Type{MarketParticipant}, n::EzXML.Node)
    out = MarketParticipant()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = _parse(PartyID_String, c)
        elseif nm == "MarketRole"
            out.MarketRole = _parse(MarketRole, c)
        end
    end
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

function _parse(::Type{Original_MarketDocument}, n::EzXML.Node)
    out = Original_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "revisionNumber"
            out.revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "Bid_BidTimeSeries"
            out.Bid_BidTimeSeries = _parse(BidTimeSeries, c)
        elseif nm == "Tendering_MarketParticipant"
            out.Tendering_MarketParticipant = _parse(Tendering_MarketParticipant, c)
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
        elseif nm == "Bid_Original_MarketDocument"
            out.Bid_Original_MarketDocument = _parse(Original_MarketDocument, c)
        elseif nm == "Auction"
            out.Auction = _parse(Auction, c)
        elseif nm == "businessType"
            out.businessType = String(strip(nodecontent(c)))
        elseif nm == "Acquiring_Domain"
            out.Acquiring_Domain = _parse(Domain, c)
        elseif nm == "Connecting_Domain"
            out.Connecting_Domain = _parse(Domain, c)
        elseif nm == "MarketAgreement"
            out.MarketAgreement = _parse(Contract_MarketAgreement, c)
        elseif nm == "Quantity_Measure_Unit"
            out.Quantity_Measure_Unit = _parse(Measure_Unit, c)
        elseif nm == "Currency_Unit"
            out.Currency_Unit = _parse(Currency_Unit, c)
        elseif nm == "Price_Measure_Unit"
            out.Price_Measure_Unit = _parse(Measure_Unit, c)
        elseif nm == "Energy_Measurement_Unit"
            out.Energy_Measurement_Unit = _parse(Measure_Unit, c)
        elseif nm == "RegisteredResource"
            out.RegisteredResource = _parse(RegisteredResource, c)
        elseif nm == "FlowDirection"
            out.FlowDirection = _parse(FlowDirection, c)
        elseif nm == "MinimumActivation_Quantity"
            out.MinimumActivation_Quantity = _parse(Quantity, c)
        elseif nm == "StepIncrement_Quantity"
            out.StepIncrement_Quantity = _parse(Quantity, c)
        elseif nm == "OrderNumber_AttributeInstanceComponent"
            out.OrderNumber_AttributeInstanceComponent = _parse(AttributeInstanceComponent, c)
        elseif nm == "Activation_ConstraintDuration"
            out.Activation_ConstraintDuration = _parse(ConstraintDuration, c)
        elseif nm == "Resting_ConstraintDuration"
            out.Resting_ConstraintDuration = _parse(ConstraintDuration, c)
        elseif nm == "Minimum_ConstraintDuration"
            out.Minimum_ConstraintDuration = _parse(ConstraintDuration, c)
        elseif nm == "Maximum_ConstraintDuration"
            out.Maximum_ConstraintDuration = _parse(ConstraintDuration, c)
        elseif nm == "Period"
            push!(out.Period, _parse(Series_Period, c))
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

function _parse(::Type{ReserveAllocationResult_MarketDocument}, n::EzXML.Node)
    out = ReserveAllocationResult_MarketDocument()
    for c in elements(n)
        local nm = nodename(c)
        if nm == "mRID"
            out.mRID = String(strip(nodecontent(c)))
        elseif nm == "revisionNumber"
            out.revisionNumber = String(strip(nodecontent(c)))
        elseif nm == "type"
            out.type_ = String(strip(nodecontent(c)))
        elseif nm == "Process"
            out.Process = _parse(Process, c)
        elseif nm == "Sender_MarketParticipant"
            out.Sender_MarketParticipant = _parse(MarketParticipant, c)
        elseif nm == "Receiver_MarketParticipant"
            out.Receiver_MarketParticipant = _parse(MarketParticipant, c)
        elseif nm == "createdDateTime"
            out.createdDateTime = (x -> DateTime(replace(String(x), "Z" => "")))(strip(nodecontent(c)))
        elseif nm == "ReserveBid_Period"
            out.ReserveBid_Period = _parse(Time_Period, c)
        elseif nm == "Domain"
            out.Domain = _parse(Domain, c)
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

function parse_document(xml::AbstractString)::ReserveAllocationResult_MarketDocument
    return _parse(ReserveAllocationResult_MarketDocument, root(parsexml(xml)))
end

end  # module Reservationallocationresult_v6_1
