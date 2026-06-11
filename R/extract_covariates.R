#' Extraire et joindre les covariables aux données sol
#'
#' Joint les covariables environnementales aux données pédologiques.
#'
#' @param soil_data Data frame. Données sol avec parcelle_id.
#' @param env_data Data frame. Covariables environnementales avec parcelle_id.
#'
#' @return Data frame complet pour la modélisation.
#' @export
extract_covariates <- function(soil_data, env_data) {

  if (!"parcelle_id" %in% names(soil_data))
    stop("soil_data doit contenir parcelle_id.")
  if (!"parcelle_id" %in% names(env_data))
    stop("env_data doit contenir parcelle_id.")

  soil_data$parcelle_id <- as.character(soil_data$parcelle_id)
  env_data$parcelle_id  <- as.character(env_data$parcelle_id)

  # Supprimer colonnes lon/lat dupliquées de env_data
  env_clean <- dplyr::select(env_data,
                             -dplyr::any_of(c("lon", "lat")))

  result <- dplyr::left_join(soil_data, env_clean, by = "parcelle_id")
  result <- tidyr::drop_na(result)

  message(sprintf("Covariables extraites : %d observations, %d variables.",
                  nrow(result), ncol(result)))
  return(result)
}
