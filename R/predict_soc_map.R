#' @title Predire la carte SOC spatiale
#' @description Applique le modele RF sur un raster de covariables.
#' @param rf_result liste retournee par train_rf_model()
#' @param env_stack SpatRaster des covariables environnementales
#' @param scale_params parametres de normalisation (optionnel)
#' @param output_dir dossier de sauvegarde
#' @return SpatRaster avec stock SOC predit en tC/ha
#' @export
#' @examples
#' # soc_map <- predict_soc_map(rf_result, env_stack)
predict_soc_map <- function(rf_result, env_stack, scale_params=NULL,
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  if (!requireNamespace("terra",        quietly=TRUE)) stop("Package terra requis.")
  if (!requireNamespace("randomForest", quietly=TRUE)) stop("Package randomForest requis.")
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  model      <- rf_result$model
  feats      <- rf_result$features
  stack_pred <- env_stack[[feats]]
  if (!is.null(scale_params)) {
    for (col in names(scale_params)) {
      if (col %in% names(stack_pred)) {
        m <- scale_params[[col]]$mean; s <- scale_params[[col]]$sd
        if (s > 0) stack_pred[[col]] <- (stack_pred[[col]] - m) / s
      }
    }
  }
  soc_map <- terra::predict(stack_pred, model, na.rm=TRUE)
  names(soc_map) <- "SOC_stock_tCha"
  cat(sprintf("SOC Map -- Min:%.2f Max:%.2f Moy:%.2f tC/ha\n",
              terra::global(soc_map,"min",na.rm=TRUE)[1,1],
              terra::global(soc_map,"max",na.rm=TRUE)[1,1],
              terra::global(soc_map,"mean",na.rm=TRUE)[1,1]))
  terra::writeRaster(soc_map, file.path(output_dir,"soc_map.tif"), overwrite=TRUE)
  return(soc_map)
}
