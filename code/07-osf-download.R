# Instructions to fetch OSF file links for the project
# API reference: https://api.osf.io/v2/nodes/8eh3p/files/osfstorage/

library(osfr)
library(dplyr)
library(stringr)

bfd_urls <- function() {
  # Authenticate if needed: osf_auth(token = token)

  # OSF node for the Brazilian Flights Dataset
  cr_project <- osf_retrieve_node("8eh3p")

  lst <- osf_ls_files(cr_project, n_max = Inf)

  name <- lst$name
  download <- name

  for (i in 1:length(lst$name)) {
    item <- lst$meta[[i]]

    download[i] <- NA
    if (item$attributes$kind == "file") {
      download[i] <- item$links$download
    }
  }

  data <- data.frame(name, download)
  data$year <- as.numeric(gsub("\\D", "", data$name))

  data <- data |>
    arrange(name) |>
    filter(str_detect(name, ".rdata")) |>
    select(year, filename = name, url = download)

  return(data)
}

