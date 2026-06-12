#' Générer un rapport scientifique farmCarbonR
#'
#' @export
generate_report <- function(
    data,
    rf_result = NULL,
    soc_map = NULL,
    output_dir = "outputs",
    output_format = "html",
    titre = "Rapport scientifique farmCarbonR"
) {

  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("rmarkdown requis")
  }

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  report_env <- new.env(parent = globalenv())
  report_env$data <- data
  report_env$rf_result <- rf_result
  report_env$soc_map <- soc_map

  # =========================
  # RMD SCIENTIFIQUE STRUCTURÉ
  # =========================

  rmd <- c(
    "---",
    paste0("title: '", titre, "'"),
    "output:",
    if (output_format == "pdf") {
      "  html_document:"
    } else {
      "  html_document:"
    },
    "    toc: true",
    "    number_sections: true",
    "    theme: flatly",
    "---",

    "```{r setup, include=FALSE}",
    "knitr::opts_chunk$set(echo=FALSE, warning=FALSE, message=FALSE)",
    "library(ggplot2)",
    "library(dplyr)",
    "library(knitr)",
    "```",

    "# 1. Résumé scientifique",

    "```{r resume}",
    "n <- nrow(data)",
    "soc_mean <- mean(data$SOC_stock_tCha, na.rm = TRUE)",
    "soc_sd <- sd(data$SOC_stock_tCha, na.rm = TRUE)",

    "interpretation <- if (soc_mean < 50) {",
    "  'Stock de carbone globalement faible à modéré.'",
    "} else if (soc_mean < 120) {",
    "  'Stock de carbone modéré avec potentiel d’amélioration.'",
    "} else {",
    "  'Stock de carbone élevé, sols riches en matière organique.'",
    "}",

    "kable(data.frame(",
    "  Indicateur = c('Parcelles','SOC moyen','Ecart-type','Interprétation'),",
    "  Valeur = c(n, round(soc_mean,2), round(soc_sd,2), interpretation)",
    "))",
    "```",

    "# 2. Distribution du carbone du sol",

    "```{r plot_soc}",
    "ggplot(data, aes(x = SOC_stock_tCha)) +",
    "  geom_histogram(bins = 12, fill = 'darkgreen', alpha = 0.7) +",
    "  geom_vline(aes(xintercept = mean(SOC_stock_tCha)), linetype='dashed') +",
    "  labs(title='Distribution du SOC', x='tC/ha', y='Fréquence') +",
    "  theme_minimal()",
    "```",

    "# 3. Analyse spatiale",

    "```{r spatial}",
    "if(all(c('lon','lat') %in% names(data))) {",
    "  ggplot(data, aes(lon, lat, color = SOC_stock_tCha)) +",
    "    geom_point(size = 3) +",
    "    scale_color_viridis_c() +",
    "    labs(title='Carte du stock de carbone') +",
    "    theme_minimal()",
    "}",
    "```",

    "# 4. Pratiques agricoles et impact",

    "```{r practices}",
    "if('travail_sol' %in% names(data)) {",
    "  ggplot(data, aes(travail_sol, SOC_stock_tCha)) +",
    "    geom_boxplot(fill='orange') +",
    "    labs(title='Impact du travail du sol sur le SOC') +",
    "    theme_minimal()",
    "}",
    "```",

    "# 5. Importance des variables (Random Forest)",

    "```{r rf}",
    "if(!is.null(rf_result)) {",
    "  imp <- rf_result$importance",
    "  imp_df <- data.frame(var = rownames(imp), imp = imp[,1])",
    "  imp_df <- imp_df[order(-imp_df$imp), ][1:10, ]",

    "  ggplot(imp_df, aes(x=reorder(var, imp), y=imp)) +",
    "    geom_col(fill='steelblue') +",
    "    coord_flip() +",
    "    labs(title='Importance des variables') +",
    "    theme_minimal()",
    "}",
    "```",

    "# 6. Interprétation agronomique",

    "```{r interpretation}",
    "cat('### Analyse globale\\n')",
    "cat('- Le stock de carbone varie selon texture et pratiques\\n')",
    "cat('- Les pratiques de labour influencent fortement la perte de SOC\\n')",
    "cat('- Les zones à forte valeur SOC doivent être protégées\\n')",
    "cat('- Le modèle permet d’identifier les zones prioritaires de séquestration\\n')",
    "```",

    "# 7. Recommandations",

    "```{r reco}",
    "cat('### Recommandations\\n')",
    "cat('- Réduction du labour intensif\\n')",
    "cat('- Adoption du semis direct\\n')",
    "cat('- Augmentation du couvert végétal\\n')",
    "cat('- Apport en matière organique (compost/fumier)\\n')",
    "```"
  )

  rmd_file <- file.path(output_dir, "report_farmCarbonR.Rmd")
  writeLines(rmd, rmd_file)

  # =========================
  # RENDER
  # =========================

  out <- rmarkdown::render(
    rmd_file,
    output_dir = output_dir,
    envir = report_env,
    quiet = TRUE
  )

  message("Rapport généré : ", out)

  return(out)
}
