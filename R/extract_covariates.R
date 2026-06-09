
extract_covariates <- function(sol_sf, env_stack, pratiques = NULL, join_by = "parcelle_id") {
  if (!requireNamespace("terra", quietly = TRUE)) stop("Package terra requis.")
  if (!requireNamespace("sf",    quietly = TRUE)) stop("Package sf requis.")
  coords_vect <- terra::vect(sol_sf)
  extracted   <- terra::extract(env_stack, coords_vect, ID = FALSE)
  sol_df      <- sf::st_drop_geometry(sol_sf)
  data        <- cbind(sol_df, extracted)
  if (!is.null(pratiques)) {
    if (!join_by %in% names(pratiques)) stop("Colonne jointure absente des pratiques.")
    data <- merge(data, pratiques, by = join_by, all.x = TRUE)
  }
  n_avant <- nrow(data)
  data    <- data[complete.cases(data), ]
  if (n_avant - nrow(data) > 0) warning(n_avant - nrow(data), " parcelle(s) supprimee(s) pour NA.")
  cat(sprintf("Dataset : %d parcelles, %d variables
", nrow(data), ncol(data)))
  return(data)
}

