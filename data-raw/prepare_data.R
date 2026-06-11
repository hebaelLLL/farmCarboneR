# ============================================================
# data-raw/prepare_data.R
# Telechargement donnees reelles via API REST SoilGrids ISRIC
# + WorldClim + SRTM — Zone Maroc
# ============================================================

library(terra)
library(geodata)
library(dplyr)
library(httr)
library(jsonlite)

dir.create("inst/extdata",               recursive = TRUE, showWarnings = FALSE)
dir.create("data-raw/rasters/soilgrids", recursive = TRUE, showWarnings = FALSE)

# ============================================================
# 1. POINTS DE SOL — 50 parcelles agricoles marocaines
# ============================================================

points_maroc <- data.frame(
  parcelle_id = paste0("P", sprintf("%03d", 1:50)),
  lon = c(
    -5.00, -5.10, -5.20, -4.50, -4.80,
    -3.90, -3.50, -2.80, -2.20, -1.50,
    -6.50, -6.20, -5.80, -5.50, -4.20,
    -3.10, -2.50, -1.80, -1.20, -0.50,
    -7.50, -7.20, -6.80, -6.40, -5.90,
    -4.70, -4.10, -3.60, -3.00, -2.40,
    -8.00, -7.80, -7.40, -7.00, -6.60,
    -6.10, -5.60, -5.10, -4.60, -4.00,
    -3.40, -2.90, -2.30, -1.70, -1.10,
    -8.50, -8.20, -7.90, -7.60, -7.30
  ),
  lat = c(
    32.0, 32.1, 32.2, 32.5, 32.8,
    33.0, 33.2, 33.5, 33.8, 34.0,
    31.5, 31.8, 32.3, 32.6, 32.9,
    33.1, 33.4, 33.7, 34.1, 34.3,
    31.0, 31.3, 31.6, 31.9, 32.4,
    32.7, 33.0, 33.3, 33.6, 33.9,
    30.5, 30.8, 31.1, 31.4, 31.7,
    32.0, 32.3, 32.6, 32.9, 33.2,
    33.5, 33.8, 34.1, 34.4, 34.7,
    30.2, 30.5, 30.8, 31.1, 31.4
  )
)

# ============================================================
# 2. FONCTION EXTRACTION REST SoilGrids
# ============================================================

get_soilgrids_point <- function(lon, lat,
                                properties = c("soc", "bdod", "clay", "sand", "silt")) {

  # ✅ PAS de parametre depth dans l'URL — l'API retourne tous les depths
  # On filtre ensuite sur le depth voulu
  query_string <- paste0(
    "lon=", lon, "&lat=", lat, "&value=mean",
    paste0("&property=", properties, collapse = "")
  )
  full_url <- paste0(
    "https://rest.isric.org/soilgrids/v2.0/properties/query?",
    query_string
  )

  resp <- tryCatch(
    httr::GET(full_url, httr::timeout(60)),
    error = function(e) NULL
  )

  if (is.null(resp)) return(NULL)

  status <- httr::status_code(resp)
  if (status == 429) {
    message("    Rate limit (429) — pause 60s...")
    Sys.sleep(60)
    return(NULL)
  }
  if (status != 200) {
    message("    HTTP ", status)
    return(NULL)
  }

  parsed <- tryCatch(
    jsonlite::fromJSON(rawToChar(resp$content), simplifyVector = FALSE),
    error = function(e) NULL
  )
  if (is.null(parsed)) return(NULL)

  layers <- parsed$properties$layers
  if (is.null(layers) || length(layers) == 0) return(NULL)

  out <- setNames(rep(NA_real_, length(properties)), properties)

  for (lyr in layers) {
    prop_name <- lyr$name
    if (!prop_name %in% properties) next

    depths <- lyr$depths
    if (is.null(depths) || length(depths) == 0) next

    # Chercher 0-30cm ou prendre le premier depth disponible
    target <- NULL
    for (d in depths) {
      label <- d$label
      if (!is.null(label) && grepl("0-30|0_30", label)) {
        target <- d
        break
      }
    }
    if (is.null(target)) target <- depths[[1]]

    val <- target$values$mean
    if (!is.null(val) && !is.na(val)) {
      out[prop_name] <- as.numeric(val)
    }
  }

  return(out)
}

# ============================================================
# 3. FONCTION RETRY AVEC BACKOFF
# ============================================================

get_soilgrids_point_safe <- function(lon, lat, max_retries = 5) {
  for (attempt in seq_len(max_retries)) {
    result <- tryCatch(
      get_soilgrids_point(lon, lat),
      error = function(e) { message("    Erreur : ", e$message); NULL }
    )
    if (!is.null(result)) return(result)
    wait <- 2 ^ attempt
    message("    Retry ", attempt, "/", max_retries, " dans ", wait, "s...")
    Sys.sleep(wait)
  }
  message("    Echec apres ", max_retries, " tentatives")
  return(NULL)
}

# ============================================================
# 4. EXTRACTION AUX 50 POINTS
# ============================================================

message("\n=== Extraction SoilGrids REST pour ", nrow(points_maroc), " points ===")

results <- vector("list", nrow(points_maroc))

for (i in seq_len(nrow(points_maroc))) {
  message("  Point ", i, "/", nrow(points_maroc),
          "  lon=", points_maroc$lon[i],
          "  lat=", points_maroc$lat[i])
  results[[i]] <- get_soilgrids_point_safe(points_maroc$lon[i],
                                           points_maroc$lat[i])
  Sys.sleep(2)
}

# Assembler — garantir 50 lignes
empty_row <- data.frame(soc  = NA_real_, bdod = NA_real_,
                        clay = NA_real_, sand = NA_real_, silt = NA_real_)

soil_raw <- do.call(rbind, lapply(results, function(x) {
  if (is.null(x)) return(empty_row)
  as.data.frame(as.list(x[c("soc", "bdod", "clay", "sand", "silt")]))
}))

message("  Valeurs extraites : ", sum(!is.na(soil_raw$soc)), "/",
        nrow(soil_raw), " points avec SOC")

stopifnot(nrow(soil_raw) == nrow(points_maroc))

# ============================================================
# 5. CONSTRUCTION sample_soil_data
# ============================================================

# Facteurs de conversion SoilGrids v2 :
#   soc  : dg/kg  -> g/kg  : / 10
#   bdod : cg/cm3 -> g/cm3 : / 100
#   clay/sand/silt : g/kg  -> %   : / 10

sample_soil_data <- data.frame(
  points_maroc,
  SOC_mean      = round(soil_raw$soc  / 10,  2),
  BD_mean       = round(soil_raw$bdod / 100, 3),
  clay          = round(soil_raw$clay / 10,  1),
  sand          = round(soil_raw$sand / 10,  1),
  silt          = round(soil_raw$silt / 10,  1),
  depth         = 30,
  rock_fragment = 0.05
)

# Imputation NA par mediane
for (col in c("SOC_mean", "BD_mean", "clay", "sand", "silt")) {
  n_na <- sum(is.na(sample_soil_data[[col]]))
  if (n_na > 0) {
    sample_soil_data[[col]][is.na(sample_soil_data[[col]])] <-
      round(median(sample_soil_data[[col]], na.rm = TRUE), 3)
    message("  [INFO] ", col, " : ", n_na, " valeurs imputees par mediane")
  }
}

# Classe texturale
sample_soil_data$texture <- dplyr::case_when(
  sample_soil_data$clay > 35 ~ "argile",
  sample_soil_data$sand > 65 ~ "sable",
  sample_soil_data$silt > 50 ~ "limon",
  TRUE                        ~ "limon-argileux"
)

message("\nDonnees SoilGrids extraites : ", nrow(sample_soil_data), " points")
message(sprintf("  SOC_mean : min=%.2f  max=%.2f  moy=%.2f  g/kg",
                min(sample_soil_data$SOC_mean, na.rm = TRUE),
                max(sample_soil_data$SOC_mean, na.rm = TRUE),
                mean(sample_soil_data$SOC_mean, na.rm = TRUE)))
message(sprintf("  BD_mean  : min=%.3f max=%.3f moy=%.3f g/cm3",
                min(sample_soil_data$BD_mean, na.rm = TRUE),
                max(sample_soil_data$BD_mean, na.rm = TRUE),
                mean(sample_soil_data$BD_mean, na.rm = TRUE)))

# ============================================================
# 6. PRATIQUES AGRICOLES — proportions FAO Maroc 2016
# ============================================================

set.seed(2024)
n <- nrow(sample_soil_data)

sample_farm_practices <- data.frame(
  parcelle_id             = sample_soil_data$parcelle_id,
  travail_sol             = ifelse(runif(n) < 0.60, "labour", "semis_direct"),
  couvert_vegetal         = ifelse(runif(n) < 0.25, "oui", "non"),
  irrigation              = ifelse(runif(n) < 0.40, "oui", "non"),
  fertilisation_organique = sample(
    c("compost", "fumier", "aucune"), n,
    replace = TRUE, prob = c(0.20, 0.35, 0.45)
  ),
  rotation = sample(
    c("monoculture", "biennale", "triennale"), n,
    replace = TRUE, prob = c(0.30, 0.40, 0.30)
  )
)
lines <- readLines("data-raw/prepare_data.R")

# Trouver les lignes de la section WorldClim (section 7)
# ============================================================
# 7. COVARIABLES ENVIRONNEMENTALES — WorldClim + SRTM
# ============================================================

message("\n=== Telechargement covariables climatiques ===")

if (!exists("temp_mean") || is.null(temp_mean)) {
  message("WorldClim temperature...")
  temp_raster      <- geodata::worldclim_global(var = "tavg", res = 10, path = "data-raw/rasters")
  temp_mean        <- terra::app(temp_raster, mean, na.rm = TRUE)
  names(temp_mean) <- "temp"
  terra::writeRaster(temp_mean, "inst/extdata/temperature.tif", overwrite = TRUE)
  message("  -> temperature.tif sauvegarde")
} else {
  message("  -> temperature.tif deja charge en memoire")
}

if (!exists("precip_sum") || is.null(precip_sum)) {
  message("WorldClim precipitations...")
  precip_raster     <- geodata::worldclim_global(var = "prec", res = 10, path = "data-raw/rasters")
  precip_sum        <- terra::app(precip_raster, sum, na.rm = TRUE)
  names(precip_sum) <- "precip"
  terra::writeRaster(precip_sum, "inst/extdata/precipitation.tif", overwrite = TRUE)
  message("  -> precipitation.tif sauvegarde")
} else {
  message("  -> precipitation.tif deja charge en memoire")
}

if (!exists("alt_raster") || is.null(alt_raster)) {
  message("Altitude SRTM...")
  alt_raster        <- geodata::elevation_3s(lon = -5.0, lat = 32.0, path = "data-raw/rasters")
  names(alt_raster) <- "alt"
  terra::writeRaster(alt_raster, "inst/extdata/altitude.tif", overwrite = TRUE)
  message("  -> altitude.tif sauvegarde")
} else {
  message("  -> altitude.tif deja charge en memoire")
}

idx_end   <- which(grepl("8. EXTRACTION COVARIABLES", lines)) - 1
# ============================================================
# Nouveau bloc section 7 avec guard
message("\n=== Extraction covariables aux points ===")
  "# ============================================================",
pts_vect <- terra::vect(
  "# ============================================================",
  crs = "EPSG:4326"
  "message(\"\\n=== Telechargement covariables climatiques ===\")",

  "if (!exists(\"temp_mean\") || is.null(temp_mean)) {",
temp_ma    <- terra::crop(temp_mean,  maroc_ext)
  "  temp_raster      <- geodata::worldclim_global(var = \"tavg\", res = 10, path = \"data-raw/rasters\")",
alt_ma     <- terra::crop(alt_raster, maroc_ext)
  "  names(temp_mean) <- \"temp\"",
stack_ma   <- c(temp_ma, precip_ma, alt_resamp)
  "  message(\"  -> temperature.tif sauvegarde\")",

  "  message(\"  -> temperature.tif deja charge en memoire\")",
names(val_extract) <- c("temp", "precip", "alt")
  "",
for (col in c("temp", "precip", "alt")) {
  "  message(\"WorldClim precipitations...\")",
  if (n_na > 0) {
  "  precip_sum        <- terra::app(precip_raster, sum, na.rm = TRUE)",
      median(val_extract[[col]], na.rm = TRUE)
  "  terra::writeRaster(precip_sum, \"inst/extdata/precipitation.tif\", overwrite = TRUE)",
  }
  "} else {",

  "}",
sample_soil_data <- stats::na.omit(sample_soil_data)
  "if (!exists(\"alt_raster\") || is.null(alt_raster)) {",

  "  alt_raster        <- geodata::elevation_3s(lon = -5.0, lat = 32.0, path = \"data-raw/rasters\")",
# 9. STACK ENVIRONNEMENTAL POUR predict_soc_map()
  "  terra::writeRaster(alt_raster, \"inst/extdata/altitude.tif\", overwrite = TRUE)",

  "} else {",
terra::writeRaster(env_stack, "inst/extdata/env_stack.tif", overwrite = TRUE)
  "}",

)
# 10. SAUVEGARDE
new_lines <- c(lines[1:(idx_start - 1)], new_section7, lines[idx_end + 1:length(lines)])

writeLines(new_lines, "data-raw/prepare_data.R")
usethis::use_data(sample_farm_practices, overwrite = TRUE)

write.csv(sample_soil_data,
# 8. EXTRACTION COVARIABLES AUX POINTS
write.csv(sample_farm_practices,



message("Toutes les donnees reelles ont ete sauvegardees.")
  as.matrix(points_maroc[, c("lon", "lat")]),
message("  data/sample_soil_data.rda")
)
message("  inst/extdata/exemple_sol.csv")
maroc_ext  <- terra::ext(-9.0, 0.0, 29.5, 35.5)
message("  inst/extdata/temperature.tif")
precip_ma  <- terra::crop(precip_sum, maroc_ext)
message("  inst/extdata/altitude.tif")
alt_resamp <- terra::resample(alt_ma, temp_ma, method = "bilinear")
message("============================================")
names(stack_ma) <- c("temp", "precip", "alt")
val_extract        <- terra::extract(stack_ma, pts_vect, ID = FALSE)

  n_na <- sum(is.na(val_extract[[col]]))
    val_extract[[col]][is.na(val_extract[[col]])] <-
    message("  [INFO] ", col, " : ", n_na, " valeurs imputees")
}
sample_soil_data <- cbind(sample_soil_data, val_extract)
message("Donnees finales : ", nrow(sample_soil_data), " points complets")
# ============================================================
# ============================================================
env_stack <- stack_ma
message("  -> env_stack.tif sauvegarde")
# ============================================================
# ============================================================
usethis::use_data(sample_soil_data,      overwrite = TRUE)

          "inst/extdata/exemple_sol.csv",       row.names = FALSE)
          "inst/extdata/exemple_pratiques.csv",  row.names = FALSE)
message("\n============================================")
message("  Sources : SoilGrids ISRIC (REST) + WorldClim v2 + SRTM")
message("  data/sample_farm_practices.rda")
message("  inst/extdata/exemple_pratiques.csv")
message("  inst/extdata/precipitation.tif")
message("  inst/extdata/env_stack.tif")
