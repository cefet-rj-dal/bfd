library(readr)
library(stringr)

# Flight history (v2 format): https://www.gov.br/anac/pt-br/assuntos/dados-e-estatisticas/historico-de-voos

# Final English schema used downstream
en_colnames <- c(
  "airline_icao", "flight_number", "di_code", "service_type", "origin_icao", "destination_icao",
  "scheduled_departure", "actual_departure", "scheduled_arrival", "actual_arrival",
  "departure_status", "arrival_status", "justification"
)
read_zip_csv <- function(zip_path) {
  members <- unzip(zip_path, list = TRUE)
  inner <- members$Name[grepl("\\.csv$", members$Name, ignore.case = TRUE)]
  if (length(inner) == 0) inner <- members$Name[1]
  for (dlm in c(";", ",", "\t")) {
    con <- unz(zip_path, inner)
    df <- tryCatch(
      read_delim(con, delim = dlm, escape_double = FALSE, trim_ws = TRUE, show_col_types = FALSE),
      error = function(e) NULL
    )
    if (!is.null(df) && ncol(df) > 1) return(df)
  }
  stop(sprintf("Failed to parse CSV from zip: %s", zip_path))
}

file_list <- list.files("src_vra_v2", pattern = "\\.zip$", ignore.case = TRUE)
process <- NULL
for (fname in file_list) {
  zip_path <- sprintf("src_vra_v2/%s", fname)
  out_rdata <- sprintf("inter_vra_month/%s", str_replace(fname, "\\.zip$", ".rdata"))

  df <- read_zip_csv(zip_path)

  # Select the required columns from the v2 file layout
  df <- df[, c(1, 3, 4, 5, 8, 12, 10, 11, 14, 15, 19, 20, 17)]

  # Rename to English schema used by later steps
  colnames(df) <- en_colnames

  save(df, file = out_rdata)

  col <- ncol(df)
  process <- rbind(process, data.frame(file = fname, col = col))
  print(sprintf("%s-%d", zip_path, col))
}
