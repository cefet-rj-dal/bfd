library(stringr)
library(dplyr)
library(lubridate)


# documentacao das colunas https://mesonet.agron.iastate.edu/request/download.phtml?network=BR__ASOS
process <- function(fileasos, filevra, filebfd) {
  asos <- get(load(fileasos))
  vra <- get(load(filevra))
  
  vra <- vra |> select(route, company = Sigla, flight = Voo, di = DI, type = TipoLinha, 
                       depart = AeroportoOrigem, arrival = AeroportoDestino, 
                       expected_depart_date = PartidaPrevista_dia, expected_depart_hour = PartidaPrevista_hora, 
                       expected_depart = PartidaPrevista, real_depart = PartidaReal, 
                       expected_arrival = ChegadaPrevista, real_arrival = ChegadaReal,
                       status = Situacao, observation = Justificativa,
                       delay_depart = AtrasoPartida, delay_arrival = AtrasoChegada,
                       expected_flight_length = DuracaoEsperada, real_flight_length = DuracaoReal,
                       outlier_depart_delay = outlierAtrasoPartida, outlier_arrival_delay = outlierAtrasoChegada,
                       outlier_expected_flight_consistency = outlierPartidaChegadaPrevista, outlier_real_flight_consistency = outlierPartidaChegadaReal, 
                       outlier_expected_flight_length = outlierDuracaoEsperada,  outlier_real_flight_length = outlierDuracaoReal)
  
  asos$station_date <- date(asos$valid)
  asos$station_hour <- hour(asos$valid)
  asos$valid <- NULL
  
  asos <- asos |> select(station, station_date, station_hour, lon, lat, 
                        elevation, tmpf, dwpf, relh, drct, sknt, skyc1, alti, vsby, feel) |>
    group_by(station, station_date, station_hour) |> 
    summarise(lon = max(lon), lat = max(lat), elevation = max(elevation),
        air_temperature = max(tmpf), dew_point = max(dwpf), relative_humidity = max(relh),
        wind_direction = max(drct), wind_speed = max(sknt), sky_coverage = max(skyc1),
        pressure = max(alti), visibility = max(vsby), apparent_temperature = max(feel))
  
  asos$air_temperature <- (asos$air_temperature - 32) * 5/9
  asos$dew_point <- (asos$dew_point - 32) * 5/9
  asos$apparent_temperature <- (asos$apparent_temperature - 32) * 5/9
  asos$wind_speed_scale <- ordered(cut(asos$wind_speed,
                                                     c(0,1,3,6,10,16,21,27,33,40,47,55,63,100),
                                                     labels = c("Calm",
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
                                                                "Hurricane")))  
  
  asos$wind_direction_cat <- ordered(cut(asos$wind_direction,
                                                       c(0,11,33,56,78,101,123,146,168,191,213,236,258,281,303,326,348,360),
                                                       labels = c("N",
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
                                                                  "N")))
  
  asos$day_period <- ordered(cut(asos$station_hour,
                                                   c(-1,4,8,10,12,16,19,22,24),
                                                   labels = c("Night",
                                                              "Early Morning",
                                                              "Mid Morning",
                                                              "Late Morning",
                                                              "Afternoon",
                                                              "Early Evening",
                                                              "Late Evening", "Night")))  
  
  
  
  
  asos_depart <- asos
  colnames(asos_depart)[4:ncol(asos_depart)] <- sprintf("depart_%s", colnames(asos_depart)[4:ncol(asos_depart)])
  asos_arrival <- asos
  colnames(asos_arrival)[4:ncol(asos_arrival)] <- sprintf("arrival_%s", colnames(asos_arrival)[4:ncol(asos_arrival)])
  
  bfd <- merge(x = vra, y = asos_depart, 
               by.x = c("depart", "expected_depart_date", "expected_depart_hour"), 
               by.y = c("station", "station_date", "station_hour"))
  
  bfd <- merge(x = bfd, y = asos_arrival, 
               by.x = c("arrival", "expected_depart_date", "expected_depart_hour"), 
               by.y = c("station", "station_date", "station_hour"))
  
  bfd$expected_depart_date <- NULL
  bfd$expected_depart_hour <- NULL
  
  save(bfd, file = filebfd)
  
  return(nrow(bfd)/nrow(vra))
}

for (i in 2000:2023) {
  fileasos <- sprintf("asos_rdata/asos%d.rdata", i)
  filevra <- sprintf("vra_rdata/vra_%d.rdata", i)
  filebfd <- sprintf("bfd_%d.rdata", i)
  ratio <- process(fileasos = fileasos, filevra = filevra, filebfd = filebfd)
  print(sprintf("%d-%.2f", i, ratio))
}
