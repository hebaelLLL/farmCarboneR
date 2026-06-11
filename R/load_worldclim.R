#' @title Charger donnees climatiques WorldClim
#' @description Telecharge temperature moyenne et precipitations annuelles
#'   depuis WorldClim v2 pour un pays donne.
#' @param country Code pays ISO 3166-1 alpha-2. Par defaut "MA".
#' @param output_dir Dossier de sauvegarde. Par defaut "data".
#' @return SpatRaster avec couches temp_mean_C et prec_annual_mm.
#' @export
load_worldclim <- function(country    = "MA",
                           output_dir = "data") {

  if (!requireNamespace("geodata", quietly = TRUE))
    stop("Package geodata requis : install.packages('geodata')")
  if (!requireNamespace("terra",   quietly = TRUE))
    stop("Package terra requis : install.packages('terra')")

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  message("Telechargement WorldClim v2...")
  temp <- geodata::worldclim_country(country = country,
                                     var     = "tavg",
                                     res     = 2.5,
                                     path    = output_dir)
  prec <- geodata::worldclim_country(country = country,
                                     var     = "prec",
                                     res     = 2.5,
                                     path    = output_dir)

  # Correction syntaxe terra : app() au lieu de mean()/sum()
  temp_mean <- terra::app(temp, mean, na.rm = TRUE)
  prec_sum  <- terra::app(prec, sum,  na.rm = TRUE)

  names(temp_mean) <- "temp_mean_C"
  names(prec_sum)  <- "prec_annual_mm"

  wc_stack <- c(temp_mean, prec_sum)

  terra::writeRaster(wc_stack,
                     file.path(output_dir, "worldclim_MA.tif"),
                     overwrite = TRUE)

  message(sprintf("  Temperature moyenne      : %.1f C",
                  terra::global(temp_mean, "mean", na.rm = TRUE)[1, 1]))
  message(sprintf("  Precipitations annuelles : %.0f mm",
                  terra::global(prec_sum,  "mean", na.rm = TRUE)[1, 1]))
  message("WorldClim OK")

  return(wc_stack)
}
