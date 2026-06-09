
# ============================================================
# TESTS UNITAIRES farmCarbonR
# ============================================================

# --- Test calculate_soc_stock ---
test_that("calculate_soc_stock retourne SOC_stock_tCha correct", {
  df <- data.frame(
    parcelle_id = c("P001","P002"),
    SOC_mean    = c(20.0, 10.0),
    BD_mean     = c(1.3,  1.5),
    lon         = c(-5.0, -5.1),
    lat         = c(32.0, 32.1)
  )
  sol <- sf::st_as_sf(df, coords=c("lon","lat"), crs=4326, remove=FALSE)
  result <- calculate_soc_stock(sol, depth=30)
  expect_true("SOC_stock_tCha" %in% names(result))
  expect_equal(result$SOC_stock_tCha[1], round(20.0 * 1.3 * 30 / 10, 2))
  expect_equal(result$SOC_stock_tCha[2], round(10.0 * 1.5 * 30 / 10, 2))
  cat("  calculate_soc_stock : OK\n")
})

# --- Test estimate_sequestration_potential ---
test_that("estimate_sequestration_potential calcule gains corrects", {
  df <- data.frame(
    parcelle_id    = c("P001","P002"),
    SOC_stock_tCha = c(80.0, 40.0),
    SOC_mean       = c(20.0, 10.0),
    BD_mean        = c(1.3,  1.5),
    lon            = c(-5.0, -5.1),
    lat            = c(32.0, 32.1)
  )
  sol <- sf::st_as_sf(df, coords=c("lon","lat"), crs=4326, remove=FALSE)
  result <- estimate_sequestration_potential(sol, scenarios=c("cover_crop","no_tillage"))
  expect_true("gain_cover_crop_tCha" %in% names(result))
  expect_true("gain_no_tillage_tCha" %in% names(result))
  expect_equal(result$gain_cover_crop_tCha[1], round(80.0 * 0.15, 2))
  expect_equal(result$best_scenario[1], "cover_crop")
  cat("  estimate_sequestration_potential : OK\n")
})

# --- Test load_ndvi ---
test_that("load_ndvi retourne SpatRaster NDVI", {
  result <- load_ndvi(ndvi_value=0.35)
  expect_true(inherits(result, "SpatRaster"))
  expect_equal(names(result), "NDVI")
  expect_equal(terra::global(result,"mean",na.rm=TRUE)[1,1], 0.35)
  cat("  load_ndvi : OK\n")
})

# --- Test load_worldclim ---
test_that("load_worldclim retourne SpatRaster avec 2 couches", {
  result <- load_worldclim(country="MA")
  expect_true(inherits(result, "SpatRaster"))
  expect_equal(terra::nlyr(result), 2)
  expect_true("temp_mean_C"    %in% names(result))
  expect_true("prec_annual_mm" %in% names(result))
  cat("  load_worldclim : OK\n")
})

# --- Test summarize_farms ---
test_that("summarize_farms retourne colonnes requises", {
  df <- data.frame(
    parcelle_id    = c("P001","P002"),
    SOC_stock_tCha = c(80.0, 40.0),
    SOC_mean       = c(20.0, 10.0),
    BD_mean        = c(1.3,  1.5),
    lon            = c(-5.0, -5.1),
    lat            = c(32.0, 32.1)
  )
  sol <- sf::st_as_sf(df, coords=c("lon","lat"), crs=4326, remove=FALSE)
  seq_pot <- estimate_sequestration_potential(sol,
               scenarios=c("cover_crop","no_tillage","all_combined"))
  result  <- summarize_farms(sol, seq_pot)
  expect_true("SOC_categorie" %in% names(result))
  expect_true("priorite_seq"  %in% names(result))
  expect_true("max_gain_tCha" %in% names(result))
  cat("  summarize_farms : OK\n")
})

# --- Test analyze_spatial_variability ---
test_that("analyze_spatial_variability retourne stats et moran", {
  df <- data.frame(
    parcelle_id    = paste0("P", sprintf("%03d",1:10)),
    SOC_stock_tCha = runif(10, 50, 100),
    lon            = runif(10, -6.5, -4.5),
    lat            = runif(10,  31.0, 33.0)
  )
  sol    <- sf::st_as_sf(df, coords=c("lon","lat"), crs=4326, remove=FALSE)
  result <- analyze_spatial_variability(sol)
  expect_true("stats" %in% names(result))
  expect_true("moran" %in% names(result))
  expect_equal(result$stats$n, 10)
  cat("  analyze_spatial_variability : OK\n")
})

# --- Test generate_recommendations ---
test_that("generate_recommendations retourne recommandations par parcelle", {
  farm_sum <- data.frame(
    parcelle_id    = c("P001","P002","P003"),
    SOC_stock_tCha = c(30.0,  65.0,  95.0),
    SOC_categorie  = c("Tres faible","Faible","Eleve"),
    priorite_seq   = c("Haute","Moyenne","Faible"),
    best_scenario  = c("all_combined","cover_crop","no_tillage"),
    max_gain_tCha  = c(12.0, 9.75, 9.5)
  )
  seq_pot <- data.frame(
    parcelle_id    = c("P001","P002","P003"),
    SOC_stock_tCha = c(30.0,  65.0,  95.0)
  )
  result <- generate_recommendations(farm_sum, seq_pot)
  expect_equal(nrow(result), 3)
  expect_true("recommandations" %in% names(result))
  expect_true(grepl("URGENT", result$recommandations[1]))
  cat("  generate_recommendations : OK\n")
})
