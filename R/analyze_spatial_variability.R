#' Analyser la variabilité spatiale du SOC
#'
#' Calcule le variogramme, l'autocorrélation spatiale (Moran)
#' et optionnellement un krigeage simplifié.
#'
#' @param data Data frame avec SOC_stock_tCha, lon, lat.
#' @param krigeage Logique. Effectuer le krigeage ? Par défaut FALSE.
#'
#' @return Liste : stats, variogram_df, moran.
#' @export
analyze_spatial_variability <- function(data, krigeage = FALSE) {

  required <- c("SOC_stock_tCha", "lon", "lat")
  missing  <- setdiff(required, names(data))
  if (length(missing) > 0)
    stop(paste("Colonnes manquantes :", paste(missing, collapse = ", ")))

  # --- Statistiques descriptives ---
  stats <- data.frame(
    moyenne  = mean(data$SOC_stock_tCha,   na.rm = TRUE),
    mediane  = stats::median(data$SOC_stock_tCha, na.rm = TRUE),
    ecart_type = stats::sd(data$SOC_stock_tCha, na.rm = TRUE),
    min      = min(data$SOC_stock_tCha,    na.rm = TRUE),
    max      = max(data$SOC_stock_tCha,    na.rm = TRUE),
    cv       = stats::sd(data$SOC_stock_tCha, na.rm = TRUE) /
      mean(data$SOC_stock_tCha,   na.rm = TRUE) * 100
  )

  # --- Variogramme empirique simplifié ---
  n     <- nrow(data)
  dists <- as.matrix(stats::dist(data[, c("lon", "lat")]))
  soc   <- data$SOC_stock_tCha
  gamma <- outer(soc, soc, function(a, b) 0.5 * (a - b)^2)

  breaks       <- stats::quantile(dists[dists > 0], probs = seq(0, 1, 0.1))
  breaks       <- unique(breaks)
  dist_classes <- cut(dists, breaks = breaks, include.lowest = TRUE)

  variogram_df <- data.frame(
    distance = tapply(dists,  dist_classes, mean,  na.rm = TRUE),
    gamma    = tapply(gamma,  dist_classes, mean,  na.rm = TRUE),
    n_paires = tapply(dists,  dist_classes, length)
  )
  variogram_df <- stats::na.omit(variogram_df)

  # --- Autocorrélation spatiale de Moran (spdep) ---
  moran_result <- tryCatch({
    coords_mat <- as.matrix(data[, c("lon", "lat")])
    voisins    <- spdep::knearneigh(coords_mat, k = min(4, n - 1))
    listw      <- spdep::nb2listw(spdep::knn2nb(voisins), style = "W")
    test_moran <- spdep::moran.test(soc, listw)
    list(
      statistic = test_moran$statistic,
      p_value   = test_moran$p.value,
      interpretation = ifelse(test_moran$p.value < 0.05,
                              "Autocorrelation spatiale significative",
                              "Pas d'autocorrelation spatiale significative")
    )
  }, error = function(e) {
    message("spdep non disponible : ", e$message)
    NULL
  })

  # --- Krigeage simplifié optionnel ---
  krigeage_result <- NULL
  if (krigeage) {
    krigeage_result <- tryCatch({
      sf_data  <- sf::st_as_sf(data, coords = c("lon", "lat"), crs = 4326)
      vgm_fit  <- gstat::variogram(SOC_stock_tCha ~ 1, data = sf_data)
      vgm_model <- gstat::fit.variogram(vgm_fit, gstat::vgm("Sph"))
      list(variogram = vgm_fit, model = vgm_model)
    }, error = function(e) {
      message("Krigeage non disponible : ", e$message)
      NULL
    })
  }

  message("Analyse spatiale terminee.")
  return(list(
    stats        = stats,
    variogram_df = variogram_df,
    moran        = moran_result,
    krigeage     = krigeage_result
  ))
}
