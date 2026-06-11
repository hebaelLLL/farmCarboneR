utils::globalVariables(c("Variable", "%IncMSE"))
#' @title Visualiser l'importance des variables
#' @description Graphique en barres de l'importance des variables RF.
#' @param rf_result Liste retournee par train_rf_model().
#' @param output_dir Dossier de sauvegarde. Par defaut "outputs".
#' @param filename Nom du fichier PNG. Par defaut "feature_importance.png".
#' @return Objet ggplot2.
#' @export
plot_feature_importance <- function(rf_result,
                                    output_dir = "outputs",
                                    filename   = "feature_importance.png") {

  if (!requireNamespace("ggplot2",      quietly = TRUE))
    stop("Package ggplot2 requis.")
  if (!requireNamespace("randomForest", quietly = TRUE))
    stop("Package randomForest requis.")

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  imp          <- as.data.frame(randomForest::importance(rf_result$model))
  imp$Variable <- rownames(imp)

  p <- ggplot2::ggplot(
    imp,
    ggplot2::aes(
      x    = reorder(Variable, `%IncMSE`),
      y    = `%IncMSE`,
      fill = `%IncMSE`
    )
  ) +
    ggplot2::geom_bar(stat = "identity", width = 0.6) +
    ggplot2::scale_fill_gradient(low = "#fdae61", high = "#d7191c") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Importance des Variables <e2><80><94> Random Forest",
      x     = "Variable",
      y     = "% Augmentation MSE"
    ) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(hjust = 0.5, face = "bold"),
      legend.position = "none"
    )

  ggplot2::ggsave(
    file.path(output_dir, filename),
    plot   = p,
    width  = 8,
    height = 5,
    dpi    = 150
  )

  message("Figure exportee : ", file.path(output_dir, filename))
  return(p)
}
