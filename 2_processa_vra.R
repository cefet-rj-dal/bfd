library(readr)
library(stringr)

#iconv -f "windows-1252" -t "UTF-8" vra_do_mes_2000_01.csv -o ../vra_do_mes_2000_01.csv

col_names <-c("Sigla",
    "Voo",
    "DI",
    "TipoLinha",
    "AeroportoOrigem",
    "AeroportoDestino",
    "PartidaPrevista",
    "PartidaReal",
    "ChegadaPrevista",
    "ChegadaReal",
    "Situacao",
    "Justificativa"
  )


if(FALSE) {
  data <- read_delim("vra/vra_do_mes_2023_10.csv", delim = ";", escape_double = FALSE, trim_ws = TRUE)
  colnames(data) <- c("Sigla", "Voo", "DI", "TipoLinha", "AeroportoOrigem",
                      "PartidaPrevista", "PartidaReal", "AeroportoDestino",
                      "ChegadaPrevista", "ChegadaReal", "Situacao")
  data$Justificativa <- ""
  data <- data[,col_names]
  write.table(data, file="vra_do_mes_2023_10.csv", quote=FALSE, sep=";", row.names = FALSE)
}



fil <- list.files("vra")
process <- NULL
for (f in fil) {
  filecsv <- sprintf("vra/%s", f)
  filerdata <- sprintf("vra_month/%s", str_replace(f, ".csv", ".rdata"))
  data <- read_delim(filecsv, delim = ";", escape_double = FALSE, trim_ws = TRUE)
  col <- ncol(data)
  if (col == 1) {
    data <- read_delim(filecsv, delim = ",", escape_double = FALSE, trim_ws = TRUE)
    col <- ncol(data)
    if (col == 1) {
      data <- read_delim(filecsv, delim = "\t", escape_double = FALSE, trim_ws = TRUE)
      col <- ncol(data)
    }
  }
  data[,colnames(data) == "Data Prevista"] <- NULL
  data[,colnames(data) == "Grupo DI"] <- NULL
  col <- ncol(data)
  if (col == 11) {
    data$Justificativa <- ""
    col <- ncol(data)
  }
  if (col == 12) {
    colnames(data) <- col_names
    save(data, file=filerdata)
  }
  process <- rbind(process, data.frame(file = f, col = col))
}
ex <- process[process$col != 12, ]
