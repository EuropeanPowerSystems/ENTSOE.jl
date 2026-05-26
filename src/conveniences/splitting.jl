# Request splitting for queries that exceed ENTSO-E's per-call period
# limits.
#
# The Transparency Platform caps most time-series endpoints at "one year
# per request". A naive call covering five years silently returns only
# the first year. This file splits a long period into a sequence of
# bounded windows, calls a query function for each, and concatenates the
# results.

using Dates: Dates, DateTime, Date, Year, Period
using TimeZones: ZonedDateTime, astimezone, TimeZone
const _SPLIT_UTC = TimeZone("UTC")

# A zoned timestamp is normalised to its UTC wall-clock DateTime, matching
# `entsoe_period(::ZonedDateTime)`. Must precede the AbstractDateTime branch:
# `DateTime(zdt)` alone would drop the offset without shifting to UTC.
_to_datetime(z::ZonedDateTime) = DateTime(astimezone(z, _SPLIT_UTC))

# Internal: invert `_to_period`. Accept anything `_to_period` accepts
# and produce a `DateTime`. Used by `_split_query` to chunk the period
# arithmetically before feeding chunks back into the wrapper.
function _to_datetime(t)
    t isa DateTime && return t
    t isa Date && return DateTime(t)
    t isa Dates.AbstractDateTime && return DateTime(t)
    if t isa Integer
        s = lpad(string(t), 12, '0')
        return DateTime(
            parse(Int, s[1:4]),     # yyyy
            parse(Int, s[5:6]),     # MM
            parse(Int, s[7:8]),     # dd
            parse(Int, s[9:10]),    # HH
            parse(Int, s[11:12])
        )   # mm
    end
    throw(ArgumentError("don't know how to convert $(typeof(t)) to DateTime"))
end

"""
    split_period(start, stop; window=Year(1)) -> Vector{Tuple{DateTime, DateTime}}

Slice the half-open interval `[start, stop)` into consecutive
`(window_start, window_end)` chunks of at most `window` length. The
last chunk is short if the total period isn't an exact multiple of
`window`. Accepts `DateTime`, `Date`, or `yyyymmddHHMM` integer
endpoints.

This is the pure arithmetic primitive; the named wrappers reuse it
internally (via `_split_query`) to fetch one chunk per window and
concatenate the results automatically.

```jldoctest
julia> using Dates

julia> split_period(DateTime("2022-01-01"), DateTime("2025-01-01"); window = Year(1))
3-element Vector{Tuple{DateTime, DateTime}}:
 (DateTime("2022-01-01T00:00:00"), DateTime("2023-01-01T00:00:00"))
 (DateTime("2023-01-01T00:00:00"), DateTime("2024-01-01T00:00:00"))
 (DateTime("2024-01-01T00:00:00"), DateTime("2025-01-01T00:00:00"))
```
"""
function split_period(start, stop; window::Period = Year(1))
    s = _to_datetime(start)
    e = _to_datetime(stop)
    s <= e || throw(ArgumentError("start ($s) must be ≤ stop ($e)"))
    chunks = Tuple{DateTime, DateTime}[]
    cursor = s
    while cursor < e
        nxt = min(cursor + window, e)
        push!(chunks, (cursor, nxt))
        cursor = nxt
    end
    return chunks
end
