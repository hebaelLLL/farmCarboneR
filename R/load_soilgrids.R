#' @title Charger donnees SoilGrids ISRIC
#' @description Telecharge SOC, Bulk Density et texture depuis API SoilGrids ISRIC.
#'   Utilise des valeurs par defaut Maroc en cas de timeout.
#' @param lon longitude du point (ex: -5.0 pour Maroc central)
#' @param lat latitude du point  (ex: 32.0 pour Maroc central)
#' @param depth profondeur soil (defaut: "0-30cm")
#' @return data.frame avec SOC_gkg, BD_gcm3, clay_pct, silt_pct, sand_pct
#' @export
#' @examples
#' # sg <- load_soilgrids(lon=-5.0, lat=32.0)
load_soilgrids <- function(lon, lat, depth="0-30cm") {
  if (!requireNamespace("httr",     quietly=TRUE)) stop("Package httr requis.")
  if (!requireNamespace("jsonlite", quietly=TRUE)) stop("Package jsonlite requis.")
  cat("Telechargement SoilGrids ISRIC...\n")
  properties <- c("soc","bdod","clay","silt","sand")
  base_url   <- "https://rest.isric.org/soilgrids/v2.0/properties/query"
  results    <- list()
  for (prop in properties) {
    url  <- paste0(base_url,"?lon=",lon,"&lat=",lat,"&property=",prop,"&depth=",depth,"&value=mean")
    resp <- tryCatch(httr::GET(url, httr::timeout(60)), error=function(e) NULL)
    if (!is.null(resp) && httr::status_code(resp)==200) {
      data <- jsonlite::fromJSON(httr::content(resp,"text",encoding="UTF-8"))
      val  <- tryCatch(data$properties$layers[[1]]$depths[[1]]$values$mean, error=function(e) NA)
      results[[prop]] <- ifelse(is.null(val), NA, val)
    } else { results[[prop]] <- NA }
  }
  defaults <- list(soc=120, bdod=130, clay=250, silt=300, sand=450)
  for (prop in properties) {
    if (is.na(results[[prop]])) {
      results[[prop]] <- defaults[[prop]]
      cat(sprintf("  %s : valeur defaut Maroc\n", prop))
    }
  }
  df <- data.frame(lon=lon, lat=lat, depth=depth,
    SOC_gkg=results$soc/10, BD_gcm3=results$bdod/100,
    clay_pct=results$clay/10, silt_pct=results$silt/10, sand_pct=results$sand/10)
  cat("SoilGrids OK\n")
  return(df)
}
