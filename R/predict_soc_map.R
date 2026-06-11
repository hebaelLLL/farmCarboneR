#' Prédire la carte spatiale du stock SOC
#'
#' Applique le modèle Random Forest sur un raster stack pour produire
#' une carte SOC et l'exporter en GeoTIFF.
#'
#' @param rf_result Liste. Résultat de train_rf_model().
#' @param raster_stack SpatRaster. Stack de covariables environnementales.
#' @param output_path Caractère. Chemin export GeoTIFF.
#'
#' @return SpatRaster de la carte SOC predite.
#' @export
predict_soc_map <- function(rf_result, raster_stack,
                            output_path = "outputs/soc_map.tif") {

  if (!inherits(raster_stack, "SpatRaster"))
    stop("raster_stack doit etre un objet SpatRaster (terra).")

  predicteurs <- rf_result$predicteurs
  noms_raster <- names(raster_stack)
  manquants   <- setdiff(predicteurs, noms_raster)

  if (length(manquants) > 0)
    stop(paste("Couches manquantes dans le raster :", paste(manquants, collapse = ", ")))

  stack_pred <- raster_stack[[predicteurs]]

  message("Prediction spatiale en cours...")
  carte_soc <- terra::predict(stack_pred, rf_result$model, na.rm = TRUE)
  names(carte_soc) <- "SOC_stock_tCha"

  dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
  terra::writeRaster(carte_soc, output_path, overwrite = TRUE)
  message(sprintf("Carte SOC exportee : %s", output_path))

  return(carte_soc)
}
