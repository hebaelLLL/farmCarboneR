#' Charger le NDVI depuis MODIS
#'
#' Télécharge le NDVI réel depuis MODIS (MOD13A3) via MODISTools.
#'
#' @param coords Data frame avec colonnes parcelle_id, lon, lat.
#' @param start_date Caractère. Date début. Par défaut "2023-01-01".
#' @param end_date Caractère. Date fin. Par défaut "2023-12-31".
#'
#' @return Data frame avec colonnes parcelle_id, lon, lat, ndvi.
#' @export
load_ndvi <- function(coords,
                      start_date = "2023-01-01",
                      end_date   = "2023-12-31") {

  if (!all(c("lon", "lat", "parcelle_id") %in% names(coords)))
    stop("coords doit contenir parcelle_id, lon et lat.")

  if (!requireNamespace("MODISTools", quietly = TRUE))
    stop("Installez MODISTools : install.packages('MODISTools')")

  message("Telechargement NDVI depuis MODIS (MOD13A3)...")

  ndvi_vals <- sapply(seq_len(nrow(coords)), function(i) {
    tryCatch({
      ndvi_raw <- MODISTools::mt_subset(
        product   = "MOD13A3",
        band      = "_500m_16_days_NDVI",
        lat       = coords$lat[i],
        lon       = coords$lon[i],
        start     = start_date,
        end       = end_date,
        km_lr     = 1,
        km_ab     = 1,
        site_name = as.character(coords$parcelle_id[i]),
        internal  = TRUE,
        progress  = FALSE
      )
      mean(ndvi_raw$value * 0.0001, na.rm = TRUE)
    }, error = function(e) {
      message("MODIS indisponible pour ", coords$parcelle_id[i], " : ", e$message)
      NA_real_
    })
  })

  result <- data.frame(
    parcelle_id = coords$parcelle_id,
    lon         = coords$lon,
    lat         = coords$lat,
    ndvi        = round(ndvi_vals, 4)
  )

  message(sprintf("NDVI charge : %d parcelles.", nrow(result)))
  return(result)
}
