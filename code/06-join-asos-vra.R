library(stringr)
library(dplyr)
library(lubridate)

# Column reference: https://mesonet.agron.iastate.edu/request/download.phtml?network=BR__ASOS
process <- function(fileasos, filevra, filebfd) {
  asos <- get(load(fileasos))
  vra <- get(load(filevra))

  # Classify time-of-day buckets for departure and arrival
  vra$departure_day_period <- ordered(
    cut(
      vra$scheduled_departure_hour,
      c(-1, 4, 8, 10, 12, 16, 19, 22, 25),
      labels = c(
        "Night",
        "Early Morning",
        "Mid Morning",
        "Late Morning",
        "Afternoon",
        "Early Evening",
        "Late Evening", "Night"
      )
    )
  )

  vra$arrival_day_period <- ordered(
    cut(
      vra$scheduled_arrival_hour,
      c(-1, 4, 8, 10, 12, 16, 19, 22, 25),
      labels = c(
        "Night",
        "Early Morning",
        "Mid Morning",
        "Late Morning",
        "Afternoon",
        "Early Evening",
        "Late Evening", "Night"
      )
    )
  )

  # Select and align to final BFD schema
  vra <- vra |>
    select(
      route,
      company = airline_icao,
      flight = flight_number,
      di = di_code,
      type = service_type,
      depart = origin_icao,
      arrival = destination_icao,
      expected_depart_date = scheduled_departure_date,
      expected_depart_hour = scheduled_departure_hour,
      depart_day_period = departure_day_period,
      expected_arrival_date = scheduled_arrival_date,
      expected_arrival_hour = scheduled_arrival_hour,
      arrival_day_period = arrival_day_period,
      expected_depart = scheduled_departure,
      real_depart = actual_departure,
      expected_arrival = scheduled_arrival,
      real_arrival = actual_arrival,
      status_depart = departure_status,
      status_arrival = arrival_status,
      observation = justification,
      delay_depart = departure_delay_mins,
      delay_arrival = arrival_delay_mins,
      expected_flight_length = scheduled_duration_mins,
      real_flight_length = actual_duration_mins,
      outlier_depart_delay = outlier_departure_delay,
      outlier_arrival_delay = outlier_arrival_delay,
      outlier_expected_flight_consistency = outlier_scheduled_consistency,
      outlier_real_flight_consistency = outlier_actual_consistency,
      outlier_expected_flight_length = outlier_scheduled_duration,
      outlier_real_flight_length = outlier_actual_duration
    )

  # Align ASOS join keys and enrich with categorical winds
  asos$station_date <- date(asos$valid)
  asos$station_hour <- hour(asos$valid)
  asos$valid <- NULL

  asos$wind_speed_scale <- ordered(
    cut(
      asos$wind_speed,
      c(-1, 1, 3, 6, 10, 16, 21, 27, 33, 40, 47, 55, 63, 1000),
      labels = c(
        "Calm",
        "Light Air",
        "Light Breeze",
        "Gentle Breeze",
        "Moderate Breeze",
        "Fresh Breeze",
        "Strong Breeze",
        "Near Gale",
        "Gale",
        "Strong Gale",
        "Storm",
        "Violent Storm",
        "Hurricane"
      )
    )
  )

  asos$wind_direction_cat <- ordered(
    cut(
      asos$wind_direction,
      c(-1, 11, 33, 56, 78, 101, 123, 146, 168, 191, 213, 236, 258, 281, 303, 326, 348, 361),
      labels = c(
        "N",
        "NNE",
        "NE",
        "ENE",
        "E",
        "ESE",
        "SE",
        "SSE",
        "S",
        "SSW",
        "SW",
        "WSW",
        "W",
        "WNW",
        "NW",
        "NNW",
        "N"
      )
    )
  )

  # Prepare separate ASOS tables to join by departure and arrival sites
  asos_depart <- asos
  colnames(asos_depart)[4:ncol(asos_depart)] <- sprintf("depart_%s", colnames(asos_depart)[4:ncol(asos_depart)])
  asos_arrival <- asos
  colnames(asos_arrival)[4:ncol(asos_arrival)] <- sprintf("arrival_%s", colnames(asos_arrival)[4:ncol(asos_arrival)])

  # Join by origin station and scheduled departure timestamp (hourly)
  bfd <- merge(
    x = vra, y = asos_depart,
    by.x = c("depart", "expected_depart_date", "expected_depart_hour"),
    by.y = c("station", "station_date", "station_hour"), all.x = TRUE
  )

  # Join by destination station using the same scheduled departure timestamp (as per original design)
  bfd <- merge(
    x = bfd, y = asos_arrival,
    by.x = c("arrival", "expected_depart_date", "expected_depart_hour"),
    by.y = c("station", "station_date", "station_hour"), all.x = TRUE
  )

  # Drop helper keys no longer needed
  bfd$expected_depart_date <- NULL
  bfd$expected_depart_hour <- NULL

  bfd$expected_arrival_date <- NULL
  bfd$expected_arrival_hour <- NULL

  save(bfd, file = filebfd)

  return(nrow(bfd) / nrow(vra))
}

for (i in 2000:2024) {
  fileasos <- sprintf("inter_asos_rdata/asos%d.rdata", i)
  filevra <- sprintf("inter_vra_rdata/vra_%d.rdata", i)
  filebfd <- sprintf("final_bfd/bfd_%d.rdata", i)
  ratio <- process(fileasos = fileasos, filevra = filevra, filebfd = filebfd)
  print(sprintf("%d-%.2f", i, ratio))
}
