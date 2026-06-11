#' Importer les pratiques agricoles
#'
#' Importe les pratiques agricoles depuis un fichier CSV ou Excel.
#' Variables : travail_sol, couvert_vegetal, irrigation, fertilisation_organique.
#'
#' @param path Caractère. Chemin vers le fichier CSV ou Excel.
#' @param format Caractère. "csv" ou "excel". Par défaut "csv".
#' @param join_data Data frame optionnel à joindre (données sol).
#' @param join_by Caractère. Colonne de jointure. Par défaut "parcelle_id".
#'
#' @return Data frame des pratiques agricoles harmonisées.
#' @export
import_agricultural_practices <- function(path, format = "csv",
                                          join_data = NULL,
                                          join_by   = "parcelle_id") {

  if (!file.exists(path)) stop(paste("Fichier introuvable :", path))

  if (format == "csv") {
    data <- readr::read_csv(path, show_col_types = FALSE)
  } else if (format == "excel") {
    data <- readxl::read_excel(path)
  } else {
    stop("Format non reconnu. Utilisez csv ou excel.")
  }

  cats <- c("travail_sol", "couvert_vegetal", "irrigation", "fertilisation_organique")
  for (col in intersect(cats, names(data))) {
    data[[col]] <- tolower(trimws(data[[col]]))
  }

  if (!is.null(join_data)) {
    data[[join_by]]      <- as.character(data[[join_by]])
    join_data[[join_by]] <- as.character(join_data[[join_by]])
    data <- dplyr::left_join(join_data, data, by = join_by)
  }

  message(sprintf("Pratiques importees : %d parcelles.", nrow(data)))
  return(data)
}
