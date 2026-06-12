#' Exporter tous les outputs du pipeline farmCarbonR
#'
#' @param soil_data dataframe sol
#' @param practices_data dataframe pratiques agricoles
#' @param model modèle RF (optionnel)
#' @param soc_map raster SOC (optionnel)
#' @param sequestration_map raster potentiel (optionnel)
#' @param path dossier de sortie
#'
#' @return liste des fichiers générés
#' @export
save_outputs <- function(soil_data,
                         practices_data,
                         model = NULL,
                         soc_map = NULL,
                         sequestration_map = NULL,
                         path = "outputs") {

  dir.create(path, showWarnings = FALSE, recursive = TRUE)

  # ---------------------------
  # 1. Export CSV
  # ---------------------------
  write.csv(soil_data,
            file = file.path(path, "soil_data.csv"),
            row.names = FALSE)

  write.csv(practices_data,
            file = file.path(path, "farm_practices.csv"),
            row.names = FALSE)

  # ---------------------------
  # 2. Export RDS (objets R complets)
  # ---------------------------
  saveRDS(soil_data, file.path(path, "soil_data.rds"))
  saveRDS(practices_data, file.path(path, "farm_practices.rds"))

  if (!is.null(model)) {
    saveRDS(model, file.path(path, "rf_model.rds"))
  }

  # ---------------------------
  # 3. Raster exports
  # ---------------------------
  if (!is.null(soc_map)) {
    terra::writeRaster(soc_map,
                       file.path(path, "soc_map.tif"),
                       overwrite = TRUE)
  }

  if (!is.null(sequestration_map)) {
    terra::writeRaster(sequestration_map,
                       file.path(path, "sequestration_map.tif"),
                       overwrite = TRUE)
  }

  # ---------------------------
  # 4. Résumé automatique
  # ---------------------------
  summary_file <- file.path(path, "summary.txt")

  cat(
    "FARM CARBON R OUTPUT\n",
    "=====================\n\n",
    "Soil dataset:\n",
    "Rows:", nrow(soil_data), "\n",
    "SOC mean:", mean(soil_data$SOC, na.rm = TRUE), "\n\n",
    "Practices dataset:\n",
    "Rows:", nrow(practices_data), "\n",
    "=====================\n",
    file = summary_file
  )

  return(list(
    soil_csv = file.path(path, "soil_data.csv"),
    practices_csv = file.path(path, "farm_practices.csv"),
    summary = summary_file
  ))
}
