library(readr)
library(stringr)

#unzip asos2000.zip

fil <- list.files("asos")
process <- NULL
for (f in fil) {
  filecsv <- sprintf("asos/%s", f)
  filerdata <- sprintf("asos_rdata/%s", str_replace(f, ".csv", ".rdata"))
  data <- read_csv(filecsv, col_types = cols(valid = col_character()))
  save(data, file=filerdata)
  process <- rbind(process, data.frame(file = f, col = ncol(data)))
}


