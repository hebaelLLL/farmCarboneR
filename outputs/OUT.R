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
      paste("Columns :", ncol(df)),
      paste("Missing values :", sum(is.na(df)))
    ),
    file.path(path, "summary.txt")
  )

  # =========================
  # 3. MODELE MACHINE LEARNING
  # =========================
  if (!is.null(model)) {
    saveRDS(model,
            file.path(path, "rf_model.rds"))
  }

  # =========================
  # 4. CARTES (RASTERS)
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
  # 5. PLOTS AUTOMATIQUES
  # =========================

  png(file.path(path, "soc_distribution.png"), 800, 600)
  hist(df$SOC_mean,
       main = "SOC Distribution",
       xlab = "SOC",
       col = "grey")
  dev.off()

  png(file.path(path, "soc_vs_clay.png"), 800, 600)
  plot(df$clay, df$SOC_mean,
       main = "SOC vs Clay",
       xlab = "Clay",
       ylab = "SOC",
       pch = 19)
  dev.off()

  png(file.path(path, "soc_vs_sand.png"), 800, 600)
  plot(df$sand, df$SOC_mean,
       main = "SOC vs Sand",
       xlab = "Sand",
       ylab = "SOC",
       pch = 19)
  dev.off()

  png(file.path(path, "soc_vs_precip.png"), 800, 600)
  plot(df$precip, df$SOC_mean,
       main = "SOC vs Precipitation",
       xlab = "Precipitation",
       ylab = "SOC",
       pch = 19)
  dev.off()

  png(file.path(path, "soc_vs_temp.png"), 800, 600)
  plot(df$temp, df$SOC_mean,
       main = "SOC vs Temperature",
       xlab = "Temperature",
       ylab = "SOC",
       pch = 19)
  dev.off()

  png(file.path(path, "soc_by_tillage.png"), 800, 600)
  boxplot(SOC_mean ~ travail_sol,
          data = df,
          main = "SOC by Tillage",
          xlab = "Tillage",
          ylab = "SOC",
          col = "lightblue")
  dev.off()

  # =========================
  # 6. RAPPORT HTML
  # =========================
  report_file <- file.path(path, "report.html")

  html <- paste0(
    "<html><head><title>FarmCarbonR Report</title></head><body>",
    "<h1>FarmCarbonR Report</h1>",
    "<p><b>Date:</b> ", Sys.time(), "</p>",
    "<p><b>Rows:</b> ", nrow(df), "</p>",
    "<p><b>Columns:</b> ", ncol(df), "</p>",
    "<p><b>Missing values:</b> ", sum(is.na(df)), "</p>",
    "<h2>Outputs generated:</h2>",
    "<ul>",
    "<li>Dataset CSV + RDS</li>",
    "<li>Model (if provided)</li>",
    "<li>Raster maps</li>",
    "<li>Plots (PNG)</li>",
    "</ul>",
    "</body></html>"
  )

  writeLines(html, report_file)

  # =========================
  # 7. FINAL MESSAGE
  # =========================
  message("✔ All outputs generated in: ", path)

  return(list(
    dataset = df,
    path = path
  ))
}
