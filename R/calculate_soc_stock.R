#' Calculer le stock de carbone organique du sol
#'
#' @param sol_data Data frame ou sf avec SOC_mean et BD_mean.
#' @param depth Profondeur en cm. Par defaut 30.
#' @param output_dir Dossier de sortie. Par defaut "data".
#' @return sol_data avec colonne SOC_stock_tCha ajoutee.
#' @export
#' @examples
#' # sol_stock <- calculate_soc_stock(sol_data, depth = 30)
calculate_soc_stock <- function(sol_data,
                                depth      = 30,
                                output_dir = "data") {

  if (!all(c("SOC_mean", "BD_mean") %in% names(sol_data)))
    stop("sol_data doit contenir SOC_mean et BD_mean.")

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  sol_data$SOC_stock_tCha <- round(
    sol_data$SOC_mean * sol_data$BD_mean * depth / 10, 2
  )

  message(sprintf("SOC stock moyen : %.2f tC/ha",
                  mean(sol_data$SOC_stock_tCha, na.rm = TRUE)))

  # Supprime la geometrie sf avant export CSV
  data_csv <- if (inherits(sol_data, "sf")) sf::st_drop_geometry(sol_data)
  else sol_data

  write.csv(data_csv,
            file.path(output_dir, "soc_stock.csv"),
            row.names = FALSE)

  return(sol_data)
}
