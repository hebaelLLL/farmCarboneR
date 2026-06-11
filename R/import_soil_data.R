#' Importer les données de sol
#'
#' Importe SOC, texture et densité depuis SoilGrids (ISRIC) ou un fichier CSV.
#'
#' @param source Caractère. "soilgrids" ou "csv".
#' @param path Caractère. Chemin CSV si source = "csv".
#' @param coords Data frame avec colonnes parcelle_id, lon, lat.
#' @param depth Caractère. Profondeur SoilGrids. Par défaut "0-30cm".
#' @param crs Entier. CRS. Par défaut 4326.
#'
#' @return Liste : sf_object et dataframe.
#' @export
import_soil_data <- function(source = "csv", path = NULL, coords = NULL,
                             depth = "0-30cm", crs = 4326) {

  if (source == "csv") {
    if (is.null(path) || !file.exists(path))
      stop("Chemin CSV invalide.")
    data <- readr::read_csv(path, show_col_types = FALSE)
    data <- tidyr::drop_na(data)

  } else if (source == "soilgrids") {
    if (is.null(coords) || !all(c("lon", "lat") %in% names(coords)))
      stop("coords doit contenir lon et lat.")

    resultats <- list()
    for (i in seq_len(nrow(coords))) {
      lon <- coords$lon[i]
      lat <- coords$lat[i]
      pid <- coords$parcelle_id[i]

      url <- paste0(
        "https://rest.isric.org/soilgrids/v2.0/properties/query?",
        "lon=", lon, "&lat=", lat,
        "&property=soc&property=bdod&property=clay",
        "&property=sand&property=silt&property=cfvo",
        "&depth=", depth, "&value=mean"
      )

      row <- data.frame(
        parcelle_id   = pid, lon = lon, lat = lat,
        depth         = as.numeric(gsub(".*-(\\d+)cm", "\\1", depth)),
        SOC           = NA_real_, bulk_density  = NA_real_,
        clay          = NA_real_, sand          = NA_real_,
        silt          = NA_real_, rock_fragment = NA_real_
      )

      tryCatch({
        res    <- httr::GET(url, httr::timeout(30))
        parsed <- httr::content(res, as = "parsed", type = "application/json")
        for (layer in parsed$properties$layers) {
          nm  <- layer$name
          val <- layer$depths[[1]]$values$mean
          if (!is.null(val)) {
            if (nm == "soc")  row$SOC           <- val / 100
            if (nm == "bdod") row$bulk_density   <- val / 100
            if (nm == "clay") row$clay           <- val / 10
            if (nm == "sand") row$sand           <- val / 10
            if (nm == "silt") row$silt           <- val / 10
            if (nm == "cfvo") row$rock_fragment  <- val / 1000
          }
        }
        message(sprintf("OK %s SOC=%.3f BD=%.3f", pid, row$SOC, row$bulk_density))
      }, error = function(e) {
        message("Erreur ", pid, " : ", e$message)
      })

      resultats[[i]] <- row
      Sys.sleep(1)
    }
    data <- dplyr::bind_rows(resultats)

  } else {
    stop("source doit etre csv ou soilgrids.")
  }

  sf_obj <- sf::st_as_sf(data, coords = c("lon", "lat"), crs = crs, remove = FALSE)
  message(sprintf("Import termine : %d points.", nrow(data)))
  return(list(sf_object = sf_obj, dataframe = data))
}
