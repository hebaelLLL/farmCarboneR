
load_environmental_covariates <- function(sol_sf, buffer_deg = 2, res = 10,
                                           output_dir = "C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  if (!requireNamespace("geodata", quietly = TRUE)) stop("Package geodata requis.")
  if (!requireNamespace("terra",   quietly = TRUE)) stop("Package terra requis.")
  if (!requireNamespace("sf",      quietly = TRUE)) stop("Package sf requis.")
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  bbox <- sf::st_bbox(sol_sf)
  ext  <- terra::ext(bbox["xmin"] - buffer_deg, bbox["xmax"] + buffer_deg,
                     bbox["ymin"] - buffer_deg, bbox["ymax"] + buffer_deg)
  tavg       <- geodata::worldclim_global(var = "tavg", res = res, path = output_dir)
  tavg       <- terra::crop(tavg, ext)
  tavg_mean  <- terra::mean(tavg);  names(tavg_mean)  <- "temp_mean"
  prec       <- geodata::worldclim_global(var = "prec", res = res, path = output_dir)
  prec       <- terra::crop(prec, ext)
  prec_annual <- terra::app(prec, sum); names(prec_annual) <- "prec_annual"
  srtm       <- geodata::elevation_global(res = res, path = output_dir)
  srtm       <- terra::crop(srtm, ext); names(srtm) <- "altitude"
  prec_annual <- terra::resample(prec_annual, tavg_mean, method = "bilinear")
  srtm        <- terra::resample(srtm,        tavg_mean, method = "bilinear")
  env_stack   <- c(tavg_mean, prec_annual, srtm)
  names(env_stack) <- c("temp_mean", "prec_annual", "altitude")
  terra::writeRaster(env_stack, file.path(output_dir, "env_stack.tif"), overwrite = TRUE)
  cat("env_stack OK
")
  return(env_stack)
}

