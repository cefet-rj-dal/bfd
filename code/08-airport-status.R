library(readr)
library(dplyr)
library(stringr)
library(lubridate)

# Optional one-time step to build the airports reference rdata
if (FALSE) {
  # ASOS BR network: https://mesonet.agron.iastate.edu/sites/networks.php?network=BR__ASOS
  # ANAC registry: https://siros.anac.gov.br/siros/registros/

  br_airports <- read_csv("src_airports/br-airports.csv")
  br_airports$station_name <- str_to_title(br_airports$station_name)
  save(br_airports, file = "src_airports/br-airports.rdata")
}

load("src_airports/br-airports.rdata")

file_list <- list.files("final_bfd")
airport_status <- NULL

for (fname in file_list) {
  filename <- sprintf("final_bfd/%s", fname)
  load(filename)
  data <- merge(br_airports, bfd, by.x = "stid", by.y = "depart")
  data$date <- date(data$expected_depart)
  data$time <- hour(data$expected_depart)
  data$delay <- as.integer((data$delay_depart > 15) | is.na(data$delay_depart))
  data <- data |>
    select(station = stid, station_name, date, time, delay) |>
    group_by(station, station_name, date, time) |>
    summarise(flights = n(), delays = sum(delay))
  airport_status <- rbind(airport_status, data)
}

airport_status <- airport_status |>
  group_by(station, station_name, date, time) |>
  summarise(flights = sum(flights), delays = sum(delays))

save(airport_status, file = "final_airports/airport_status.rdata")

data <- airport_status |>
  group_by(station, station_name) |>
  summarize(flights = sum(flights), delays = sum(delays)) |>
  arrange(desc(flights))
data$ratio <- data$delays / data$flights
