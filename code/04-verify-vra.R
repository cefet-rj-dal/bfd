library(stringr)
library(dplyr)

# Verify VRA monthly extracts saved under 'vra_month', reporting the count of
# unique origin/destination airports and listing columns present in each file.

result <- NULL
file_list <- list.files("inter_vra_month")
file_list <- sort(file_list)
for (fname in file_list) {
  path <- sprintf("inter_vra_month/%s", fname)
  data <- get(load(path))
  result <- rbind(
    result,
    data.frame(
      f = fname,
      origin = length(table(data$origin_icao)),
      destination = length(table(data$destination_icao)),
      cols = colnames(data)
    )
  )
  print(path)
}

write.table(result, file = "result.csv", quote = FALSE, sep = ";", row.names = FALSE)

x <- result |>
  group_by(f) |>
  summarise(n = n())
print(table(x$n))
