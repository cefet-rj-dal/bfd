library(stringr)
library(dplyr)


processa_data <- function(data) {
  data$PartidaPrevista <-strptime(data$PartidaPrevista,"%d/%m/%Y %H:%M", tz="GMT")
  data$PartidaReal <-strptime(data$PartidaReal,"%d/%m/%Y %H:%M", tz="GMT")
  
  data$ChegadaPrevista <-strptime(data$ChegadaPrevista,"%d/%m/%Y %H:%M", tz="GMT")
  data$ChegadaReal <-strptime(data$ChegadaReal,"%d/%m/%Y %H:%M", tz="GMT")
  
  # Difference in Minutes for departures
  data$AtrasoPartida <-as.numeric(difftime(data$PartidaReal, data$PartidaPrevista, units = "mins"))
  
  # Difference in Minutes for arrivals
  data$AtrasoChegada <-as.numeric(difftime(data$ChegadaReal, data$ChegadaPrevista, units = "mins"))
  
  # Difference in Minutes for expected duration
  data$DuracaoEsperada <- as.numeric(difftime(data$ChegadaPrevista, data$PartidaPrevista, units = "mins"))
  
  # Difference in Minutes for real duration
  data$DuracaoReal<-as.numeric(difftime(data$ChegadaReal, data$PartidaReal, units = "mins"))
  
  
  #--- Remove flights that flight_id not filled
  data <- data |> filter (data$Voo !='')
  
  #--- with the pair of airports of origin and destination respectively
  data$route <- sprintf("%s-%s", data$AeroportoOrigem, data$AeroportoDestino)
  
  #--- Remove routes that have not been properly formed
  data <- data |> filter (nchar(data$route)==9)
  
  #--- Remove flights that expected and real departure and arrival dates are not filled
  data <-data |> filter (!is.na(data$PartidaPrevista) | !is.na(data$ChegadaPrevista))
  
  data <- data |>
    filter (is.na(AtrasoPartida) | AtrasoPartida < 1440)
  
  data <- data |>
    filter (is.na(AtrasoChegada) | AtrasoChegada < 1440)
  
  #--- filter expected departures <= expected arrivals
  data <- data |> filter((PartidaPrevista <= ChegadaPrevista))
  
  #--- filter real departures <= real arrivals
  data <- data |> filter(is.na(PartidaReal) | is.na(ChegadaReal) |  (PartidaReal <= ChegadaReal))  

  return(data)  
}

for (i in 2000:2023) {
  fil <- list.files("vra_rdata")
  search <- sprintf("vra_do_mes_%d", i)
  fil <- fil[(grepl(search, fil))]
  vra <- NULL
  for (f in fil) {
    fname <- sprintf("vra_rdata/%s", f)
    data <- get(load(fname))
    data <- processa_data(data)
    vra <- rbind(vra, data)
  }
  fname <- sprintf("vra_rdata/vra_%d.rdata", i)
  save(vra, file=fname)
}




