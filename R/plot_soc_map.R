utils::globalVariables(c("lon","lat","SOC_stock_tCha","gain_total_tCha","parcelle_id","scenario","gain"))
#' Cartographier le stock de carbone du sol
#'
#' Produit trois cartes : SOC actuel, potentiel séquestration, scénarios agricoles.
#'
#' @param data Data frame avec SOC_stock_tCha, lon, lat.
#' @param output_path Caractère. Chemin export PNG/PDF. NULL = affichage seul.
#'
#' @return Liste de graphiques ggplot2.
#' @export
plot_soc_map <- function(data, output_path = NULL) {

  required <- c("SOC_stock_tCha", "lon", "lat")
  missing  <- setdiff(required, names(data))
  if (length(missing) > 0)
    stop(paste("Colonnes manquantes :", paste(missing, collapse = ", ")))

  # --- Carte 1 : SOC actuel ---
  p1 <- ggplot2::ggplot(data, ggplot2::aes(x = lon, y = lat,
                                           color = SOC_stock_tCha,
                                           size  = SOC_stock_tCha)) +
    ggplot2::geom_point(alpha = 0.8) +
    ggplot2::scale_color_gradientn(
      colors = c("#d73027", "#fee08b", "#1a9850"),
      name   = "SOC (tC/ha)"
    ) +
    ggplot2::labs(title = "Stock de carbone organique actuel",
                  x = "Longitude", y = "Latitude") +
    ggplot2::theme_minimal()

  # --- Carte 2 : Potentiel de séquestration ---
  p2 <- NULL
  if ("gain_total_tCha" %in% names(data)) {
    p2 <- ggplot2::ggplot(data, ggplot2::aes(x = lon, y = lat,
                                             color = gain_total_tCha,
                                             size  = gain_total_tCha)) +
      ggplot2::geom_point(alpha = 0.8) +
      ggplot2::scale_color_gradientn(
        colors = c("#f7f7f7", "#74add1", "#313695"),
        name   = "Gain (tC/ha)"
      ) +
      ggplot2::labs(title = "Potentiel de sequestration",
                    x = "Longitude", y = "Latitude") +
      ggplot2::theme_minimal()
  }

  # --- Carte 3 : Scénarios agricoles ---
  p3 <- NULL
  if (all(c("gain_couvert_tCha", "gain_semis_direct_tCha",
            "gain_pratiques_tCha") %in% names(data))) {

    scenarios <- tidyr::pivot_longer(
      data[, c("parcelle_id", "gain_couvert_tCha",
               "gain_semis_direct_tCha", "gain_pratiques_tCha")],
      cols      = -parcelle_id,
      names_to  = "scenario",
      values_to = "gain"
    )
    scenarios$scenario <- dplyr::recode(scenarios$scenario,
                                        "gain_couvert_tCha"      = "Couvert vegetal",
                                        "gain_semis_direct_tCha" = "Semis direct",
                                        "gain_pratiques_tCha"    = "Apport organique"
    )

    p3 <- ggplot2::ggplot(scenarios,
                          ggplot2::aes(x = scenario, y = gain, fill = scenario)) +
      ggplot2::geom_boxplot(alpha = 0.7) +
      ggplot2::scale_fill_brewer(palette = "Set2") +
      ggplot2::labs(title = "Gain par scenario agricole",
                    x = "Scenario", y = "Gain SOC (tC/ha)") +
      ggplot2::theme_minimal() +
      ggplot2::theme(legend.position = "none")
  }

  # --- Export ---
  if (!is.null(output_path)) {
    dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
    plots <- Filter(Negate(is.null), list(p1, p2, p3))
    if (length(plots) > 0) {
      grDevices::pdf(output_path, width = 10, height = 6 * length(plots))
      lapply(plots, print)
      grDevices::dev.off()
      message(sprintf("Cartes exportees : %s", output_path))
    }
  } else {
    print(p1)
    if (!is.null(p2)) print(p2)
    if (!is.null(p3)) print(p3)
  }

  return(list(soc_actuel = p1, sequestration = p2, scenarios = p3))
}
