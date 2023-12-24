library(stringr)
library(dplyr)
library(doParallel)


processa_data <- function(data) {
  data$PartidaPrevista <-strptime(data$PartidaPrevista,"%d/%m/%Y %H:%M", tz="GMT")
  data$PartidaReal <-strptime(data$PartidaReal,"%d/%m/%Y %H:%M", tz="GMT")
  
  data$ChegadaPrevista <-strptime(data$ChegadaPrevista,"%d/%m/%Y %H:%M", tz="GMT")
  data$ChegadaReal <-strptime(data$ChegadaReal,"%d/%m/%Y %H:%M", tz="GMT")
  
  data$PartidaPrevista_dia <-date(data$PartidaPrevista)
  data$PartidaPrevista_hora <- hour(data$PartidaPrevista) 
  
  # Difference in Minutes for departures
  data$AtrasoPartida <-as.numeric(difftime(data$PartidaReal, data$PartidaPrevista, units = "mins"))
  
  # Difference in Minutes for arrivals
  data$AtrasoChegada <-as.numeric(difftime(data$ChegadaReal, data$ChegadaPrevista, units = "mins"))
  
  # Difference in Minutes for expected duration
  data$DuracaoEsperada <- as.numeric(difftime(data$ChegadaPrevista, data$PartidaPrevista, units = "mins"))
  
  # Difference in Minutes for real duration
  data$DuracaoReal <- as.numeric(difftime(data$ChegadaReal, data$PartidaReal, units = "mins"))
  
  
  #--- Remove flights that flight_id not filled
  data <- data |> dplyr::filter(Voo !='')
  
  #--- with the pair of airports of origin and destination respectively
  data$route <- sprintf("%s-%s", data$AeroportoOrigem, data$AeroportoDestino)
  
  #--- Remove flights that expected and real departure and arrival dates are not filled
  data <- data |> dplyr::filter(!is.na(PartidaPrevista) | !is.na(ChegadaPrevista))
  
  data$outlierAtrasoPartida <- data$AtrasoPartida < 1440
  data$outlierAtrasoChegada <- data$AtrasoChegada < 1440
  data$outlierPartidaChegadaPrevista <- data$PartidaPrevista <= data$ChegadaPrevista
  data$outlierPartidaChegadaReal <- data$PartidaReal <= data$ChegadaReal

  return(data)  
}

compute_threshold <- function(x) {
  r <- quantile(x, na.rm=TRUE)
  limit <- r[4]+3*(r[4]-r[2])
  return(limit)
}

processa_yearly_data <- function(data) {
  summary <- data |> group_by(route) |> summarise(outlierDuracaoEsperada = compute_threshold(DuracaoEsperada), 
                                                  outlierDuracaoReal = compute_threshold(DuracaoReal))
  data <- merge(data, summary)
  data$outlierDuracaoEsperada <- data$DuracaoEsperada > data$outlierDuracaoEsperada 
  data$outlierDuracaoReal <- data$DuracaoReal > data$outlierDuracaoReal 

  return(data)  
}


execute_year <- function(i) {
  fil <- list.files("vra_month")
  search <- sprintf("vra_do_mes_%d", i)
  fil <- fil[(grepl(search, fil))]
  vra <- NULL
  s <- 0
  for (f in fil) {
    fname <- sprintf("vra_month/%s", f)
    print(fname)
    data <- get(load(fname))
    data <- processa_data(data)
    vra <- rbind(vra, data)
  }
  vra <- processa_yearly_data(vra)
  fname <- sprintf("vra_rdata/vra_%d.rdata", i)
  save(vra, file=fname)
  return(s)
}

myCluster <- makeCluster(detectCores()-1, # number of cores to use
                         type = "PSOCK") # type of cluster

registerDoParallel(myCluster)

years <- 2000:2023

#%dopar%
r <- foreach(i = years) %do% {
  s <- execute_year(i)
  return(s)
}

stopCluster(myCluster)

