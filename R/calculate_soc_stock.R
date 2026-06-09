#' @title Calculer le stock de carbone organique
#' @description Calcule le stock SOC en tC/ha.
#' @param sol_data sf object avec colonnes SOC_mean et BD_mean
#' @param depth profondeur en cm (defaut: 30)
#' @param output_dir dossier de sauvegarde
#' @return sf object avec colonne SOC_stock_tCha
#' @export
#' @examples
#' # sol_stock <- calculate_soc_stock(sol_data, depth=30)
calculate_soc_stock <- function(sol_data, depth=30,
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  if (!requireNamespace("sf", quietly=TRUE)) stop("Package sf requis.")
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  sol_data$SOC_stock_tCha <- round(
    sol_data$SOC_mean * sol_data$BD_mean * depth / 10, 2)
  cat(sprintf("SOC stock moyen : %.2f tC/ha\n",
              mean(sol_data$SOC_stock_tCha, na.rm=TRUE)))
  write.csv(sf::st_drop_geometry(sol_data),
            file.path(output_dir,"soc_stock.csv"), row.names=FALSE)
  return(sol_data)
}
