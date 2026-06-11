#' Estimer le potentiel de séquestration du carbone
#'
#' Compare trois scénarios agricoles et calcule le gain potentiel en carbone.
#'
#' @param data Data frame avec SOC_stock_tCha et colonnes de pratiques agricoles.
#' @param gain_couvert Numérique. Gain SOC couvert végétal. Par défaut 0.3.
#' @param gain_semis_direct Numérique. Gain SOC semis direct. Par défaut 0.25.
#' @param gain_compost Numérique. Gain SOC apport organique. Par défaut 0.4.
#'
#' @return Data frame avec colonnes de gain par scénario et gain_total_tCha.
#' @export
estimate_sequestration_potential <- function(data,
                                             gain_couvert      = 0.3,
                                             gain_semis_direct = 0.25,
                                             gain_compost      = 0.4) {

  if (!"SOC_stock_tCha" %in% names(data))
    stop("Colonne SOC_stock_tCha manquante. Lancez calculate_soc_stock() d'abord.")

  # Scénario 1 : couvert végétal
  if ("couvert_vegetal" %in% names(data)) {
    data$gain_couvert_tCha <- ifelse(
      tolower(data$couvert_vegetal) == "non", gain_couvert, 0)
  } else {
    data$gain_couvert_tCha <- gain_couvert
  }

  # Scénario 2 : réduction labour
  if ("travail_sol" %in% names(data)) {
    data$gain_semis_direct_tCha <- ifelse(
      tolower(data$travail_sol) == "labour", gain_semis_direct, 0)
  } else {
    data$gain_semis_direct_tCha <- gain_semis_direct
  }

  # Scénario 3 : apport organique
  if ("fertilisation_organique" %in% names(data)) {
    data$gain_pratiques_tCha <- ifelse(
      tolower(data$fertilisation_organique) == "aucune", gain_compost, 0)
  } else {
    data$gain_pratiques_tCha <- gain_compost
  }

  data$gain_total_tCha    <- data$gain_couvert_tCha +
    data$gain_semis_direct_tCha +
    data$gain_pratiques_tCha
  data$SOC_potentiel_tCha <- data$SOC_stock_tCha + data$gain_total_tCha

  message(sprintf("Gain moyen : %.2f tC/ha | Max : %.2f tC/ha",
                  mean(data$gain_total_tCha, na.rm = TRUE),
                  max(data$gain_total_tCha, na.rm = TRUE)))
  return(data)
}
