library(testthat)
library(sf)

test_that("erreur si fichier manquant", {
  expect_error(import_soil_data(source="csv", file="rien.csv"))
})

test_that("erreur si source inconnue", {
  expect_error(import_soil_data(source="oracle"), "source doit etre")
})

test_that("import_soil_data charge un CSV correctement", {
  tmp <- tempfile(fileext=".csv")
  write.csv(data.frame(
    parcelle_id = c("P001","P002"),
    SOC_mean    = c(20.0, 15.0),
    BD_mean     = c(1.3,  1.4),
    lon         = c(-5.0, -5.1),
    lat         = c(32.0, 32.1)
  ), tmp, row.names=FALSE)
  result <- import_soil_data(source="csv", file=tmp)
  expect_true(inherits(result, "sf"))
  expect_equal(nrow(result), 2)
  file.remove(tmp)
})
