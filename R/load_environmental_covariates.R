#' Charger les covariables environnementales
#'
#' Télécharge NDVI (MODIS), température et précipitations (WorldClim),
#' altitude (SRTM) via les packages R appropriés.
#'
#' @param coords Data frame avec colonnes lon et lat.
#' @param start_date Caractère. Date début MODIS. Par défaut "2023-01-01".
#' @param end_date Caractère. Date fin MODIS. Par défaut "2023-12-31".
#' @param path_temp Caractère. Dossier temporaire pour téléchargements.
#' @param country Caractère. Code pays ISO 3166-1 alpha-2/alpha-3. Par défaut "MA".
#' @param ndvi_fallback Numérique. Valeur de repli NDVI si MODIS indisponible. Par défaut 0.35.
#'
#' @return Data frame avec colonnes ndvi, temp, precip, alt par parcelle.
#' @export
load_environmental_covariates <- function(coords,
                                          start_date = "2023-01-01",
                                          end_date   = "2023-12-31",
                                          path_temp  = tempdir(),
                                          country       = "MA",
                                          ndvi_fallback = NULL) {

  if (!all(c("lon", "lat") %in% names(coords)))
    stop("coords doit contenir lon et lat.")

  # --- Température et Précipitations : WorldClim via geodata ---
  message("Telechargement WorldClim (temperature + precipitations)...")
  temp_rast   <- geodata::worldclim_country(country, var = "tavg", path = path_temp)
  precip_rast <- geodata::worldclim_country(country, var = "prec", path = path_temp)
  alt_rast    <- geodata::elevation_3s(country, path = path_temp)

  pts <- terra::vect(coords, geom = c("lon", "lat"), crs = "EPSG:4326")

  temp_vals   <- terra::extract(terra::mean(temp_rast),  pts)[, 2]
  precip_vals <- terra::extract(terra::mean(precip_rast), pts)[, 2]
  alt_vals    <- terra::extract(alt_rast, pts)[, 2]

  message("WorldClim et SRTM charges.")

  fallback_val <- if (!is.null(ndvi_fallback)) ndvi_fallback else 0.35

  # --- NDVI : MODIS via MODISTools ---
  message("Telechargement NDVI MODIS...")
  ndvi_vals <- tryCatch({
    sapply(seq_len(nrow(coords)), function(i) {
      ndvi_raw <- MODISTools::mt_subset(
        product   = "MOD13A3",
        band      = "_500m_16_days_NDVI",
        lat       = coords$lat[i],
        lon       = coords$lon[i],
        start     = start_date,
        end       = end_date,
        km_lr     = 1,
        km_ab     = 1,
        site_name = paste0("P", i),
        internal  = TRUE,
        progress  = FALSE
      )
      mean(ndvi_raw$value * 0.0001, na.rm = TRUE)
    })
  }, error = function(e) {
    message("MODIS indisponible, NDVI estime depuis valeur de repli : ", e$message)
    rep(fallback_val, nrow(coords))
  })

  message("NDVI charge.")

  # --- Assembler le dataframe ---
  result <- data.frame(
    lon    = coords$lon,
    lat    = coords$lat,
    ndvi   = round(ndvi_vals,   4),
    temp   = round(temp_vals,   2),
    precip = round(precip_vals, 1),
    alt    = round(alt_vals,    1)
  )

  if ("parcelle_id" %in% names(coords))
    result$parcelle_id <- coords$parcelle_id

  message(sprintf("Covariables chargees : %d parcelles.", nrow(result)))
  return(result)
}
