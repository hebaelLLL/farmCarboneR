library(testthat)
library(sf)

test_that("calculate_soc_stock retourne la colonne SOC_stock_tCha", {
  df <- data.frame(
    parcelle_id = c("P001","P002"),
    SOC_mean    = c(20.0, 10.0),
    BD_mean     = c(1.3,  1.5),
    lon         = c(-5.0, -5.1),
    lat         = c(32.0, 32.1)
  )
  sol    <- sf::st_as_sf(df, coords=c("lon","lat"), crs=4326, remove=FALSE)
  result <- calculate_soc_stock(sol, depth=30)
  expect_true("SOC_stock_tCha" %in% names(result))
  expect_equal(result$SOC_stock_tCha[1], round(20.0 * 1.3 * 30 / 10, 2))
  expect_equal(result$SOC_stock_tCha[2], round(10.0 * 1.5 * 30 / 10, 2))
})

test_that("calcul correct sans fragments grossiers", {
  df <- data.frame(
    parcelle_id = "P001",
    SOC_mean    = 15.0,
    BD_mean     = 1.4,
    lon         = -5.0,
    lat         = 32.0
  )
  sol    <- sf::st_as_sf(df, coords=c("lon","lat"), crs=4326, remove=FALSE)
  result <- calculate_soc_stock(sol, depth=30)
  expect_equal(result$SOC_stock_tCha[1], round(15.0 * 1.4 * 30 / 10, 2))
})

test_that("erreur si colonne SOC_mean manquante", {
  df <- data.frame(
    parcelle_id = "P001",
    BD_mean     = 1.4,
    lon         = -5.0,
    lat         = 32.0
  )
  sol <- sf::st_as_sf(df, coords=c("lon","lat"), crs=4326, remove=FALSE)
  expect_error(calculate_soc_stock(sol))
})
