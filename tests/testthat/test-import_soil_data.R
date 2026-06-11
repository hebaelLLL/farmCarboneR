library(farmCarbonR)

test_that("import_soil_data retourne une liste avec sf_object et dataframe", {
  path <- system.file("extdata", "exemple_sol.csv", package = "farmCarbonR")
  skip_if_not(file.exists(path))
  result <- import_soil_data(source = "csv", path = path)
  # retourne une liste
  expect_type(result, "list")
  expect_true("sf_object" %in% names(result))
  expect_true("dataframe" %in% names(result))
  expect_s3_class(result$sf_object, "sf")
})

test_that("erreur si fichier manquant", {
  expect_error(
    import_soil_data(source = "csv", path = "rien.csv"),
    "Chemin CSV invalide"
  )
})

test_that("erreur si source inconnue", {
  expect_error(
    import_soil_data(source = "oracle"),
    "source doit etre csv ou soilgrids"
  )
})
