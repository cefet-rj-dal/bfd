library(readr)
library(stringr) 

#unzip asos2000.zip
#https://mesonet.agron.iastate.edu/ASOS/


cols_rm <- c("mslp", "gust", "skyc2", "skyc3", "skyc4", "skyl1", "skyl2", "skyl3", "skyl4", "p01i",
             "wxcodes", "ice_accretion_1hr", "ice_accretion_3hr", "ice_accretion_6hr", "peak_wind_gust", "peak_wind_drct",
             "peak_wind_time", "snowdepth", "metar")

validate_attributes <- function(data) {
  na.eval <- function(x) {
    y <- is.na(x)
    y <- y[y==TRUE]
    return(round(length(y)/length(x), digits = 2))
  }
  
  result <- sapply(data, na.eval)
  result <- result[result > 0.05]
  return(result)
}

fil <- list.files("asos")
process <- NULL
for (f in fil) {
  filecsv <- sprintf("asos/%s", f)
  print(filecsv)
  filerdata <- sprintf("asos_rdata/%s", str_replace(f, ".zip", ".rdata"))
  data <- read_csv(filecsv, col_types = cols(valid = col_character()))
  data$valid <- strptime(data$valid,"%Y-%m-%d %H:%M", tz="GMT")
  result <- validate_attributes(data)
  print(result)
  res <- colnames(data)[is.na(pmatch(colnames(data),cols_rm))]
  asos <- data[,res]
  save(asos, file=filerdata)
  process <- rbind(process, data.frame(file = f, col = ncol(asos)))
}





