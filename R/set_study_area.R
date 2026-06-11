#' @title Definir la zone d'etude
#' @description Enregistre les parametres de la zone dans l'environnement interne.
#' @param lon_min Longitude minimale
#' @param lon_max Longitude maximale
#' @param lat_min Latitude minimale
#' @param lat_max Latitude maximale
#' @param start_date Date debut (format YYYY-MM-DD)
#' @param end_date Date fin (format YYYY-MM-DD)
#' @param country Code pays ISO 3166-1 alpha-3 (ex: "MAR")
#' @param output_dir Dossier de sortie
#' @return Liste invisible des parametres
#' @export
set_study_area <- function(lon_min    = -6.5,
                           lon_max    = -4.5,
                           lat_min    = 31.0,
                           lat_max    = 33.0,
                           start_date = NULL,
                           end_date   = NULL,
                           country    = "MAR",
                           output_dir = "data") {

  if (lon_min >= lon_max) stop("lon_min doit etre inferieur a lon_max.")
  if (lat_min >= lat_max) stop("lat_min doit etre inferieur a lat_max.")
  if (!is.null(start_date) && !is.null(end_date))
    if (as.Date(end_date) <= as.Date(start_date))
      stop("end_date doit etre posterieure a start_date.")

  params <- list(
    lon_min    = lon_min,
    lon_max    = lon_max,
    lat_min    = lat_min,
    lat_max    = lat_max,
    start_date = start_date,
    end_date   = end_date,
    country    = country,
    output_dir = output_dir,
    bbox_vec   = c(lon_min, lat_min, lon_max, lat_max)
  )

  assign("study_area", params, envir = .farmCarbonEnv)

  message("=== Zone d'etude enregistree ===")
  message(sprintf("  Pays      : %s", country))
  message(sprintf("  Longitude : [%.2f, %.2f]", lon_min, lon_max))
  message(sprintf("  Latitude  : [%.2f, %.2f]", lat_min, lat_max))
  if (!is.null(start_date))
    message(sprintf("  Periode   : %s -> %s", start_date, end_date))
  message(sprintf("  Dossier   : %s", output_dir))

  invisible(params)
}

#' @title Recuperer les parametres de la zone d'etude
#' @return Liste des parametres
#' @export
get_study_area <- function() {
  if (!exists("study_area", envir = .farmCarbonEnv))
    stop("Zone non definie. Lancez d'abord set_study_area().")
  get("study_area", envir = .farmCarbonEnv)
}
