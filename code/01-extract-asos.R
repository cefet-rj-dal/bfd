library(readr)
library(stringr)
library(lubridate)
library(dplyr)

# Note: If ASOS data comes zipped, unzip files beforehand.
# Source and documentation: https://mesonet.agron.iastate.edu/ASOS/
# Timezone handling: shift timestamps by -3 hours to align with local time.

# Columns to remove from raw ASOS input (not used downstream)
cols_remove <- c(
  "mslp", "gust", "skyc2", "skyc3", "skyc4", "skyl1", "skyl2", "skyl3", "skyl4", "p01i",
  "wxcodes", "ice_accretion_1hr", "ice_accretion_3hr", "ice_accretion_6hr", "peak_wind_gust", "peak_wind_drct",
  "peak_wind_time", "snowdepth", "metar"
)

# Compute NA ratios per column and keep those over a small threshold for quick diagnostics
validate_attributes <- function(df) {
  na_ratio <- function(x) {
    y <- is.na(x)
    y <- y[y == TRUE]
    return(round(length(y) / length(x), digits = 2))
  }

  result <- sapply(df, na_ratio)
  result <- result[result > 0.05]
  return(result)
}

# Normalize and enrich ASOS data
enrich_asos <- function(asos) {
  # Shift timezone by -3 hours (Brazil standard offset used in the dataset)
  asos$valid <- asos$valid - as.difftime(3, units = "hours")

  # Extract date and hour components and keep only hourly observations (minute == 0)
  asos$station_date <- date(asos$valid)
  asos$station_hour <- hour(asos$valid)
  asos$station_minute <- minute(asos$valid)

  asos <- asos |>
    filter(station_minute == 0) |>
    select(
      station, station_date, station_hour, valid,
      air_temperature = tmpf, dew_point = dwpf, relative_humidity = relh, wind_direction = drct,
      wind_speed = sknt, sky_coverage = skyc1, pressure = alti, visibility = vsby, apparent_temperature = feel
    ) |>
    distinct()

  # Convert Fahrenheit to Celsius
  asos$air_temperature <- (asos$air_temperature - 32) * 5 / 9
  asos$dew_point <- (asos$dew_point - 32) * 5 / 9
  asos$apparent_temperature <- (asos$apparent_temperature - 32) * 5 / 9

  asos <- as_tibble(asos)
  return(asos)
}

# Process all ASOS files found in the 'src_asos' directory
file_list <- list.files("src_asos")

asos_all <- NULL
for (fname in file_list) {
  file_path <- sprintf("src_asos/%s", fname)
  print(file_path)

  # Read raw ASOS CSV; the 'valid' column is parsed as character first, then converted to POSIXlt
  raw <- read_csv(file_path, col_types = cols(valid = col_character()))
  raw$valid <- strptime(raw$valid, "%Y-%m-%d %H:%M", tz = "GMT")

  diag <- validate_attributes(raw)
  print(diag)

  # Keep only relevant columns
  keep <- colnames(raw)[is.na(pmatch(colnames(raw), cols_remove))]
  asos <- raw[, keep]

  asos <- enrich_asos(asos)

  asos_all <- rbind(asos_all, asos)
}

# Split by year and persist compact .rdata files
asos_all$year <- year(asos_all$valid)
years <- sort(unique(asos_all$year))

for (i in years) {
  out_rdata <- sprintf("inter_asos_rdata/asos%d.rdata", i)
  asos <- asos_all |>
    filter(year == i)
  asos$year <- NULL
  save(asos, file = out_rdata)
  print(out_rdata)
}
