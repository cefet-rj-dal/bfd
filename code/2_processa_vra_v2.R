library(readr)
library(stringr)

#https://www.gov.br/anac/pt-br/assuntos/dados-e-estatisticas/historico-de-voos
#os dados de 2000-2009 não podem ser baixados pois estão piores do que estão no repositorio atual
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

col_expected <- c("Sigla ICAO Empresa Aérea", "Empresa Aérea", "Número Voo", "Código DI", "Código Tipo Linha", 
                  "Modelo Equipamento", "Número de Assentos", "Sigla ICAO Aeroporto Origem", "Descrição Aeroporto Origem",
                  "Partida Prevista", "Partida Real", "Sigla ICAO Aeroporto Destino", "Descrição Aeroporto Destino",
                  "Chegada Prevista", "Chegada Real", "Situação Voo", "Justificativa",
                  "Referência", "Situação Partida", "Situação Chegada")    

col_names_v2 <-c("Sigla",
                 "Voo",
                 "DI",
                 "TipoLinha",
                 "AeroportoOrigem",
                 "AeroportoDestino",
                 "PartidaPrevista",
                 "PartidaReal",
                 "ChegadaPrevista",
                 "ChegadaReal",
                 "SituacaoPartida",
                 "SituacaoChegada",
                 "Justificativa"
)


fil <- list.files("vra_v2")
process <- NULL
for (f in fil) {
  filecsv <- sprintf("vra_v2/%s", f)
  filerdata <- sprintf("vra_month/%s", str_replace(f, ".csv", ".rdata"))
  data <- read_delim(filecsv, delim = ";", escape_double = FALSE, trim_ws = TRUE)
  data <- data[,c(1,3,4,5,8,12,10,11,14,15,19,20,17)]
  colnames(data) <- col_names_v2
  save(data, file=filerdata)
  
  col <- ncol(data)
  process <- rbind(process, data.frame(file = f, col = col))
  print(sprintf("%s-%d", filecsv, col))
}

#ex <- process[process$col != 12, ]
