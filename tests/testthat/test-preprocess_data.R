library(testthat)

test_that("preprocess_data retourne train et test", {
  df <- data.frame(
    parcelle_id    = paste0("P", sprintf("%03d",1:20)),
    SOC_stock_tCha = runif(20, 40, 100),
    NDVI           = runif(20, 0.2, 0.6),
    temp_mean_C    = runif(20, 15, 25),
    prec_annual_mm = runif(20, 100, 400),
    lon            = runif(20, -6.5, -4.5),
    lat            = runif(20,  31.0, 33.0)
  )
  sol    <- sf::st_as_sf(df, coords=c("lon","lat"), crs=4326, remove=FALSE)
  result <- preprocess_data(sol)
  expect_true("train"        %in% names(result))
  expect_true("test"         %in% names(result))
  expect_true("scale_params" %in% names(result))
})
