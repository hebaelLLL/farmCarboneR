#' Générer des recommandations automatiques
#'
#' Génère des recommandations de gestion selon le stock SOC et les pratiques.
#'
#' @param data Data frame avec SOC_stock_tCha et pratiques agricoles.
#' @param seuil_faible Numérique. Seuil SOC faible (tC/ha). Par défaut 40.
#'
#' @return Data frame avec recommandations par parcelle.
#' @export
generate_recommendations <- function(data, seuil_faible = 40) {

  if (!"SOC_stock_tCha" %in% names(data))
    stop("Colonne SOC_stock_tCha manquante.")

  data$recommandation <- ""

  data$recommandation <- ifelse(
    data$SOC_stock_tCha < seuil_faible,
    paste0(data$recommandation, "SOC faible : augmenter matiere organique. "),
    data$recommandation
  )

  if ("travail_sol" %in% names(data)) {
    data$recommandation <- ifelse(
      tolower(data$travail_sol) == "labour",
      paste0(data$recommandation, "Reduire le labour : passer en semis direct. "),
      data$recommandation
    )
  }

  if ("couvert_vegetal" %in% names(data)) {
    data$recommandation <- ifelse(
      tolower(data$couvert_vegetal) == "non",
      paste0(data$recommandation, "Ajouter des couverts vegetaux. "),
      data$recommandation
    )
  }

  if ("fertilisation_organique" %in% names(data)) {
    data$recommandation <- ifelse(
      tolower(data$fertilisation_organique) %in% c("aucune", "non"),
      paste0(data$recommandation, "Ajouter compost ou fumier. "),
      data$recommandation
    )
  }

  if ("rotation" %in% names(data)) {
    data$recommandation <- ifelse(
      tolower(data$rotation) == "monoculture",
      paste0(data$recommandation, "Ameliorer la rotation culturale. "),
      data$recommandation
    )
  }

  data$recommandation <- ifelse(
    trimws(data$recommandation) == "",
    "Bonnes pratiques : maintenir les pratiques actuelles.",
    trimws(data$recommandation)
  )

  message(sprintf("Recommandations generees : %d parcelles.", nrow(data)))
  return(data)
}
