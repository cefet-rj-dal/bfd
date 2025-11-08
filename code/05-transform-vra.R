library(stringr)
library(dplyr)
library(lubridate)

# Transform VRA monthly data into yearly files with derived metrics and outliers
transform_vra_data <- function(df) {
  # Parse times as GMT-based timestamps
  df$scheduled_departure <- strptime(df$scheduled_departure, "%d/%m/%Y %H:%M", tz = "GMT")
  df$actual_departure <- strptime(df$actual_departure, "%d/%m/%Y %H:%M", tz = "GMT")

  df$scheduled_arrival <- strptime(df$scheduled_arrival, "%d/%m/%Y %H:%M", tz = "GMT")
  df$actual_arrival <- strptime(df$actual_arrival, "%d/%m/%Y %H:%M", tz = "GMT")

  df$scheduled_departure_date <- date(df$scheduled_departure)
  df$scheduled_departure_hour <- hour(df$scheduled_departure)

  df$scheduled_arrival_date <- date(df$scheduled_arrival)
  df$scheduled_arrival_hour <- hour(df$scheduled_arrival)

  # Delays in minutes
  df$departure_delay_mins <- as.numeric(difftime(df$actual_departure, df$scheduled_departure, units = "mins"))
  df$arrival_delay_mins <- as.numeric(difftime(df$actual_arrival, df$scheduled_arrival, units = "mins"))

  # Flight durations in minutes
  df$scheduled_duration_mins <- as.numeric(difftime(df$scheduled_arrival, df$scheduled_departure, units = "mins"))
  df$actual_duration_mins <- as.numeric(difftime(df$actual_arrival, df$actual_departure, units = "mins"))

  # Keep flights with any scheduled timestamps
  df <- df |>
    dplyr::filter(!is.na(scheduled_departure) | !is.na(scheduled_arrival))

  # Remove empty flight identifiers
  df <- df |>
    dplyr::filter(flight_number != "")

  # Build route identifier
  df$route <- sprintf("%s-%s", df$origin_icao, df$destination_icao)

  # Basic consistency and long-delay flags
  df$outlier_departure_delay <- df$departure_delay_mins > 1440
  df$outlier_arrival_delay <- df$arrival_delay_mins > 1440
  df$outlier_scheduled_consistency <- df$scheduled_departure > df$scheduled_arrival
  df$outlier_actual_consistency <- df$actual_departure > df$actual_arrival

  return(df)
}

compute_threshold <- function(x) {
  r <- quantile(x, na.rm = TRUE)
  limit <- r[4] + 3 * (r[4] - r[2])
  return(limit)
}

transform_yearly_data <- function(df) {
  summary <- df |>
    group_by(route) |>
    summarise(
      outlier_scheduled_duration_limit = compute_threshold(scheduled_duration_mins),
      outlier_actual_duration_limit = compute_threshold(actual_duration_mins)
    )
  df <- merge(df, summary)
  df$outlier_scheduled_duration <- df$scheduled_duration_mins > df$outlier_scheduled_duration_limit
  df$outlier_actual_duration <- df$actual_duration_mins > df$outlier_actual_duration_limit

  return(df)
}

execute_year <- function(year_value) {
  file_list <- list.files("inter_vra_month")
  search <- sprintf("VRA_%d", year_value)
  file_list <- file_list[(grepl(search, file_list))]
  vra <- NULL
  for (fname in file_list) {
    path <- sprintf("inter_vra_month/%s", fname)
    print(path)
    df <- get(load(path))
    df <- transform_vra_data(df)
    vra <- rbind(vra, df)
  }
  vra <- transform_yearly_data(vra)
  out <- sprintf("inter_vra_rdata/vra_%d.rdata", year_value)
  save(vra, file = out)
}

for (i in 2000:2024) {
  execute_year(i)
}
