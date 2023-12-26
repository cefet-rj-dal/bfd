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
  
  asos <-asos |> select(station, station_date, station_hour, lon, lat, 
                        elevation, tmpf, dwpf, relh, drct, sknt, p01i, alti, vsby, feel) |>
    group_by(station, station_date, station_hour) |> 
    summarise(lon = max(lon), lat = max(lat), elevation = max(elevation),
        air_temperature = max(tmpf), dew_point = max(dwpf), relative_humidity = max(relh),
        wind_direction = max(drct), wind_speed = max(sknt), precipitation = max(p01i),
        pressure = max(alti), visibility = max(vsby), apparent_temperature = max(feel))
  asos_depart <- asos
  colnames(asos_depart)[4:ncol(asos_depart)] <- sprintf("%s_depart", colnames(asos_depart)[4:ncol(asos_depart)])
  asos_arrival <- asos
  colnames(asos_arrival)[4:ncol(asos_arrival)] <- sprintf("%s_arrival", colnames(asos_arrival)[4:ncol(asos_arrival)])
  
  bfd <- merge(x = vra, y = asos_depart, 
               by.x = c("depart", "expected_depart_date", "expected_depart_hour"), 
               by.y = c("station", "station_date", "station_hour"))
  
  bfd <- merge(x = bfd, y = asos_arrival, 
               by.x = c("arrival", "expected_depart_date", "expected_depart_hour"), 
               by.y = c("station", "station_date", "station_hour"))
  
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
