# Brazilian Flight Dataset (BFD)

The Brazilian Flight Dataset (BFD) combines Brazil’s official flight history (ANAC VRA) with hourly airport weather observations (IEM/ASOS) to enable analyses of delays, operational performance, and weather impacts over time.

- Coverage: 2000–2024 (as available in the repository)
- Granularity: flight-level records enriched with hourly weather at departure and arrival airports
- Outputs: yearly `.rdata` files in `final_bfd/` and an hourly airport status aggregate in `final_airports/`

This README documents the final datasets, their fields, data sources, and the full ETL pipeline with links to code and data.

## Final Datasets

- `final_bfd/bfd_YYYY.rdata`
  - Flight-level dataset for each year, merging ANAC VRA flights with hourly ASOS weather at the origin and destination airports based on scheduled departure hour.
- `final_airports/airport_status.rdata`
  - Hourly airport aggregation (per ASOS station) with counts of total flights and delayed flights (delay defined as departure delay > 15 minutes or missing actual departure).

## Schema: `final_bfd/bfd_YYYY.rdata`

Core flight fields (from ANAC VRA, harmonized):
- `route`: `origin_icao-destination_icao` route identifier
- `company`: airline ICAO code
- `flight`: flight number (string as published)
- `di`: DI code (domestic/international indicator)
- `type`: service type
- `depart`: origin airport ICAO code
- `arrival`: destination airport ICAO code
- `expected_depart`: scheduled departure timestamp (POSIX)
- `real_depart`: actual departure timestamp (POSIX)
- `expected_arrival`: scheduled arrival timestamp (POSIX)
- `real_arrival`: actual arrival timestamp (POSIX)
- `status_depart`: published departure status
- `status_arrival`: published arrival status
- `observation`: justification text (when present)

Derived timing metrics:
- `delay_depart`: departure delay in minutes
- `delay_arrival`: arrival delay in minutes
- `expected_flight_length`: scheduled duration in minutes
- `real_flight_length`: actual duration in minutes

Outlier/consistency flags:
- `outlier_depart_delay`: `delay_depart > 1440` minutes
- `outlier_arrival_delay`: `delay_arrival > 1440` minutes
- `outlier_expected_flight_consistency`: scheduled departure > scheduled arrival
- `outlier_real_flight_consistency`: actual departure > actual arrival
- `outlier_expected_flight_length`: scheduled duration above route-specific IQR threshold (Q3 + 3×(Q3−Q1))
- `outlier_real_flight_length`: actual duration above route-specific IQR threshold

Weather at departure (ASOS; columns prefixed with `depart_`):
- `depart_air_temperature`, `depart_dew_point`, `depart_relative_humidity`
- `depart_wind_direction`, `depart_wind_speed`, `depart_wind_speed_scale` (Beaufort-like bins)
- `depart_wind_direction_cat` (compass sector)
- `depart_sky_coverage`, `depart_pressure`, `depart_visibility`, `depart_apparent_temperature`

Weather at arrival (ASOS; columns prefixed with `arrival_`):
- `arrival_air_temperature`, `arrival_dew_point`, `arrival_relative_humidity`
- `arrival_wind_direction`, `arrival_wind_speed`, `arrival_wind_speed_scale`
- `arrival_wind_direction_cat`
- `arrival_sky_coverage`, `arrival_pressure`, `arrival_visibility`, `arrival_apparent_temperature`

Notes on units and time handling:
- Temperatures are converted from Fahrenheit to Celsius.
- Wind speed, pressure, visibility remain in source ASOS units (e.g., wind in knots, altimeter in inHg, visibility in miles) per IEM/ASOS documentation.
- ASOS timestamps are shifted by −3 hours to align with local Brazilian time used to schedule flights; hourly observations (minute == 0) are kept.
- Weather is joined by origin/destination and the scheduled departure hour; the arrival weather uses the same hour key as per the original design.

## Schema: `final_airports/airport_status.rdata`

- `station`: ASOS station ID (airport identifier in the BR__ASOS network)
- `station_name`: human-friendly station name
- `date`: date (YYYY-MM-DD)
- `time`: hour of day (0–23)
- `flights`: total flights scheduled to depart from the station during that hour
- `delays`: count of flights with `delay_depart > 15` minutes or missing actual departure

## Source Data

- ANAC Flight History (VRA): https://www.gov.br/anac/pt-br/assuntos/dados-e-estatisticas/historico-de-voos
- IEM/ASOS Observations (Brazil network):
  - Portal and docs: https://mesonet.agron.iastate.edu/ASOS/
  - BR network listing: https://mesonet.agron.iastate.edu/sites/networks.php?network=BR__ASOS
- ANAC SIROS Airport Registry (used to build Brazilian airport references):
  - https://siros.anac.gov.br/siros/registros/
- OSF Project Storage for BFD (download links helper in code):
  - Node: https://osf.io/8eh3p

Local source folders in this repository:
- `src_vra_v1/`: VRA monthly ZIPs in legacy layout (primarily 2000–2009)
- `src_vra_v2/`: VRA monthly ZIPs in current layout
- `src_asos/`: ASOS monthly ZIPs
- `src_airports/br-airports.csv`: Brazilian airport reference (compiled)

## ETL Pipeline

1) Extract ASOS hourly weather → yearly ASOS `.rdata`
- Code: `code/01-extract-asos.R`
  - Reads `src_asos/*.zip` CSVs, removes unused columns, converts temperatures to °C, shifts timestamps by −3h, keeps hourly observations, writes `inter_asos_rdata/asosYYYY.rdata`.

2) Extract VRA monthly flights (legacy v1) → monthly VRA `.rdata`
- Code: `code/02-extract-vra-v1.R`
  - Reads `src_vra_v1/*.zip`, normalizes column set to the v2 English schema, writes `inter_vra_month/VRA_YYYY_MM.rdata`.

3) Extract VRA monthly flights (current v2) → monthly VRA `.rdata`
- Code: `code/03-extract-vra-v2.R`
  - Reads `src_vra_v2/*.zip`, selects the required columns into the unified English schema, writes `inter_vra_month/VRA_YYYY_MM.rdata`.

4) Verify VRA extracts
- Code: `code/04-verify-vra.R`
  - Scans `inter_vra_month/` and writes `result.csv` with basic stats and column presence.

5) Transform VRA → yearly VRA `.rdata`
- Code: `code/05-transform-vra.R`
  - Parses timestamps, derives dates/hours, computes delays and durations, builds `route`, and flags outliers. Aggregates by year to `inter_vra_rdata/vra_YYYY.rdata` with route-specific duration limits.

6) Join ASOS + VRA → final BFD `.rdata`
- Code: `code/06-join-asos-vra.R`
  - Categorizes time-of-day buckets, builds ASOS categorical wind features, and joins weather to flights by origin/destination and scheduled departure hour. Saves `final_bfd/bfd_YYYY.rdata`.

7) OSF download links helper
- Code: `code/07-osf-download.R`
  - Lists files and direct download URLs from the OSF node for convenience.

8) Build hourly airport status
- Code: `code/08-airport-status.R`
  - Merges `final_bfd/*` with `src_airports/br-airports.rdata` to compute hourly flight and delay counts per station. Saves `final_airports/airport_status.rdata`.

## Repository Links

Final data:
- Yearly BFD: `final_bfd/` (e.g., [`final_bfd/bfd_2024.rdata`](final_bfd/bfd_2024.rdata))
- Airport status: [`final_airports/airport_status.rdata`](final_airports/airport_status.rdata)

Source data:
- VRA (v1): `src_vra_v1/`
- VRA (v2): `src_vra_v2/`
- ASOS: `src_asos/`
- Airports reference: [`src_airports/br-airports.csv`](src_airports/br-airports.csv), [`src_airports/br-airports.rdata`](src_airports/br-airports.rdata)

Intermediate data:
- Monthly VRA: `inter_vra_month/`
- Yearly VRA: `inter_vra_rdata/`
- Yearly ASOS: `inter_asos_rdata/`

ETL code (with brief descriptions):
- [`code/01-extract-asos.R`](code/01-extract-asos.R): normalize hourly ASOS and persist per year
- [`code/02-extract-vra-v1.R`](code/02-extract-vra-v1.R): extract legacy VRA and map to unified schema
- [`code/03-extract-vra-v2.R`](code/03-extract-vra-v2.R): extract current VRA version to unified schema
- [`code/04-verify-vra.R`](code/04-verify-vra.R): quick verification of monthly VRA outputs
- [`code/05-transform-vra.R`](code/05-transform-vra.R): derive delays, durations, outliers; produce yearly VRA
- [`code/06-join-asos-vra.R`](code/06-join-asos-vra.R): join VRA + ASOS into final BFD
- [`code/07-osf-download.R`](code/07-osf-download.R): helper to list OSF download URLs
- [`code/08-airport-status.R`](code/08-airport-status.R): build hourly airport status aggregate

## Usage Notes and Caveats

- Encoding: some early VRA CSVs (2000–2009) may require conversion to UTF‑8 prior to parsing.
- Time alignment: ASOS observations are shifted −3h to align with local time conventions used in VRA scheduling; joins occur at hourly resolution.
- Missing weather: when ASOS data is missing for a given station/hour, the corresponding `depart_*`/`arrival_*` columns will be `NA`.
- Units: except for temperatures (converted to °C), ASOS units follow the source (e.g., wind speed in knots, visibility in miles, pressure in inHg).
