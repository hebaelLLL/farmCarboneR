
# ============================================================
# TESTS UNITAIRES farmCarbonR
# ============================================================

library(sf)

# Données de test communes
df_base <- data.frame(
  parcelle_id = c("P001", "P002", "P003"),
  SOC_mean    = c(20.0, 10.0, 15.0),
  BD_mean     = c(1.3,  1.5,  1.4),
  lon         = c(-5.0, -5.1, -5.2),
  lat         = c(32.0, 32.1, 32.2)
)
sol_sf <- sf::st_as_sf(df_base, coords = c("lon", "lat"),
                       crs = 4326, remove = FALSE)

# ── calculate_soc_stock ──────────────────────────────────────
test_that("calculate_soc_stock retourne SOC_stock_tCha correct", {
  result <- calculate_soc_stock(sol_sf, depth = 30)
  expect_true("SOC_stock_tCha" %in% names(result))
  expect_equal(result$SOC_stock_tCha[1], round(20.0 * 1.3 * 30 / 10, 2))
  expect_equal(result$SOC_stock_tCha[2], round(10.0 * 1.5 * 30 / 10, 2))
})

test_that("calculate_soc_stock erreur si colonnes manquantes", {
  df_mauvais <- data.frame(x = 1:3, y = 1:3)
  expect_error(calculate_soc_stock(df_mauvais), "SOC_mean")
})

# ── estimate_sequestration_potential ────────────────────────
test_that("estimate_sequestration_potential retourne les colonnes de gain", {
  sol    <- calculate_soc_stock(sol_sf, depth = 30)
  result <- estimate_sequestration_potential(sol)
  expect_true("gain_couvert_tCha"      %in% names(result))
  expect_true("gain_semis_direct_tCha" %in% names(result))
  expect_true("gain_pratiques_tCha"    %in% names(result))
  expect_true("gain_total_tCha"        %in% names(result))
  expect_true("SOC_potentiel_tCha"     %in% names(result))
})

test_that("estimate_sequestration_potential : SOC_potentiel = SOC + gain", {
  sol    <- calculate_soc_stock(sol_sf, depth = 30)
  result <- estimate_sequestration_potential(sol)
  expect_equal(
    result$SOC_potentiel_tCha[1],
    result$SOC_stock_tCha[1] + result$gain_total_tCha[1]
  )
})

test_that("estimate_sequestration_potential erreur si SOC_stock_tCha absent", {
  expect_error(
    estimate_sequestration_potential(df_base),
    "SOC_stock_tCha"
  )
})

# ── load_worldclim ───────────────────────────────────────────
test_that("load_worldclim retourne SpatRaster avec 2 couches", {
  result <- load_worldclim(country = "MA")
  expect_true(inherits(result, "SpatRaster"))
  expect_equal(terra::nlyr(result), 2)
  expect_true("temp_mean_C"    %in% names(result))
  expect_true("prec_annual_mm" %in% names(result))
})

# ── analyze_spatial_variability ──────────────────────────────
test_that("analyze_spatial_variability retourne stats, variogram et moran", {
  # data frame simple (pas sf) avec lon/lat comme colonnes
  df_spatial <- data.frame(
    parcelle_id    = paste0("P", 1:5),
    SOC_stock_tCha = c(50, 60, 45, 70, 55),
    lon            = c(-5.0, -5.1, -5.2, -5.3, -5.4),
    lat            = c(32.0, 32.1, 32.2, 32.3, 32.4)
  )
  result <- analyze_spatial_variability(df_spatial)
  expect_true("stats"        %in% names(result))
  expect_true("variogram_df" %in% names(result))
  expect_true("moran"        %in% names(result))
  expect_true("moyenne"      %in% names(result$stats))
})

test_that("analyze_spatial_variability erreur si colonnes manquantes", {
  df_sans_lon <- data.frame(
    SOC_stock_tCha = c(50, 60),
    lat = c(32, 33)
  )
  expect_error(analyze_spatial_variability(df_sans_lon), "manquantes")
})

# ── summarize_farms ──────────────────────────────────────────
test_that("summarize_farms retourne une liste avec stats et detail", {
  sol    <- calculate_soc_stock(sol_sf, depth = 30)
  result <- summarize_farms(sol)
  # retourne une liste
  expect_type(result, "list")
  expect_true("stats"  %in% names(result))
  expect_true("detail" %in% names(result))
})

test_that("summarize_farms : stats contient les bonnes colonnes", {
  sol    <- calculate_soc_stock(sol_sf, depth = 30)
  result <- summarize_farms(sol)
  expect_true("n_parcelles" %in% names(result$stats))
  expect_true("SOC_moyen"   %in% names(result$stats))
  expect_true("SOC_min"     %in% names(result$stats))
  expect_true("SOC_max"     %in% names(result$stats))
})

test_that("summarize_farms erreur si SOC_stock_tCha absent", {
  expect_error(summarize_farms(df_base), "SOC_stock_tCha")
})

# ── generate_recommendations ─────────────────────────────────
test_that("generate_recommendations retourne la colonne recommandation", {
  sol    <- calculate_soc_stock(sol_sf, depth = 30)
  result <- generate_recommendations(sol)
  # la colonne s'appelle recommandation (sans s)
  expect_true("recommandation" %in% names(result))
  expect_equal(nrow(result), 3)
  expect_true(all(nchar(result$recommandation) > 0))
})

test_that("generate_recommendations erreur si SOC_stock_tCha absent", {
  expect_error(generate_recommendations(df_base), "SOC_stock_tCha")
})

# ── preprocess_data ──────────────────────────────────────────
test_that("preprocess_data retourne train, test et removed_vars", {
  set.seed(42)
  # data frame purement numérique
  df_num <- data.frame(
    SOC_stock_tCha = runif(60, 10, 80),
    temp           = runif(60),
    precip         = runif(60),
    NDVI           = runif(60)
  )
  result <- preprocess_data(df_num, target = "SOC_stock_tCha", seed = 42)
  expect_named(result, c("train", "test", "removed_vars"))
  expect_gt(nrow(result$train), nrow(result$test))
})

test_that("preprocess_data erreur si variable cible absente", {
  df <- data.frame(x = 1:10, y = 1:10)
  expect_error(preprocess_data(df, target = "SOC_stock_tCha"), "introuvable")
})

# ── train_rf_model ───────────────────────────────────────────
test_that("train_rf_model retourne model, importance et oob_error", {
  set.seed(42)
  df_num <- data.frame(
    SOC_stock_tCha = runif(60, 10, 80),
    temp           = runif(60),
    precip         = runif(60),
    NDVI           = runif(60)
  )
  prep <- preprocess_data(df_num, seed = 42)
  rf   <- train_rf_model(prep$train, ntree = 100)
  expect_true("model"      %in% names(rf))
  expect_true("importance" %in% names(rf))
  expect_true("oob_error"  %in% names(rf))
  expect_gt(rf$oob_error, 0)
})
