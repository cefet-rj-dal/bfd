load("~/bfd/VRA_2009.RData")

data11 <- data[str_sub(data$Partida.Prevista, 4, 5) == "11", ]
data12 <- data[str_sub(data$Partida.Prevista, 4, 5) == "12", ]

data11$Partida.Real[data11$Partida.Real==""] <-data11$Partida.Prevista[data11$Partida.Real==""]
data11$Chegada.Real[data11$Chegada.Real==""] <-data11$Chegada.Prevista[data11$Chegada.Real==""]

write.table(data11, file="vra_do_mes_2009_11.csv", sep=";", row.names = FALSE, quote = FALSE)

data12$Partida.Real[data12$Partida.Real==""] <-data12$Partida.Prevista[data12$Partida.Real==""]
data12$Chegada.Real[data12$Chegada.Real==""] <-data12$Chegada.Prevista[data12$Chegada.Real==""]

write.table(data12, file="vra_do_mes_2009_12.csv", sep=";", row.names = FALSE, quote = FALSE)

load("~/bfd/VRA_2014.RData")

data6 <- data[str_sub(data$Partida.Prevista, 4, 5) == "06", ]
data7 <- data[str_sub(data$Partida.Prevista, 4, 5) == "07", ]


unique(str_sub(data$Partida.Prevista, 4, 5))