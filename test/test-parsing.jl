using ENTSOE
using Test
using Dates: DateTime

# unzip_response uses ZipFile.jl on demand. The package is in
# test/Project.toml only when present; the test self-skips otherwise so
# adding it later just turns this section on.
const _ZIPFILE_AVAILABLE = Base.identify_package("ZipFile") !== nothing

# Small synthetic XML payloads modelled on real ENTSO-E responses,
# kept inline so the parser tests don't depend on cassettes being
# loadable (they're already covered by `test-cassettes.jl`).

const _TS_PRICE_XML = """
<?xml version="1.0" encoding="utf-8"?>
<Publication_MarketDocument xmlns="urn:iec62325.351:tc57wg16:451-3:publicationdocument:7:0">
  <mRID>x</mRID>
  <TimeSeries>
    <mRID>1</mRID>
    <Period>
      <timeInterval>
        <start>2024-09-01T22:00Z</start>
        <end>2024-09-02T22:00Z</end>
      </timeInterval>
      <resolution>PT60M</resolution>
      <Point><position>1</position><price.amount>50.10</price.amount></Point>
      <Point><position>2</position><price.amount>49.30</price.amount></Point>
      <Point><position>3</position><price.amount>-2.00</price.amount></Point>
    </Period>
  </TimeSeries>
</Publication_MarketDocument>
"""

const _TS_LOAD_XML = """
<?xml version="1.0" encoding="utf-8"?>
<GL_MarketDocument xmlns="urn:iec62325.351:tc57wg16:451-6:generationloaddocument:3:0">
  <TimeSeries>
    <Period>
      <timeInterval>
        <start>2024-09-01T22:00Z</start>
        <end>2024-09-02T22:00Z</end>
      </timeInterval>
      <resolution>PT15M</resolution>
      <Point><position>1</position><quantity>12156.45</quantity></Point>
      <Point><position>2</position><quantity>12001.76</quantity></Point>
    </Period>
  </TimeSeries>
</GL_MarketDocument>
"""

const _CAPACITY_XML = """
<?xml version="1.0" encoding="utf-8"?>
<GL_MarketDocument xmlns="urn:iec62325.351:tc57wg16:451-6:generationloaddocument:3:0">
  <TimeSeries>
    <MktPSRType><psrType>B16</psrType></MktPSRType>
    <Period>
      <timeInterval><start>2023-12-31T23:00Z</start><end>2024-12-31T23:00Z</end></timeInterval>
      <resolution>P1Y</resolution>
      <Point><position>1</position><quantity>22850.0</quantity></Point>
    </Period>
  </TimeSeries>
  <TimeSeries>
    <MktPSRType><psrType>B19</psrType></MktPSRType>
    <Period>
      <timeInterval><start>2023-12-31T23:00Z</start><end>2024-12-31T23:00Z</end></timeInterval>
      <resolution>P1Y</resolution>
      <Point><position>1</position><quantity>5500.0</quantity></Point>
    </Period>
  </TimeSeries>
</GL_MarketDocument>
"""

const _ACK_XML = """
<?xml version="1.0" encoding="utf-8"?>
<Acknowledgement_MarketDocument xmlns="urn:iec62325.351:tc57wg16:451-1:acknowledgementdocument:7:0">
  <mRID>x</mRID>
  <Reason>
    <code>999</code>
    <text>No matching data found</text>
  </Reason>
</Acknowledgement_MarketDocument>
"""

@testset "parse_timeseries — prices" begin
    rows = parse_timeseries(_TS_PRICE_XML)
    @test length(rows) == 3
    @test rows[1].time == DateTime("2024-09-01T22:00")
    @test rows[1].value == 50.1
    @test rows[2].time == DateTime("2024-09-01T23:00")  # +1 hour @ PT60M
    @test rows[3].value == -2.0                          # negative price OK
end

@testset "parse_timeseries — load (PT15M)" begin
    rows = parse_timeseries(_TS_LOAD_XML)
    @test length(rows) == 2
    @test rows[1].time == DateTime("2024-09-01T22:00")
    @test rows[1].value == 12156.45
    @test rows[2].time == DateTime("2024-09-01T22:15")  # +15 min @ PT15M
end

@testset "parse_timeseries — empty/acknowledgement document" begin
    # The acknowledgement document has no <TimeSeries>, so the parser
    # returns an empty vector rather than throwing.
    @test parse_timeseries(_ACK_XML) == []
end

@testset "parse_installed_capacity" begin
    rows = parse_installed_capacity(_CAPACITY_XML)
    @test length(rows) == 2
    @test rows[1].psr_type == "B16"
    @test rows[1].capacity_mw == 22850.0
    @test rows[2].psr_type == "B19"
    @test PSR_TYPE.B16 == "Solar"           # codes table sanity
    @test PSR_TYPE.B19 == "Wind Onshore"
end

@testset "parse_acknowledgement" begin
    ack = parse_acknowledgement(_ACK_XML)
    @test ack isa ENTSOEAcknowledgement
    @test ack isa ENTSOE.APIError
    @test ack.reason_code == "999"
    @test ack.text == "No matching data found"

    # Non-acknowledgement documents return `nothing`.
    @test parse_acknowledgement(_TS_PRICE_XML) === nothing
    @test parse_acknowledgement(_TS_LOAD_XML) === nothing
end

@testset "parse_timeseries — extended resolutions" begin
    # The resolutions table covers PT1H, P1D, P7D, P1M, P1Y as nominal
    # mappings. We don't see all of these in production today; pass a
    # synthetic doc through each branch to cover the table.
    function _ts_xml(resolution)
        """
        <?xml version="1.0"?><GL_MarketDocument xmlns="urn:x">
          <TimeSeries><Period>
            <timeInterval><start>2024-01-01T00:00Z</start><end>2024-01-02T00:00Z</end></timeInterval>
            <resolution>$resolution</resolution>
            <Point><position>1</position><quantity>10.0</quantity></Point>
          </Period></TimeSeries>
        </GL_MarketDocument>
        """
    end

    # Sub-quarter-hour resolutions (PT1M, PT5M, PT10M) are also valid —
    # balancing 1.2.3.A in particular emits PT1M for some control areas.
    for res in ("PT1M", "PT5M", "PT10M", "PT1H", "P1D", "P7D", "P1M", "P1Y")
        rows = parse_timeseries(_ts_xml(res))
        @test length(rows) == 1
        @test rows[1].value == 10.0
    end

    # Unknown resolution → loud error.
    @test_throws ErrorException parse_timeseries(_ts_xml("PT42M"))
end

@testset "parse_unavailability — aggregated consumption-units shape" begin
    # Modelled on the real outages71_a_b cassette: bounds split across
    # start_DateAndOrTime.{date,time} siblings, no production_RegisteredResource,
    # no nominal_P.
    xml = """
    <?xml version="1.0"?><Unavailability_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <mRID>1</mRID>
        <businessType>A53</businessType>
        <start_DateAndOrTime.date>2023-11-30</start_DateAndOrTime.date>
        <start_DateAndOrTime.time>11:00:00Z</start_DateAndOrTime.time>
        <end_DateAndOrTime.date>2023-11-30</end_DateAndOrTime.date>
        <end_DateAndOrTime.time>23:00:00Z</end_DateAndOrTime.time>
        <Available_Period>
          <timeInterval>
            <start>2023-11-30T11:00Z</start><end>2023-11-30T23:00Z</end>
          </timeInterval>
          <resolution>PT15M</resolution>
          <Point><position>1</position><quantity>126</quantity></Point>
        </Available_Period>
      </TimeSeries>
    </Unavailability_MarketDocument>
    """
    rows = parse_unavailability(xml)
    @test length(rows) == 1
    @test rows[1].start == DateTime("2023-11-30T11:00:00")
    @test rows[1].stop == DateTime("2023-11-30T23:00:00")
    @test rows[1].business_type == "A53"
    @test rows[1].resource_name == ""    # aggregated — no per-unit name
    @test rows[1].resource_mrid == ""
    @test rows[1].psr_type == ""
    @test isnan(rows[1].nominal_mw)
end

@testset "parse_unavailability — generation-unit shape with resource + nominal" begin
    # Synthetic, modelled on Outages 15.1.A/B. Production_RegisteredResource
    # is populated with name + mRID + pSRType, and a nominal_P is given.
    xml = """
    <?xml version="1.0"?><Unavailability_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <mRID>1</mRID>
        <businessType>A54</businessType>
        <start_DateAndOrTime.date>2024-01-15</start_DateAndOrTime.date>
        <start_DateAndOrTime.time>08:00:00Z</start_DateAndOrTime.time>
        <end_DateAndOrTime.date>2024-01-15</end_DateAndOrTime.date>
        <end_DateAndOrTime.time>18:00:00Z</end_DateAndOrTime.time>
        <nominal_P unit="MAW">485.0</nominal_P>
        <production_RegisteredResource>
          <mRID codingScheme="A01">22WCOOX6X000064W</mRID>
          <name>Tihange-3</name>
          <pSRType><psrType>B14</psrType></pSRType>
        </production_RegisteredResource>
      </TimeSeries>
    </Unavailability_MarketDocument>
    """
    rows = parse_unavailability(xml)
    @test length(rows) == 1
    @test rows[1].start == DateTime("2024-01-15T08:00:00")
    @test rows[1].stop == DateTime("2024-01-15T18:00:00")
    @test rows[1].business_type == "A54"
    @test rows[1].resource_name == "Tihange-3"
    @test rows[1].resource_mrid == "22WCOOX6X000064W"
    @test rows[1].psr_type == "B14"   # Nuclear
    @test rows[1].nominal_mw == 485.0
end

@testset "parse_unavailability — empty document returns empty StructVector" begin
    xml = """<?xml version="1.0"?><Unavailability_MarketDocument xmlns="urn:x"></Unavailability_MarketDocument>"""
    @test length(parse_unavailability(xml)) == 0
end

@testset "parse_unavailability — flat dot-notation form (real ENTSO-E shape)" begin
    # Real outages XML uses sibling elements with dot-flattened names
    # under TimeSeries, NOT a nested <production_RegisteredResource>
    # wrapper. The parser must handle this form too.
    xml = """
    <?xml version="1.0"?><Unavailability_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <mRID>1</mRID>
        <businessType>A53</businessType>
        <start_DateAndOrTime.date>2023-10-11</start_DateAndOrTime.date>
        <start_DateAndOrTime.time>15:37:00Z</start_DateAndOrTime.time>
        <end_DateAndOrTime.date>2024-03-05</end_DateAndOrTime.date>
        <end_DateAndOrTime.time>08:00:00Z</end_DateAndOrTime.time>
        <production_RegisteredResource.mRID>22WRODENH000213L</production_RegisteredResource.mRID>
        <production_RegisteredResource.name>RODENHUIZE 4</production_RegisteredResource.name>
        <production_RegisteredResource.pSRType.psrType>B01</production_RegisteredResource.pSRType.psrType>
        <production_RegisteredResource.pSRType.powerSystemResources.nominalP unit="MAW">268.0</production_RegisteredResource.pSRType.powerSystemResources.nominalP>
      </TimeSeries>
    </Unavailability_MarketDocument>
    """
    rows = parse_unavailability(xml)
    @test length(rows) == 1
    @test rows[1].resource_name == "RODENHUIZE 4"
    @test rows[1].resource_mrid == "22WRODENH000213L"
    @test rows[1].psr_type == "B01"
    @test rows[1].nominal_mw == 268.0
end

@testset "parse_timeseries — picks up <*.amount> fields" begin
    # Transmission 13.1.C uses <congestionCost_Price.amount> instead of
    # <quantity> or <price.amount>. The generic `*.amount` matcher should
    # find it.
    xml = """
    <?xml version="1.0"?><MarketDocument xmlns="urn:x">
      <TimeSeries><Period>
        <timeInterval><start>2024-09-01T22:00Z</start><end>2024-09-02T22:00Z</end></timeInterval>
        <resolution>PT60M</resolution>
        <Point><position>1</position><congestionCost_Price.amount>1074741.41</congestionCost_Price.amount></Point>
        <Point><position>2</position><congestionCost_Price.amount>43840</congestionCost_Price.amount></Point>
      </Period></TimeSeries>
    </MarketDocument>
    """
    rows = parse_timeseries(xml)
    @test length(rows) == 2
    @test rows[1].value == 1074741.41
    @test rows[2].value == 43840.0
end

@testset "parse_timeseries_per_psr — TimeSeries without MktPSRType" begin
    # Some flavours of the document omit `<MktPSRType>`; the parser then
    # tags rows with `psr_type = ""`.
    xml = """
    <?xml version="1.0"?><GL_MarketDocument xmlns="urn:x">
      <TimeSeries><Period>
        <timeInterval><start>2024-01-01T00:00Z</start><end>2024-01-01T01:00Z</end></timeInterval>
        <resolution>PT60M</resolution>
        <Point><position>1</position><quantity>5.0</quantity></Point>
      </Period></TimeSeries>
    </GL_MarketDocument>
    """
    rows = parse_timeseries_per_psr(xml)
    @test length(rows) == 1
    @test rows[1].psr_type == ""   # the missing-MktPSRType fallback
end

@testset "unzip_response" begin
    if !_ZIPFILE_AVAILABLE
        @info "ZipFile not installed; skipping unzip_response live tests."
    else
        # Build a tiny ZIP in-memory with two entries, then round-trip
        # through `unzip_response`.
        ZipFile = Base.require(Base.identify_package("ZipFile"))
        buf = IOBuffer()
        w = Base.invokelatest(ZipFile.Writer, buf)
        f1 = Base.invokelatest(ZipFile.addfile, w, "first.xml")
        Base.invokelatest(write, f1, "<a/>")
        f2 = Base.invokelatest(ZipFile.addfile, w, "second.xml")
        Base.invokelatest(write, f2, "<b/>")
        Base.invokelatest(close, w)

        zip_bytes = take!(buf)
        members = unzip_response(zip_bytes)
        @test length(members) == 2
        names = [p.first for p in members]
        @test "first.xml" in names
        @test "second.xml" in names
        @test String(members[findfirst(p -> p.first == "first.xml", members)].second) == "<a/>"
    end
end

@testset "Base.show(::ENTSOEAcknowledgement)" begin
    ack = ENTSOEAcknowledgement("999", "No matching data")
    s = sprint(show, ack)
    @test occursin("999", s)
    @test occursin("No matching data", s)
end

@testset "check_acknowledgement" begin
    # Pass-through on non-acknowledgement payloads.
    @test check_acknowledgement(_TS_PRICE_XML) === _TS_PRICE_XML
    @test check_acknowledgement(_TS_LOAD_XML) === _TS_LOAD_XML

    # Throws on acknowledgement payload, with a useful message.
    err = try
        check_acknowledgement(_ACK_XML)
        nothing
    catch e
        e
    end
    @test err isa ENTSOEAcknowledgement
    @test err.reason_code == "999"
    msg = sprint(showerror, err)
    @test occursin("999", msg)
    @test occursin("No matching data", msg)
end

include("_brokenrecord_helpers.jl")

@testset "parse_timeseries — cassette payload (live integration)" begin
    # End-to-end shape check against the committed Load cassette
    # body — proves the parser handles the real ENTSO-E XML produced
    # by `load61_a_actual_total_load`. We replay the cassette through
    # BrokenRecord (no network) and parse the result.
    let BR = _load_brokenrecord()
        if BR === nothing
            @info "BrokenRecord not installed; skipping live cassette parse."
        else
            client = ENTSOEClient("PLAYBACK")
            apis = entsoe_apis(client)
            xml, _ = Base.invokelatest(
                BR.playback,
                () -> ENTSOE.load61_a_actual_total_load(
                    apis.load, "A65", "A16", EIC.NL,
                    entsoe_period(DateTime("2024-09-01T22:00")),
                    entsoe_period(DateTime("2024-09-02T22:00")),
                ),
                "load_61a_actual_total_load_NL.yml",
            )
            rows = parse_timeseries(xml)
            @test !isempty(rows)
            # 24 hours @ PT15M = 96 quarter-hourly points.
            @test length(rows) == 96
            @test rows[1].time == DateTime("2024-09-01T22:00")
            @test rows[1].value > 1_000  # NL load is always thousands of MW
        end
    end
end
