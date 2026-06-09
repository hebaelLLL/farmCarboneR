#' @title Visualiser l importance des variables
#' @description Graphique en barres de l importance des variables RF.
#' @param rf_result liste retournee par train_rf_model()
#' @param output_dir dossier de sauvegarde
#' @param filename nom du fichier PNG
#' @return objet ggplot2
#' @export
#' @examples
#' # p <- plot_feature_importance(rf_result)
plot_feature_importance <- function(rf_result,
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/outputs",
  filename="feature_importance.png") {
  if (!requireNamespace("ggplot2",      quietly=TRUE)) stop("Package ggplot2 requis.")
  if (!requireNamespace("randomForest", quietly=TRUE)) stop("Package randomForest requis.")
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  imp <- as.data.frame(randomForest::importance(rf_result$model))
  imp$Variable <- rownames(imp)
  Variable <- NULL; `%IncMSE` <- NULL
  p <- ggplot2::ggplot(imp, ggplot2::aes(x=reorder(Variable,`%IncMSE`),
                                          y=`%IncMSE`, fill=`%IncMSE`)) +
    ggplot2::geom_bar(stat="identity", width=0.6) +
    ggplot2::scale_fill_gradient(low="#fdae61", high="#d7191c") +
    ggplot2::coord_flip() +
    ggplot2::labs(title="Importance des Variables", x="Variable", y="% Inc MSE") +
    ggplot2::theme_minimal(base_size=13) +
    ggplot2::theme(plot.title=ggplot2::element_text(hjust=0.5,face="bold"),
                   legend.position="none")
  ggplot2::ggsave(file.path(output_dir,filename), plot=p, width=8, height=5, dpi=150)
  return(p)
}
