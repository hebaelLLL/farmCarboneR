library(testthat)
library(farmCarbonR)

test_that("preprocess_data retourne train et test", {
  set.seed(42)
  df <- data.frame(
    parcelle_id    = paste0("P", sprintf("%03d", 1:20)),
    SOC_stock_tCha = runif(20, 40, 100),
    NDVI           = runif(20, 0.2, 0.6),
    temp_mean_C    = runif(20, 15,  25),
    prec_annual_mm = runif(20, 100, 400),
    lon            = runif(20, -6.5, -4.5),
    lat            = runif(20,  31.0, 33.0)
  )
  # test avec sf
  sol    <- sf::st_as_sf(df, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
  result <- preprocess_data(sol)
  expect_true("train"        %in% names(result))
  expect_true("test"         %in% names(result))
  expect_true("removed_vars" %in% names(result))  # la fonction retourne removed_vars
  expect_gt(nrow(result$train), nrow(result$test))
})

test_that("preprocess_data fonctionne aussi sur data frame simple", {
  set.seed(1)
  df_num <- data.frame(
    SOC_stock_tCha = runif(50, 10, 80),
    temp           = runif(50),
    precip         = runif(50),
    NDVI           = runif(50)
  )
  result <- preprocess_data(df_num, seed = 1)
  expect_named(result, c("train", "test", "removed_vars"))
  expect_gt(nrow(result$train), nrow(result$test))
})

test_that("preprocess_data erreur si variable cible absente", {
  df <- data.frame(x = 1:10, y = 1:10)
  expect_error(preprocess_data(df, target = "SOC_stock_tCha"), "introuvable")
})
