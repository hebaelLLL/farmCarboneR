#' Sample Soil Data for Moroccan Agricultural Sites
#'
#' @format A data frame with 50 rows and 14 variables:
#' \describe{
#'   \item{parcelle_id}{Identifiant parcelle}
#'   \item{lon}{Longitude (WGS84)}
#'   \item{lat}{Latitude (WGS84)}
#'   \item{SOC_mean}{Carbone organique du sol (g/kg)}
#'   \item{BD_mean}{Densite apparente (g/cm3)}
#'   \item{clay}{Argile (pct)}
#'   \item{sand}{Sable (pct)}
#'   \item{silt}{Limon (pct)}
#'   \item{depth}{Profondeur (cm)}
#'   \item{rock_fragment}{Fragments grossiers}
#'   \item{texture}{Classe texturale}
#'   \item{temp}{Temperature moyenne annuelle (degC)}
#'   \item{precip}{Precipitations annuelles (mm)}
#'   \item{alt}{Altitude (m)}
#' }
#' @source SoilGrids ISRIC + WorldClim v2.1 + SRTM
"sample_soil_data"

#' Sample Farm Practices Data
#'
#' @format A data frame with 50 rows and 6 variables:
#' \describe{
#'   \item{parcelle_id}{Identifiant parcelle}
#'   \item{travail_sol}{Type de travail du sol}
#'   \item{couvert_vegetal}{Presence couvert vegetal}
#'   \item{irrigation}{Mode irrigation}
#'   \item{fertilisation_organique}{Type fertilisation organique}
#'   \item{rotation}{Type de rotation culturale}
#' }
#' @source Recensement agricole Maroc 2016 (FAO)
"sample_farm_practices"
