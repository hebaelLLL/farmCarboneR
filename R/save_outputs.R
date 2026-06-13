#' Sauvegarder tous les outputs du pipeline farmCarbonR (VERSION AMÉLIORÉE)
#'
#' @param soil_data Data frame. Données sol avec colonne parcelle_id et SOC_stock_tCha.
#' @param practices_data Data frame. Pratiques agricoles avec colonne parcelle_id.
#' @param model Liste. Résultat de train_rf_model(). RECOMMANDÉ.
#' @param soc_map SpatRaster. Carte SOC prédite. Recommandé.
#' @param rf_importance Data frame. Importance des variables (from model$importance).
#' @param sequestration_map SpatRaster optionnel. Carte potentiel séquestration. Par défaut NULL.
#' @param path Caractère. Dossier de sortie. Par défaut "outputs".
#'
#' @return Liste : dataset (data frame fusionné) et path (dossier de sortie).
#' @export
save_outputs <- function(
    soil_data,
    practices_data,
    model = NULL,
    soc_map = NULL,
    rf_importance = NULL,
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
      paste("Missing values :", sum(is.na(df))),
      "",
      "FICHIERS GÉNÉRÉS :",
      "  ✓ final_dataset.csv/rds - Dataset complet",
      "  ✓ plot_soc_map.png - CARTE SOC (PRIORITAIRE)",
      "  ✓ plot_feature_importance.png - IMPORTANCE VARIABLES (PRIORITAIRE)",
      "  ✓ Graphiques exploratoires (soc_vs_*, soc_distribution, soc_by_tillage)",
      if (!is.null(model)) "  ✓ rf_model.rds - Modèle Random Forest" else "  ✗ rf_model.rds - Non fourni",
      "  ✓ report.html - Rapport synthétique"
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
  # Dans save_outputs, section 5, remplacez par :

  # =========================
  # 5a. PLOT SOC : CARTE POINTS (fonction officielle)
  # =========================
  if (!is.null(rf_importance)) {
    p_soc <- plot_soc_map(data = df)
    ggplot2::ggsave(
      file.path(path, "plot_soc_map.png"),
      plot   = p_soc$soc_actuel,
      width  = 10,
      height = 6,
      dpi    = 150
    )
    message("✓ plot_soc_map.png généré")
  }

  # =========================
  # 5b. PLOT SOC : CARTE RASTER IDW
  # =========================
  if (!is.null(soc_map)) {
    png(file.path(path, "plot_soc_map_idw.png"), width = 1400, height = 1000, res = 120)
    par(mar = c(5, 5, 4, 7))

    terra::plot(soc_map,
                main   = "Stock SOC interpolé — Maroc (tC/ha)",
                col    = colorRampPalette(c("#d73027", "#fee08b", "#1a9850"))(100),
                axes   = TRUE,
                legend = TRUE)

    terra::lines(morocco, col = "grey30", lwd = 1.5)

    points(df$lon, df$lat,
           pch = 21, bg = "white", col = "black", cex = 1.2)
    text(df$lon, df$lat,
         labels = df$parcelle_id,
         cex = 0.5, pos = 3, col = "black")

    mtext("Interpolation IDW — Données réelles parcelles",
          side = 1, line = 4, cex = 0.9)

    dev.off()
    message("✓ plot_soc_map_idw.png généré")
  }
  terra::lines(morocco, col = "grey30", lwd = 1.5)

  if (exists("regions")) {
    terra::lines(regions, col = "darkblue", lwd = 1.2)
    text(terra::centroids(regions), labels = regions$NAME_1,
         cex = 0.55, col = "darkblue", font = 2)
  }

  points(df$lon, df$lat,
         pch = 21, bg = "white", col = "black", cex = 1.2)

  # =========================
  # 6. PLOT 2 : FEATURE IMPORTANCE (⭐ PRIORITAIRE) - CORRIGÉ
  # =========================
  if (!is.null(rf_importance)) {
    png(file.path(path, "plot_feature_importance.png"), width = 1000, height = 800, res = 100)

    # S'assurer que c'est un data frame avec les bonnes colonnes
    if (is.data.frame(rf_importance) && "variable" %in% names(rf_importance)) {
      imp_df <- rf_importance
    } else {
      imp_df <- data.frame(
        variable      = rownames(rf_importance),
        `%IncMSE`     = as.numeric(rf_importance[, "%IncMSE"]),
        check.names   = FALSE,
        row.names     = NULL
      )
    }

    # Trier par %IncMSE croissant (pour barplot horizontal : plus important en haut)
    imp_df <- imp_df[order(imp_df$`%IncMSE`, decreasing = FALSE), ]

    par(mar = c(5, 10, 4, 2))
    barplot(
      imp_df$`%IncMSE`,
      names.arg = imp_df$variable,   # FIX : noms de variables, pas valeurs
      horiz     = TRUE,
      main      = "Importance des variables - Modèle Random Forest",
      sub       = "Prédiction des stocks de carbone organique du sol (SOC)",
      xlab      = "Importance (%IncMSE)",
      col       = colorRampPalette(c("#FFA500", "#FF6347"))(nrow(imp_df)),
      las       = 1,
      cex.names = 0.9
    )

    dev.off()
    message("✓ plot_feature_importance.png généré")
  }

  # =========================
  # 7. PLOTS EXPLORATOIRES
  # =========================

  # Distribution SOC
  png(file.path(path, "soc_distribution.png"), 800, 600)
  par(mar = c(5, 5, 4, 2))
  hist(df$SOC_mean,
       main   = "Distribution des stocks SOC",
       xlab   = "SOC (g/kg)",
       ylab   = "Fréquence",
       col    = "#DAA520",
       border = "black")
  dev.off()

  # SOC vs Clay
  png(file.path(path, "soc_vs_clay.png"), 800, 600)
  par(mar = c(5, 5, 4, 2))
  plot(df$clay, df$SOC_mean,
       main = "SOC vs Teneur en argile",
       xlab = "Argile (%)",
       ylab = "SOC (g/kg)",
       pch  = 19,
       col  = rgb(0.5, 0.5, 0.8, 0.6),
       cex  = 1.5)
  dev.off()

  # SOC vs Sand
  png(file.path(path, "soc_vs_sand.png"), 800, 600)
  par(mar = c(5, 5, 4, 2))
  plot(df$sand, df$SOC_mean,
       main = "SOC vs Teneur en sable",
       xlab = "Sable (%)",
       ylab = "SOC (g/kg)",
       pch  = 19,
       col  = rgb(0.8, 0.6, 0.4, 0.6),
       cex  = 1.5)
  dev.off()

  # SOC vs Precipitation
  if ("precip" %in% colnames(df)) {
    png(file.path(path, "soc_vs_precip.png"), 800, 600)
    par(mar = c(5, 5, 4, 2))
    plot(df$precip, df$SOC_mean,
         main = "SOC vs Précipitations annuelles",
         xlab = "Précipitations (mm)",
         ylab = "SOC (g/kg)",
         pch  = 19,
         col  = rgb(0.2, 0.6, 0.8, 0.6),
         cex  = 1.5)
    dev.off()
  }

  # SOC vs Temperature
  if ("temp" %in% colnames(df)) {
    png(file.path(path, "soc_vs_temp.png"), 800, 600)
    par(mar = c(5, 5, 4, 2))
    plot(df$temp, df$SOC_mean,
         main = "SOC vs Température moyenne",
         xlab = "Température (°C)",
         ylab = "SOC (g/kg)",
         pch  = 19,
         col  = rgb(0.8, 0.2, 0.2, 0.6),
         cex  = 1.5)
    dev.off()
  }

  # SOC by Tillage - FIX : notch = FALSE pour éviter le warning
  if ("travail_sol" %in% colnames(df)) {
    png(file.path(path, "soc_by_tillage.png"), 800, 600)
    par(mar = c(5, 5, 4, 2))
    boxplot(SOC_mean ~ travail_sol,
            data  = df,
            main  = "SOC selon type de travail du sol",
            xlab  = "Type de travail",
            ylab  = "SOC (g/kg)",
            col   = c("#FFB6C1", "#87CEEB", "#90EE90"),
            notch = FALSE)   # FIX : évite le warning des notches
    dev.off()
  }

  # =========================
  # 8 RAPPORT HTML
  # =========================
  report_file <- file.path(path, "report.html")

  html <- paste0(
    "<!DOCTYPE html>",
    "<html>",
    "<head>",
    "<meta charset='UTF-8'>",
    "<title>FarmCarbonR Report</title>",
    "<style>",
    "body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }",
    "h1 { color: #2c5f2d; border-bottom: 3px solid #DAA520; padding-bottom: 10px; }",
    "h2 { color: #555; margin-top: 25px; }",
    ".info { background: white; padding: 15px; border-radius: 5px; margin: 15px 0; }",
    ".important { color: red; font-weight: bold; }",
    ".success { color: green; }",
    "ul { line-height: 1.8; }",
    "code { background: #eee; padding: 2px 5px; border-radius: 3px; }",
    "</style>",
    "</head>",
    "<body>",
    "<h1>🌍 FarmCarbonR - Rapport d'analyse</h1>",
    "<div class='info'>",
    "<p><b>Date :</b> ", Sys.time(), "</p>",
    "<p><b>Nombre de parcelles :</b> ", nrow(df), "</p>",
    "<p><b>Nombre de variables :</b> ", ncol(df), "</p>",
    "<p><b>Valeurs manquantes :</b> ", sum(is.na(df)), "</p>",
    "</div>",
    "<h2>📊 Visualisations générées</h2>",
    "<div class='info'>",
    "<h3 class='important'>⭐ Prioritaires (À ABSOLUMENT CONSULTER)</h3>",
    "<ul>",
    "<li><b>plot_soc_map.png</b> - Cartographie spatiale des stocks SOC (Maroc)</li>",
    "<li><b>plot_feature_importance.png</b> - Importance des variables du modèle RF</li>",
    "</ul>",
    "<h3>Plots exploratoires</h3>",
    "<ul>",
    "<li>soc_distribution.png - Distribution des stocks SOC</li>",
    "<li>soc_vs_clay.png - Relation SOC / argile</li>",
    "<li>soc_vs_sand.png - Relation SOC / sable</li>",
    "<li>soc_vs_precip.png - Relation SOC / précipitations</li>",
    "<li>soc_vs_temp.png - Relation SOC / température</li>",
    "<li>soc_by_tillage.png - SOC selon type de travail du sol</li>",
    "</ul>",
    "</div>",
    "<h2>📁 Fichiers de sortie</h2>",
    "<div class='info'>",
    "<ul>",
    "<li><code>final_dataset.csv</code> - Dataset complet (données brutes)</li>",
    "<li><code>final_dataset.rds</code> - Dataset en format R</li>",
    "<li><code>rf_model.rds</code> - Modèle Random Forest entraîné</li>",
    "<li><code>summary.txt</code> - Résumé texte des outputs</li>",
    "<li><code>soc_map.tif</code> - Raster de la carte SOC</li>",
    "</ul>",
    "</div>",
    "<h2>✅ Résumé</h2>",
    "<div class='info'>",
    "<p class='success'>Tous les outputs ont été générés avec succès !</p>",
    "<p>Consultez d'abord les visualisations <span class='important'>⭐ prioritaires</span> ",
    "pour une compréhension rapide des résultats.</p>",
    "</div>",
    "</body>",
    "</html>"
  )

  writeLines(html, report_file)
  message("✓ report.html généré")

  # =========================
  # 9. MESSAGE FINAL
  # =========================
  message("\n===============================================")
  message("✅ TOUS LES OUTPUTS ONT ÉTÉ GÉNÉRÉS")
  message("===============================================")
  message("📁 Dossier de sortie : ", path)
  message("\n⭐ À CONSULTER EN PRIORITÉ :")
  message("  1. plot_soc_map.png - CARTE SOC")
  message("  2. plot_feature_importance.png - IMPORTANCE VARIABLES")
  message("\n📊 Autres visualisations :")
  message("  - Plots exploratoires (6 fichiers PNG)")
  message("  - Rapport HTML synthétique")
  message("\n💾 Données & Modèle :")
  message("  - final_dataset.csv / .rds")
  if (!is.null(model)) message("  - rf_model.rds")
  message("===============================================\n")

  return(list(
    dataset = df,
    path    = path
  ))
}
