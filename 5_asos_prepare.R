library(stringr)
library(dplyr)

load("~/bfd/asos_rdata/asos2000.rdata")

validate_attributes <- function(data) {
  na.eval <- function(x) {
    y <- is.na(x)
    y <- y[y==TRUE]
    return(round(length(y)/length(x), digits = 2))
  }
  
  k <- na.eval(data$station)
  result <- sapply(data, na.eval)
  result <- result[result > 0.05]
  return(result)
}

fil <- list.files("asos_rdata")
process <- NULL
for (f in fil) {
  print(f)
  f <- sprintf("asos_rdata/%s", f)
  data <- get(load(f))
  result <- validate_attributes(data)
  print(result)
}



