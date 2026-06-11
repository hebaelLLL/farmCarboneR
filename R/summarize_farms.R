#' @title Resumer les donnees des parcelles agricoles
#' @description Produit un tableau de bord par parcelle avec SOC,
#'   potentiel de sequestration et pratiques agricoles.
#' @param data Data frame avec SOC_stock_tCha et colonnes de pratiques.
#' @return Liste : stats et detail.
#' @export
summarize_farms <- function(data) {

  if (!"SOC_stock_tCha" %in% names(data))
    stop("Colonne SOC_stock_tCha manquante.")

  cols_disponibles <- intersect(
    c("parcelle_id", "SOC_stock_tCha", "gain_total_tCha",
      "travail_sol", "couvert_vegetal", "fertilisation_organique"),
    names(data)
  )

  if (inherits(data, 'sf')) data <- sf::st_drop_geometry(data)

  # Categorisation SOC
  data$SOC_categorie <- cut(
    data$SOC_stock_tCha,
    breaks = c(-Inf, 40, 70, 90, Inf),
    labels = c("Tres faible (<40)", "Faible (40-70)",
               "Moyen (70-90)",     "Eleve (>90)"),
    right  = TRUE
  )

  # Meilleur scenario
  gain_cols <- intersect(
    c("gain_couvert_tCha", "gain_semis_direct_tCha", "gain_pratiques_tCha"),
    names(data)
  )
  if (length(gain_cols) > 0) {
    data$best_scenario <- apply(
      data[, gain_cols, drop = FALSE], 1,
      function(x) gain_cols[which.max(x)]
    )
    data$max_gain_tCha <- apply(
      data[, gain_cols, drop = FALSE], 1, max, na.rm = TRUE
    )
  } else {
    data$best_scenario <- NA_character_
    data$max_gain_tCha <- NA_real_
  }

  stats <- data.frame(
    n_parcelles     = nrow(data),
    SOC_moyen       = round(mean(data$SOC_stock_tCha,  na.rm = TRUE), 2),
    SOC_min         = round(min(data$SOC_stock_tCha,   na.rm = TRUE), 2),
    SOC_max         = round(max(data$SOC_stock_tCha,   na.rm = TRUE), 2),
    gain_moyen_tCha = round(mean(data$max_gain_tCha,   na.rm = TRUE), 2)
  )

  if ("travail_sol" %in% names(data)) {
    stats$pratique_dominante <-
      names(sort(table(data$travail_sol), decreasing = TRUE))[1]
  }

  message("Resume des parcelles :")
  print(stats)

  return(list(stats = stats, detail = data))
}
