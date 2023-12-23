library(stringr)
library(dplyr)

compute_threshold <- function(x) {
  r <- quantile(x, na.rm=TRUE)
  limit <- r[4]+3*(r[4]-r[2])
  return(limit)
}

processa_data <- function(data) {
  summary <- data |> group_by(route) |> summarise(n = n(), DE = compute_threshold(DuracaoEsperada), DR = compute_threshold(DuracaoReal))
  data <- merge(data, summary)
  data <- data |> filter((DuracaoEsperada <= DE) & (is.na(DuracaoReal) | (DuracaoReal <= DR)))
  return(data)  
}

for (i in 2000:2000) {
  fil <- list.files("vra_rdata")
  search <- sprintf("vra_%d", i)
  fil <- fil[(grepl(search, fil))]

  fname <- sprintf("vra_rdata/%s", fil)
  data <- get(load(fname))
  data <- processa_data(data)
  vra <- rbind(vra, data)

  fname <- sprintf("vra_rdata/vra_%d.rdata", i)
  save(vra, file=fname)
}




