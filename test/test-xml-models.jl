using ENTSOE
using Test
using Dates: DateTime

# Tests for the typed XML-model layer (auto-generated from IEC 62325
# XSDs). Each generated module under `ENTSOE.XmlModels` exposes a
# `parse_document(xml)` entry point returning a fully populated struct
# tree. This is complementary to the hand-written
# `parse_timeseries`/etc. parsers — the typed layer preserves the
# entire document (mRID, createdDateTime, attributes like
# `codingScheme`, multiple TimeSeries with their full metadata), while
# the hand-written layer flattens to `(time, value)` rows.

include("_brokenrecord_helpers.jl")

@testset "XmlModels namespace is populated" begin
    # The codegen step (run before package build) emits one module per
    # XSD under `src/xml_models/`; ENTSOE.XmlModels picks them up at
    # include time. We just assert the first family is there.
    @test isdefined(ENTSOE.XmlModels, :Publication_v7_4)
end

let BR = _load_brokenrecord()
    if BR === nothing
        @info "BrokenRecord not installed; skipping XmlModels live tests."
    else
        client = ENTSOEClient("PLAYBACK")
        # Pull the raw XML from the cassette via the same `Raw()` path the
        # walkthrough uses.
        xml = Base.invokelatest(
            BR.playback,
            () -> day_ahead_prices(
                client, EIC.NL,
                DateTime("2024-09-01T22:00"), DateTime("2024-09-02T22:00"),
                Raw(),
            ),
            "market_121d_day_ahead_prices_NL.yml",
        )

        @testset "Publication_v7_4: parse_document on a real cassette" begin
            doc = ENTSOE.XmlModels.Publication_v7_4.parse_document(xml)
            # Top-level MarketDocument fields.
            @test doc.type_ == "A44"                  # Price document
            @test doc.mRID == "8c6f96f960dd43d8825846643f939b37"
            @test doc.createdDateTime isa DateTime
            @test length(doc.TimeSeries) == 1

            ts = doc.TimeSeries[1]
            # Domain mRIDs are typed structs with `value` + `codingScheme`
            # attribute (XSD simpleContent + attribute extension).
            @test ts.in_Domain_mRID.value == "10YNL----------L"
            @test ts.in_Domain_mRID.codingScheme == "A01"
            @test ts.out_Domain_mRID.value == "10YNL----------L"

            # Period / Point tree — the cassette has 24 hourly points.
            @test length(ts.Period) == 1
            period = ts.Period[1]
            @test period.resolution == "PT60M"
            @test length(period.Point) == 24

            # First and last Point — values match what `parse_timeseries`
            # produces from the same cassette.
            @test period.Point[1].position == 1
            @test period.Point[1].price_amount == 91.24
            @test period.Point[end].price_amount == 104.0

            # `quantity` is the alternative numeric field on Point —
            # absent for a price document, so it stays at the default.
            @test period.Point[1].quantity === nothing
        end

        @testset "Typed parser matches parse_timeseries point count" begin
            # Cross-check: the typed and ad-hoc parsers agree on how many
            # points / what the first numeric value is.
            doc = ENTSOE.XmlModels.Publication_v7_4.parse_document(xml)
            flat = parse_timeseries(xml)
            n_points = sum(length(p.Point) for p in doc.TimeSeries[1].Period)
            @test length(flat) == n_points
            @test flat[1].value == doc.TimeSeries[1].Period[1].Point[1].price_amount
        end
    end
end
