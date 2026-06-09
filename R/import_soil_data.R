#' @title Importer les donnees sol
#' @description Importe les donnees de sol depuis un fichier CSV ou SoilGrids ISRIC.
#' @param source type de source : "csv" ou "soilgrids"
#' @param file chemin vers le fichier CSV (si source="csv")
#' @param coords_col noms des colonnes de coordonnees (defaut: c("lon","lat"))
#' @param crs systeme de coordonnees (defaut: 4326)
#' @return sf object avec les donnees sol
#' @export
#' @examples
#' # sol <- import_soil_data(source="csv", file="data/soil.csv")
import_soil_data <- function(source     = "csv",
                              file       = NULL,
                              coords_col = c("lon","lat"),
                              crs        = 4326) {
  if (!requireNamespace("sf", quietly=TRUE)) stop("Package sf requis.")

  if (source == "csv") {
    if (is.null(file) || !file.exists(file))
      stop("Fichier CSV introuvable : ", file)
    df <- read.csv(file, stringsAsFactors=FALSE)
    if (!all(coords_col %in% names(df)))
      stop("Colonnes coordonnees manquantes : ", paste(coords_col, collapse=", "))
    result <- sf::st_as_sf(df, coords=coords_col, crs=crs, remove=FALSE)
    cat(sprintf("CSV importe : %d parcelles\n", nrow(result)))

  } else if (source == "soilgrids") {
    if (!requireNamespace("httr",     quietly=TRUE)) stop("Package httr requis.")
    if (!requireNamespace("jsonlite", quietly=TRUE)) stop("Package jsonlite requis.")
    stop("Pour SoilGrids, utiliser load_soilgrids(lon, lat).")

  } else {
    stop("source doit etre csv ou soilgrids.")
  }

  return(result)
}
