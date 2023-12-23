library(stringr)
library(dplyr)

compute_threshold <- function(x) {
  r <- quantile(x, na.rm=TRUE)
  limit <- r[4]+3*(r[4]-r[2])
  return(limit)
}

processa_data <- function(data) {
  summary <- data |> group_by(route) |> summarise(outlierDuracaoEsperada = compute_threshold(DuracaoEsperada), 
                                                  outlierDuracaoReal = compute_threshold(DuracaoReal))
  data <- merge(data, summary)
  data$outlierDuracaoEsperada <- data$DuracaoEsperada > data$outlierDuracaoEsperada 
  data$outlierDuracaoReal <- data$DuracaoReal > data$outlierDuracaoReal 
  

  
  return(data)  
}

for (i in 2023:2023) {
  fil <- list.files("vra_rdata")
  search <- sprintf("vra_%d", i)
  fil <- fil[(grepl(search, fil))]

  fname <- sprintf("vra_rdata/%s", fil)
  vra <- get(load(fname))
  vra <- processa_data(vra)
  save(vra, file=fname)
}

vra$expected_depart_date<-as.character(gsub("-","",as.character(vra$expected_depart_date)))
vra$expected_depart_hour<-substr(as.character(gsub(":","",as.character(vra$expected_depart_time))),1,2)
vra$expected_depart_time<-NULL


