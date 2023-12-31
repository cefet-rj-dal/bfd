library(stringr)
library(dplyr)


result <- NULL
fil <- list.files("vra_month")
fil <- sort(fil)
for (f in fil) {
  fname <- sprintf("vra_month/%s", f)
  data <- get(load(fname))
  result <- rbind(result, data.frame(f = f, origem = length(table(data$AeroportoOrigem)),
      destino = length(table(data$AeroportoDestino)), cols = colnames(data)))
  print(fname)
}

write.table(result, file="result.csv", quote=FALSE, sep=";", row.names = FALSE)

x <- result |> group_by(f) |> summarise(n = n())
print(table(x$n))