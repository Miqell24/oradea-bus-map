#!/usr/bin/env bash
# Downloads input data: Oradea GTFS, OSM networks (Overpass), MapLibre GL.
# Everything is cached — re-running only fetches what is missing.
#
# ONE feed covers the whole network: Oradea Transport Local (OTL)'s
# buses and trams, split by route_type at build time.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs data/osm web/vendor

BB=46.86,21.68,47.20,22.15

# 1) GTFS
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== OTL GTFS (Oradea) =="
  curl -fL --retry 3 --max-time 600 -o data/oradea-gtfs.zip \
    "https://external.gtfs.ro/oradea/ORADEA.zip"
  unzip -o data/oradea-gtfs.zip -d data/gtfs
fi

# 2) OSM — roadways over the feed's extent plus margin.
if [ ! -f data/osm/oradea.json ]; then
  echo "== Overpass (roads) =="
  QR="[out:json][timeout:900];way($BB)[\"highway\"~\"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|service|busway|construction|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)$\"];out geom;"
  ok=0
  # overpass-api.de first: the lighter mirrors have been caught serving a stale
  # database (Naples, 16.08.2026 — a line opened in 2025 was missing)
  for EP in "https://overpass-api.de/api/interpreter" \
            "https://maps.mail.ru/osm/tools/overpass/api/interpreter" \
            "https://overpass.kumi.systems/api/interpreter"; do
    echo "-- $EP"
    if curl -fsS --max-time 900 -o data/osm/oradea.json --data-urlencode "data=$QR" "$EP" \
       && grep -q '"elements"' data/osm/oradea.json; then
      ok=1; break
    fi
    sleep 5
  done
  [ "$ok" = 1 ] || { echo "Overpass (roads): all mirrors failed" >&2; exit 1; }
fi

# 2b) OSM — tram tracks for the rail mode. `disused` and `construction` come
#     along on purpose: OSM lags behind reopenings, and a corridor sitting
#     under a stale lifecycle tag drops whole lines out of the graph (Belgrade,
#     16.08.2026). See railKind() in pipeline/lib/graph.mjs.
if [ ! -f data/osm/oradea-rail.json ]; then
  echo "== Overpass (tram tracks) =="
  QT="[out:json][timeout:300];way($BB)[\"railway\"~\"^(tram|construction|disused)$\"];out geom;"
  ok=0
  for EP in "https://overpass-api.de/api/interpreter" \
            "https://maps.mail.ru/osm/tools/overpass/api/interpreter" \
            "https://overpass.kumi.systems/api/interpreter"; do
    echo "-- $EP"
    if curl -fsS --max-time 300 -o data/osm/oradea-rail.json --data-urlencode "data=$QT" "$EP" \
       && grep -q '"elements"' data/osm/oradea-rail.json; then
      ok=1; break
    fi
    sleep 5
  done
  [ "$ok" = 1 ] || { echo "Overpass (rails): all mirrors failed" >&2; exit 1; }
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/oradea-gtfs.zip data/osm/oradea*.json 2>/dev/null || true
