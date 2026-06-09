#' @title Estimer le potentiel de sequestration carbone
#' @description Calcule les gains potentiels en SOC par scenario.
#' @param sol_stock sf object avec colonne SOC_stock_tCha
#' @param scenarios vecteur de scenarios
#' @param output_dir dossier de sauvegarde
#' @return data.frame avec gains par scenario
#' @export
#' @examples
#' # seq_pot <- estimate_sequestration_potential(sol_stock)
estimate_sequestration_potential <- function(sol_stock,
  scenarios=c("cover_crop","no_tillage","organic_fert"),
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  if (!"SOC_stock_tCha" %in% names(sol_stock)) stop("Colonne SOC_stock_tCha manquante.")
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  scenario_factors <- list(cover_crop=0.15, no_tillage=0.10,
                            organic_fert=0.20, all_combined=0.40)
  base_stock <- sol_stock$SOC_stock_tCha
  result <- sf::st_drop_geometry(sol_stock)[, c("parcelle_id","SOC_stock_tCha")]
  for (sc in scenarios) {
    if (!sc %in% names(scenario_factors)) next
    gain <- base_stock * scenario_factors[[sc]]
    result[[paste0("gain_",sc,"_tCha")]]  <- round(gain, 2)
    result[[paste0("stock_",sc,"_tCha")]] <- round(base_stock + gain, 2)
  }
  gain_cols <- grep("^gain_", names(result), value=TRUE)
  if (length(gain_cols) > 0) {
    result$best_scenario <- apply(result[,gain_cols,drop=FALSE], 1,
      function(x) gsub("^gain_|_tCha$","",names(which.max(x))))
    result$max_gain_tCha <- round(apply(result[,gain_cols,drop=FALSE], 1, max, na.rm=TRUE), 2)
  }
  write.csv(result, file.path(output_dir,"sequestration_potential.csv"), row.names=FALSE)
  return(result)
}
