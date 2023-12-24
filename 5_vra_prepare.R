library(stringr)
library(dplyr)


for (i in 2023:2023) {
  fil <- list.files("vra_rdata")
  search <- sprintf("vra_%d", i)
  fil <- fil[(grepl(search, fil))]

  fname <- sprintf("vra_rdata/%s", fil)
  vra <- get(load(fname))
  vra <- processa_data(vra)
  save(vra, file=fname)
}



