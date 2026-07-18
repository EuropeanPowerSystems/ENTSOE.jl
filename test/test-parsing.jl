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

# Variable-sized-block (curveType A03) document: unchanged points are
# omitted. The 24-hour PT60M period lists only positions 1, 4 and 20 —
# the run between each holds the previous value, and position 20 holds
# through the period's <end>.
const _TS_A03_XML = """
<?xml version="1.0" encoding="utf-8"?>
<Publication_MarketDocument xmlns="urn:iec62325.351:tc57wg16:451-3:publicationdocument:7:0">
  <TimeSeries>
    <mRID>1</mRID>
    <curveType>A03</curveType>
    <Period>
      <timeInterval>
        <start>2025-01-01T00:00Z</start>
        <end>2025-01-02T00:00Z</end>
      </timeInterval>
      <resolution>PT60M</resolution>
      <Point><position>1</position><price.amount>50.0</price.amount></Point>
      <Point><position>4</position><price.amount>60.0</price.amount></Point>
      <Point><position>20</position><price.amount>70.0</price.amount></Point>
    </Period>
  </TimeSeries>
</Publication_MarketDocument>
"""

@testset "parse_timeseries — A03 forward-fill (default)" begin
    rows = parse_timeseries(_TS_A03_XML)
    @test length(rows) == 24                       # expanded to every PT60M step
    @test rows[1].time == DateTime("2025-01-01T00:00")
    @test rows[1].value == 50.0
    @test rows[3].value == 50.0                    # positions 1–3 hold 50
    @test rows[4].value == 60.0                    # position 4 changes to 60
    @test rows[19].value == 60.0                   # positions 4–19 hold 60
    @test rows[20].value == 70.0                   # position 20 changes to 70
    @test rows[24].value == 70.0                   # last block holds to <end>
    @test rows[24].time == DateTime("2025-01-01T23:00")
end

@testset "parse_timeseries — A03 fill_gaps=false keeps literal points" begin
    rows = parse_timeseries(_TS_A03_XML; fill_gaps = false)
    @test length(rows) == 3                         # only the listed points
    @test rows[1].time == DateTime("2025-01-01T00:00")
    @test rows[2].time == DateTime("2025-01-01T03:00")   # position 4
    @test rows[3].time == DateTime("2025-01-01T19:00")   # position 20
    @test (rows[1].value, rows[2].value, rows[3].value) == (50.0, 60.0, 70.0)
end

@testset "parse_timeseries — A01-style docs are never expanded" begin
    # No <curveType> (and the explicit A01 form) must stay literal even
    # when the declared interval is longer than the listed points.
    rows = parse_timeseries(_TS_PRICE_XML)           # 24h interval, 3 points, no curveType
    @test length(rows) == 3
    a01 = replace(_TS_A03_XML, "<curveType>A03</curveType>" => "<curveType>A01</curveType>")
    @test length(parse_timeseries(a01)) == 3
end

@testset "parse_timeseries — fill_gaps honours set_config default" begin
    try
        ENTSOE.set_config(; fill_gaps = false)
        @test length(parse_timeseries(_TS_A03_XML)) == 3   # global default off
    finally
        ENTSOE.set_config(; fill_gaps = true)              # restore
    end
    @test length(parse_timeseries(_TS_A03_XML)) == 24
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
    @test PSR_LABELS.B16 == "Solar"           # codes table sanity
    @test PSR_LABELS.B19 == "Wind Onshore"
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

    # Unknown resolution → @warn (max-once) + the offending Period is
    # silently dropped. Avoids crashing batch imports when ENTSO-E
    # starts emitting a new ISO-8601 duration we haven't seen.
    let rows = @test_logs (:warn, r"unsupported resolution") parse_timeseries(_ts_xml("PT42M"))
        @test isempty(rows)   # the only Period was skipped
    end
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

@testset "parse_unavailability_curve — per-15-min curtailment trajectory" begin
    # Modelled on a real Outages 15.1.A/B document: one TimeSeries with
    # a single Available_Period describing the unit's curtailed output
    # at 15-minute resolution. parse_unavailability_curve returns one
    # row per timestamp, parse_unavailability returns one row per event.
    xml = """
    <?xml version="1.0"?><Unavailability_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <mRID>1</mRID>
        <production_RegisteredResource.mRID>22WRODENH000213L</production_RegisteredResource.mRID>
        <production_RegisteredResource.name>RODENHUIZE 4</production_RegisteredResource.name>
        <Available_Period>
          <timeInterval>
            <start>2024-01-15T08:00Z</start><end>2024-01-15T09:00Z</end>
          </timeInterval>
          <resolution>PT15M</resolution>
          <Point><position>1</position><quantity>0</quantity></Point>
          <Point><position>2</position><quantity>50</quantity></Point>
          <Point><position>3</position><quantity>100</quantity></Point>
          <Point><position>4</position><quantity>268</quantity></Point>
        </Available_Period>
      </TimeSeries>
    </Unavailability_MarketDocument>
    """
    rows = parse_unavailability_curve(xml)
    @test length(rows) == 4
    @test rows[1].time == DateTime("2024-01-15T08:00")
    @test rows[4].time == DateTime("2024-01-15T08:45")
    @test rows[1].resource_name == "RODENHUIZE 4"
    @test rows[1].resource_mrid == "22WRODENH000213L"
    @test rows[1].available_mw == 0.0
    @test rows[4].available_mw == 268.0     # back to full nominal
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

@testset "parse_timeseries_per_psr strips pretty-printed psrType" begin
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <GL_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <MktPSRType>
          <psrType>
            B16
          </psrType>
        </MktPSRType>
        <Period>
          <timeInterval><start>2024-09-01T22:00Z</start><end>2024-09-01T23:00Z</end></timeInterval>
          <resolution>PT60M</resolution>
          <Point><position>1</position><quantity>10.0</quantity></Point>
        </Period>
      </TimeSeries>
    </GL_MarketDocument>
    """
    rows = ENTSOE.parse_timeseries_per_psr(xml)
    @test length(rows) == 1
    @test rows.psr_type[1] == "B16"
end

@testset "parse_unavailability_curve accepts *.amount value nodes" begin
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <Unavailability_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <production_RegisteredResource><mRID>U1</mRID><name>Unit 1</name></production_RegisteredResource>
        <Available_Period>
          <timeInterval><start>2024-05-01T00:00Z</start><end>2024-05-01T01:00Z</end></timeInterval>
          <resolution>PT60M</resolution>
          <Point><position>1</position><curtailed_Quantity.amount>120.0</curtailed_Quantity.amount></Point>
        </Available_Period>
      </TimeSeries>
    </Unavailability_MarketDocument>
    """
    rows = ENTSOE.parse_unavailability_curve(xml)
    @test length(rows) == 1
    @test rows.available_mw[1] == 120.0
end

@testset "parse_timeseries — P1M periods step by calendar month" begin
    # Position 2 of a monthly series starting Jan 1 must be Feb 1 — not
    # Jan 31 (start + 30 nominal days). Shape mirrors 13.1.C congestion
    # costs (tut_costs_BE_2022.yml).
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <CongestionCosts_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <curveType>A01</curveType>
        <Period>
          <timeInterval><start>2022-01-01T00:00Z</start><end>2023-01-01T00:00Z</end></timeInterval>
          <resolution>P1M</resolution>
          $(join(["<Point><position>$p</position><congestionCost_Price.amount>$(p * 10.0)</congestionCost_Price.amount></Point>" for p in 1:12], "\n"))
        </Period>
      </TimeSeries>
    </CongestionCosts_MarketDocument>
    """
    rows = ENTSOE.parse_timeseries(xml)
    @test length(rows) == 12
    @test rows.time == [DateTime(2022, m, 1) for m in 1:12]
    @test rows.value == [p * 10.0 for p in 1:12]
end

@testset "parse_timeseries — P1M A03 fill counts calendar months" begin
    # A single point covering Jan–Mar must fill 3 monthly rows; the old
    # nominal-30-day arithmetic computed div(90d, 30d)=3 only by luck and
    # yielded 0 for a single short month (February).
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <CongestionCosts_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <curveType>A03</curveType>
        <Period>
          <timeInterval><start>2022-01-01T00:00Z</start><end>2022-04-01T00:00Z</end></timeInterval>
          <resolution>P1M</resolution>
          <Point><position>1</position><quantity>7.0</quantity></Point>
        </Period>
      </TimeSeries>
    </CongestionCosts_MarketDocument>
    """
    rows = ENTSOE.parse_timeseries(xml; fill_gaps = true)
    @test rows.time == [DateTime(2022, 1, 1), DateTime(2022, 2, 1), DateTime(2022, 3, 1)]
    @test all(rows.value .== 7.0)

    feb = """<?xml version="1.0" encoding="UTF-8"?>
    <Doc xmlns="urn:x">
      <TimeSeries>
        <curveType>A03</curveType>
        <Period>
          <timeInterval><start>2022-02-01T00:00Z</start><end>2022-03-01T00:00Z</end></timeInterval>
          <resolution>P1M</resolution>
          <Point><position>1</position><quantity>3.0</quantity></Point>
        </Period>
      </TimeSeries>
    </Doc>
    """
    rows_feb = ENTSOE.parse_timeseries(feb; fill_gaps = true)
    @test rows_feb.time == [DateTime(2022, 2, 1)]
    @test rows_feb.value == [3.0]
end

@testset "parse_timeseries — P1Y periods step by calendar year" begin
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <Doc xmlns="urn:x">
      <TimeSeries>
        <curveType>A01</curveType>
        <Period>
          <timeInterval><start>2020-01-01T00:00Z</start><end>2023-01-01T00:00Z</end></timeInterval>
          <resolution>P1Y</resolution>
          <Point><position>1</position><quantity>1.0</quantity></Point>
          <Point><position>2</position><quantity>2.0</quantity></Point>
          <Point><position>3</position><quantity>3.0</quantity></Point>
        </Period>
      </TimeSeries>
    </Doc>
    """
    rows = ENTSOE.parse_timeseries(xml)
    # 2020 is a leap year: nominal 365-day stepping would land position 2
    # on 2020-12-31T00:00 instead of 2021-01-01.
    @test rows.time == [DateTime(2020, 1, 1), DateTime(2021, 1, 1), DateTime(2022, 1, 1)]
end

@testset "parse_timeseries — A03 fill stops at explicitly valueless points" begin
    # Real shape (balancing_if_afrr316_cbmps_DE_AMPRION.yml): a listed
    # <Point> with a <position> but no value element marks "no value here" —
    # the previous run must stop before it and no value may be fabricated
    # until the next valued point.
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <Doc xmlns="urn:x">
      <TimeSeries>
        <curveType>A03</curveType>
        <Period>
          <timeInterval><start>2024-01-01T00:00Z</start><end>2024-01-01T08:00Z</end></timeInterval>
          <resolution>PT60M</resolution>
          <Point><position>1</position><quantity>10.0</quantity></Point>
          <Point><position>3</position></Point>
          <Point><position>5</position><quantity>50.0</quantity></Point>
        </Period>
      </TimeSeries>
    </Doc>
    """
    rows = ENTSOE.parse_timeseries(xml; fill_gaps = true)
    @test rows.time == [
        DateTime(2024, 1, 1, 0), DateTime(2024, 1, 1, 1),          # run of 10.0: pos 1–2
        DateTime(2024, 1, 1, 4), DateTime(2024, 1, 1, 5),          # run of 50.0: pos 5–8
        DateTime(2024, 1, 1, 6), DateTime(2024, 1, 1, 7),
    ]
    @test rows.value == [10.0, 10.0, 50.0, 50.0, 50.0, 50.0]
end

@testset "_parse_entsoe_datetime — offsets and seconds" begin
    P = ENTSOE._parse_entsoe_datetime
    # The classic ENTSO-E shapes, unchanged.
    @test P("2024-09-01T22:00Z") == DateTime(2024, 9, 1, 22, 0)
    @test P("2024-09-01T22:00") == DateTime(2024, 9, 1, 22, 0)
    @test P("2024-05-01T00:00:00Z") == DateTime(2024, 5, 1)
    # Non-zero seconds must survive (PT1M grids misalign otherwise).
    @test P("2024-09-01T22:00:30Z") == DateTime(2024, 9, 1, 22, 0, 30)
    # A numeric UTC offset must be applied, not silently discarded.
    @test P("2024-01-01T00:00:00+01:00") == DateTime(2023, 12, 31, 23, 0)
    @test P("2024-01-01T00:00-01:30") == DateTime(2024, 1, 1, 1, 30)
end

@testset "parse_unavailability — transmission outages (Asset_RegisteredResource)" begin
    # 10.1.x / offshore documents identify the asset via
    # Asset_RegisteredResource, not production_RegisteredResource. Shapes
    # mirror the committed redispatch/offshore cassettes: mRID + name (or
    # location.name) + pSRType.psrType (or asset_PSRType.psrType).
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <Unavailability_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <businessType>A54</businessType>
        <start_DateAndOrTime.date>2023-10-31</start_DateAndOrTime.date>
        <start_DateAndOrTime.time>23:00:00Z</start_DateAndOrTime.time>
        <end_DateAndOrTime.date>2023-11-01</end_DateAndOrTime.date>
        <end_DateAndOrTime.time>23:00:00Z</end_DateAndOrTime.time>
        <Asset_RegisteredResource>
          <mRID codingScheme="A01">49T000000000436O</mRID>
          <pSRType.psrType>B21</pSRType.psrType>
          <location.name>Hardenberg - Ommen 110 kV</location.name>
        </Asset_RegisteredResource>
      </TimeSeries>
      <TimeSeries>
        <businessType>A53</businessType>
        <start_DateAndOrTime.date>2024-05-01</start_DateAndOrTime.date>
        <end_DateAndOrTime.date>2024-05-03</end_DateAndOrTime.date>
        <Asset_RegisteredResource>
          <mRID>11T0-0000-0044-X</mRID>
          <name>DolWin1</name>
          <asset_PSRType.psrType>B22</asset_PSRType.psrType>
        </Asset_RegisteredResource>
      </TimeSeries>
    </Unavailability_MarketDocument>
    """
    rows = ENTSOE.parse_unavailability(xml)
    @test length(rows) == 2
    @test rows.resource_mrid[1] == "49T000000000436O"
    @test rows.resource_name[1] == "Hardenberg - Ommen 110 kV"
    @test rows.psr_type[1] == "B21"
    @test rows.resource_mrid[2] == "11T0-0000-0044-X"
    @test rows.resource_name[2] == "DolWin1"
    @test rows.psr_type[2] == "B22"
end

@testset "parse_unavailability — stop spans the LAST Available_Period" begin
    # No start/end_DateAndOrTime fields: bounds fall back to the
    # Available_Period intervals. A curve split across two periods must
    # report the full window, not just the first sub-period.
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <Unavailability_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <businessType>A53</businessType>
        <production_RegisteredResource><mRID>U9</mRID><name>Unit 9</name></production_RegisteredResource>
        <Available_Period>
          <timeInterval><start>2024-05-01T00:00Z</start><end>2024-05-03T00:00Z</end></timeInterval>
          <resolution>PT60M</resolution>
          <Point><position>1</position><quantity>100.0</quantity></Point>
        </Available_Period>
        <Available_Period>
          <timeInterval><start>2024-05-03T00:00Z</start><end>2024-05-10T00:00Z</end></timeInterval>
          <resolution>PT60M</resolution>
          <Point><position>1</position><quantity>50.0</quantity></Point>
        </Available_Period>
      </TimeSeries>
    </Unavailability_MarketDocument>
    """
    rows = ENTSOE.parse_unavailability(xml)
    @test length(rows) == 1
    @test rows.start[1] == DateTime(2024, 5, 1)
    @test rows.stop[1] == DateTime(2024, 5, 10)
end

@testset "parse_timeseries_quantity_price — dual-value points (17.1.B&C)" begin
    # Points on "volumes AND prices of contracted reserves" carry BOTH a
    # <quantity> (MW) and a <procurement_Price.amount> (EUR/MW); a single
    # value column can only keep one of them.
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <Balancing_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <curveType>A01</curveType>
        <Period>
          <timeInterval><start>2024-09-01T22:00Z</start><end>2024-09-02T00:00Z</end></timeInterval>
          <resolution>PT60M</resolution>
          <Point><position>1</position><quantity>600.0</quantity><procurement_Price.amount>11.5</procurement_Price.amount></Point>
          <Point><position>2</position><quantity>580.0</quantity></Point>
        </Period>
      </TimeSeries>
    </Balancing_MarketDocument>
    """
    rows = ENTSOE.parse_timeseries_quantity_price(xml)
    @test length(rows) == 2
    @test rows.time == [DateTime(2024, 9, 1, 22), DateTime(2024, 9, 1, 23)]
    @test rows.quantity == [600.0, 580.0]
    @test rows.price[1] == 11.5
    @test isnan(rows.price[2])
end

@testset "parse_timeseries_quantity_price — A03 fill carries both columns" begin
    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <Balancing_MarketDocument xmlns="urn:x">
      <TimeSeries>
        <curveType>A03</curveType>
        <Period>
          <timeInterval><start>2024-09-01T00:00Z</start><end>2024-09-01T04:00Z</end></timeInterval>
          <resolution>PT60M</resolution>
          <Point><position>1</position><quantity>100.0</quantity><procurement_Price.amount>5.0</procurement_Price.amount></Point>
          <Point><position>3</position><quantity>200.0</quantity><procurement_Price.amount>6.0</procurement_Price.amount></Point>
        </Period>
      </TimeSeries>
    </Balancing_MarketDocument>
    """
    rows = ENTSOE.parse_timeseries_quantity_price(xml; fill_gaps = true)
    @test rows.quantity == [100.0, 100.0, 200.0, 200.0]
    @test rows.price == [5.0, 5.0, 6.0, 6.0]
end
