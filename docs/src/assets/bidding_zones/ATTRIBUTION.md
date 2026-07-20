# Bidding-zone GeoJSON — attribution

The `*.geojson` files in this directory are **not** original to ENTSOE.jl. They
are vendored, unmodified, from the **`entsoe-py`** project:

- Source: <https://github.com/EnergieID/entsoe-py/tree/master/entsoe/geo/geojson>
- Author: **EnergieID cvba-so** and the `entsoe-py` contributors
- License: **MIT** (© 2017 EnergieID cvba-so) — the same permissive licence as
  ENTSOE.jl, so redistribution here is fine as long as this credit is kept.

We use them only as documentation assets to draw the bidding-zone map in the
cross-border flows tutorial (`docs/src/tutorial_flow_map.md`); they are not part
of the importable Julia package.

## Provenance of the shapes (per `entsoe-py`'s own README)

- **Single-zone countries:** [Natural Earth](https://www.naturalearthdata.com/downloads/10m-cultural-vectors/)
  10 m Admin-0 cultural vectors.
- **Norway (NO_1…NO_5):** [NVE Temakart](https://temakart.nve.no/link/?link=vannkraft).
- **Sweden (SE_1…SE_4):** based on <https://www.natomraden.se/> (manually redrawn).
- **Italy (IT_*):** regions aggregated per the GME (Gestore dei Mercati
  Energetici) market-zone definition, as documented in `entsoe-py`'s
  README.

Rings were rewound to RFC 7946 winding order with `geojson-rewind`.

## File naming

Each file is one `FeatureCollection` with a single feature carrying a
`zoneName` property (e.g. `NL`, `DE_LU`, `NO_2`). The `_2020`-suffixed Italian
files (`IT_CNOR_2020`, `IT_CSUD_2020`, `IT_SUD_2020`) are the pre-2021 zone
boundaries; `entsoe-py`'s `load_zones` selects them for dates before
2021-01-01. `IT_CALA` (Calabria) only exists from 2021 onward.

To refresh these files, re-download from the source URL above — they are
vendored verbatim, so a plain copy is all that is needed.
