library(readr)
library(stringr)

# Flight history: https://www.gov.br/anac/pt-br/assuntos/dados-e-estatisticas/historico-de-voos
# Note: 2000–2009 files might need manual conversion to UTF-8
# Example: iconv -f "windows-1252" -t "UTF-8" vra_do_mes_2000_01.csv -o ../vra_do_mes_2000_01.csv

# Expected legacy (v1) column names present in some CSVs
pt_colnames <- c(
  "Sigla", "Voo", "DI", "TipoLinha", "AeroportoOrigem", "AeroportoDestino",
  "PartidaPrevista", "PartidaReal", "ChegadaPrevista", "ChegadaReal", "SituacaoPartida", "Justificativa"
)

# Harmonized v2 column set (adds arrival status)
pt_colnames_v2 <- c(
  "Sigla", "Voo", "DI", "TipoLinha", "AeroportoOrigem", "AeroportoDestino",
  "PartidaPrevista", "PartidaReal", "ChegadaPrevista", "ChegadaReal",
  "SituacaoPartida", "SituacaoChegada", "Justificativa"
)

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

file_list <- list.files("src_vra_v1", pattern = "\\.zip$", ignore.case = TRUE)
process_log <- NULL
for (fname in file_list) {
  zip_path <- sprintf("src_vra_v1/%s", fname)
  out_rdata <- sprintf("inter_vra_month/%s", str_replace(fname, "\\.zip$", ".rdata"))

  df <- read_zip_csv(zip_path)

  # Drop extraneous columns when present
  df[, colnames(df) == "Data Prevista"] <- NULL
  df[, colnames(df) == "Grupo DI"] <- NULL

  # Ensure presence of 12 columns by adding an empty 'Justificativa' when needed
  if (ncol(df) == 11) {
    df$Justificativa <- ""
  }

  if (ncol(df) >= 12) {
    # Map to the 13-column v2 layout (derive arrival status from departure status when missing)
    colnames(df)[1:12] <- pt_colnames
    if (is.null(df$SituacaoChegada)) df$SituacaoChegada <- df$SituacaoPartida
    df <- df[, pt_colnames_v2]

    # Rename to English schema used by later steps
    names(df) <- en_colnames

    save(df, file = out_rdata)
  }

  process_log <- rbind(process_log, data.frame(file = fname, col = ncol(df)))
  print(zip_path)
}

exceptions <- process_log[process_log$col < 12, ]

