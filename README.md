# Oradea Public Transport — interactive map

Interactive, poster-grade map of the public transport network of
**Oradea**: Oradea Transport Local (OTL)'s buses and trams — 57 lines drawn along the
real street and track geometry.

## Live

Not published — this map is built and reviewed locally.

One feed covers everything, split by `route_type` at build time:

| mode | route_type | lines | graph |
|---|---|---|---|
| buses | 3 | city lines, the metropolitan 5xx/6xx/7xx services and RoHu, the cross-border run to Debrecen | OSM roadways |
| trams | 0 | 2, 4, 5, 6, 7, 8 and 9 | `railway=tram` tracks |

Oradea has **no metro**, so the engine's metro treatment stays unused.

Build quirks worth knowing:

* **A shape can run far past its last stop.** Line 25 carries a 2.9 km tail beyond Autogara Nufărul — the depot run to Casa de Cultură named in its `route_long_name`, while the direction itself serves only five stops. The passenger-stretch trim cuts it, which is why the drawn length sits 42 % under the raw shape there.
* **Line numbers are unique across the modes**, so the line keys are the bare
  numbers printed on the vehicles — none of the mode prefixes the Sofia sibling
  needs. Re-check on every feed refresh.
* **Romanian is written in the Latin alphabet**, so this map runs without the
  second, transliterated label line its Greek, Bulgarian and Serbian siblings
  carry, and the stop names arrive properly cased and accented from the
  operator.
* **The feed's own `route_color` is ignored**, as everywhere in this family:
  colour means the MODE — navy bus, green trolleybus, red tram.

## Pipeline

`npm run download` fetches the GTFS, the OSM roadways, the tram tracks and
MapLibre GL. `npm run build` map-matches every line (HMM/Viterbi on the OSM
graphs) and writes GeoJSON to `data/out/`. `npm run serve` hosts the map at
http://localhost:8143.

Data: Oradea Transport Local (OTL) · base map © OpenFreeMap / OpenMapTiles / OpenStreetMap
contributors.
