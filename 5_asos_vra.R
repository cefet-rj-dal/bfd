library(stringr)
library(dplyr)

load("~/bfd/asos_rdata/asos2000.rdata")


fil <- list.files("asos_rdata")
process <- NULL
for (f in fil) {
  file <- sprintf("asos_rdata/%s", f)
  print(sprintf("unzip %s", f))
}

colnames(data)