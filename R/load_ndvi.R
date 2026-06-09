#' @title Charger NDVI Maroc
#' @description Cree un raster NDVI sur la zone d etude marocaine.
#' @param lon_min longitude minimum (defaut: -6.5)
#' @param lon_max longitude maximum (defaut: -4.5)
#' @param lat_min latitude minimum  (defaut: 31.0)
#' @param lat_max latitude maximum  (defaut: 33.0)
#' @param ndvi_value valeur NDVI par defaut (defaut: 0.35)
#' @param output_dir dossier de sauvegarde
#' @return SpatRaster avec couche NDVI
#' @export
#' @examples
#' # ndvi <- load_ndvi()
load_ndvi <- function(lon_min=-6.5, lon_max=-4.5, lat_min=31.0, lat_max=33.0,
                       ndvi_value=0.35,
                       output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  cat("Creation NDVI Maroc...\n")
  ext_zone   <- terra::ext(lon_min, lon_max, lat_min, lat_max)
  ndvi_terra <- terra::rast(ext_zone, resolution=0.1, crs="EPSG:4326")
  terra::values(ndvi_terra) <- ndvi_value
  names(ndvi_terra) <- "NDVI"
  out_path <- file.path(output_dir, "ndvi_MA.tif")
  terra::writeRaster(ndvi_terra, out_path, overwrite=TRUE)
  cat(sprintf("NDVI cree (valeur=%.2f) : %s\n", ndvi_value, out_path))
  return(ndvi_terra)
}
