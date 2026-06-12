save_outputs <- function(
    soil_data,
    practices_data,
    model = NULL,
    soc_map = NULL,
    sequestration_map = NULL,
    path = "outputs"
) {

  dir.create(path, showWarnings = FALSE, recursive = TRUE)

  # =========================
  # 1. DATASET FINAL
  # =========================
  df <- merge(soil_data, practices_data, by = "parcelle_id")

  write.csv(df,
            file.path(path, "final_dataset.csv"),
            row.names = FALSE)

  saveRDS(df,
          file.path(path, "final_dataset.rds"))

  # =========================
  # 2. RESUME TEXTE
  # =========================
  writeLines(
    c(
      "===== FARM CARBON R OUTPUTS =====",
      paste("Date :", Sys.time()),
      paste("Rows :", nrow(df)),
      paste("Cols :", ncol(df)),
      paste("Missing values :", sum(is.na(df)))
    ),
    file.path(path, "summary.txt")
  )

  # =========================
  # 3. MODELE ML
  # =========================
  if (!is.null(model)) {
    saveRDS(model,
            file.path(path, "rf_model.rds"))
  }

  # =========================
  # 4. CARTES SOC
  # =========================
  if (!is.null(soc_map)) {
    terra::writeRaster(
      soc_map,
      file.path(path, "soc_map.tif"),
      overwrite = TRUE
    )
  }

  if (!is.null(sequestration_map)) {
    terra::writeRaster(
      sequestration_map,
      file.path(path, "sequestration_map.tif"),
      overwrite = TRUE
    )
  }

  # =========================
  # 5. RAPPORT AUTOMATIQUE (HTML SIMPLE)
  # =========================
  report_file <- file.path(path, "report.html")

  html <- paste0(
    "<html><head><title>FarmCarbonR Report</title></head><body>",
    "<h1>FarmCarbonR - Report</h1>",
    "<p><b>Date:</b> ", Sys.time(), "</p>",
    "<p><b>Rows:</b> ", nrow(df), "</p>",
    "<p><b>Columns:</b> ", ncol(df), "</p>",
    "<p><b>Missing values:</b> ", sum(is.na(df)), "</p>",
    "</body></html>"
  )

  writeLines(html, report_file)

  # =========================
  # 6. OUTPUT FINAL MESSAGE
  # =========================
  message("✔ Outputs generated in: ", path)

  return(list(
    dataset = df,
    path = path
  ))
}
