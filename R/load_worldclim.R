#' @title Charger donnees climatiques WorldClim
#' @description Telecharge temperature moyenne et precipitations annuelles
#'   depuis WorldClim v2 pour un pays donne.
#' @param country code pays ISO 3166-1 alpha-2 (defaut: "MA" pour Maroc)
#' @param output_dir dossier de sauvegarde
#' @return SpatRaster avec couches temp_mean_C et prec_annual_mm
#' @export
#' @examples
#' # wc <- load_worldclim(country="MA")
load_worldclim <- function(country="MA",
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  if (!requireNamespace("geodata", quietly=TRUE)) stop("Package geodata requis.")
  if (!requireNamespace("terra",   quietly=TRUE)) stop("Package terra requis.")
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  cat("Telechargement WorldClim v2...\n")
  temp <- geodata::worldclim_country(country=country, var="tavg", res=2.5, path=output_dir)
  prec <- geodata::worldclim_country(country=country, var="prec",  res=2.5, path=output_dir)
  temp_mean <- terra::mean(temp); names(temp_mean) <- "temp_mean_C"
  prec_sum  <- sum(prec);         names(prec_sum)  <- "prec_annual_mm"
  wc_stack  <- c(temp_mean, prec_sum)
  terra::writeRaster(wc_stack, file.path(output_dir,"worldclim_MA.tif"), overwrite=TRUE)
  cat(sprintf("  Temperature moyenne      : %.1f C\n",
              terra::global(temp_mean,"mean",na.rm=TRUE)[1,1]))
  cat(sprintf("  Precipitations annuelles : %.0f mm\n",
              terra::global(prec_sum,"mean",na.rm=TRUE)[1,1]))
  cat("WorldClim OK\n")
  return(wc_stack)
}
