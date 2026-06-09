#' @title Preprocesser les donnees sol
#' @description Normalise et divise les donnees en train/test.
#' @param data sf object avec SOC_stock_tCha et covariables
#' @param target colonne cible (defaut: "SOC_stock_tCha")
#' @param test_size proportion jeu de test (defaut: 0.2)
#' @param scale normaliser les variables numeriques (defaut: TRUE)
#' @return liste avec train, test, full, target, features, scale_params
#' @export
#' @examples
#' # result <- preprocess_data(sol_stock)
preprocess_data <- function(data, target="SOC_stock_tCha",
                             test_size=0.2, scale=TRUE) {
  if (!requireNamespace("sf", quietly=TRUE)) stop("Package sf requis.")

  # Convertir sf en data.frame pour complete.cases
  df <- sf::st_drop_geometry(data)
  df <- df[complete.cases(df), ]

  features <- setdiff(names(df), c("parcelle_id", target, "geometry"))

  scale_params <- list()
  if (scale) {
    for (col in features) {
      if (is.numeric(df[[col]])) {
        m <- mean(df[[col]], na.rm=TRUE)
        s <- sd(df[[col]],   na.rm=TRUE)
        scale_params[[col]] <- list(mean=m, sd=s)
        if (s > 0) df[[col]] <- (df[[col]] - m) / s
      }
    }
  }

  set.seed(42)
  idx   <- sample(nrow(df), floor(nrow(df) * (1 - test_size)))
  train <- df[idx,  ]
  test  <- df[-idx, ]

  cat(sprintf("Train: %d obs | Test: %d obs | Features: %d\n",
              nrow(train), nrow(test), length(features)))

  return(list(
    train       = train,
    test        = test,
    full        = df,
    target      = target,
    features    = features,
    scale_params = scale_params
  ))
}
