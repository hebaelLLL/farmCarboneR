#' @title Entrainer un modele Random Forest
#' @description Entraine un modele RF pour predire le stock SOC.
#' @param sol_stock sf object avec SOC_stock_tCha et covariables
#' @param features vecteur de noms de covariables
#' @param ntree nombre d arbres (defaut: 500)
#' @param test_size proportion jeu de test (defaut: 0.2)
#' @param output_dir dossier de sauvegarde
#' @return liste avec model, rmse_train, rmse_test, r2_train, r2_test, features
#' @export
#' @examples
#' # rf <- train_rf_model(sol_stock)
train_rf_model <- function(sol_stock, features=NULL, ntree=500, test_size=0.2,
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  if (!requireNamespace("randomForest", quietly=TRUE)) stop("Package randomForest requis.")
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  df <- sf::st_drop_geometry(sol_stock)
  if (is.null(features))
    features <- setdiff(names(df), c("parcelle_id","SOC_stock_tCha","geometry"))
  df <- df[, c("SOC_stock_tCha", features)]
  df <- df[complete.cases(df), ]
  set.seed(42)
  idx   <- sample(nrow(df), floor(nrow(df)*(1-test_size)))
  train <- df[idx,]; test <- df[-idx,]
  model <- randomForest::randomForest(SOC_stock_tCha ~ ., data=train,
                                       ntree=ntree, importance=TRUE)
  pred_train <- predict(model, train); pred_test <- predict(model, test)
  rmse <- function(a,b) sqrt(mean((a-b)^2, na.rm=TRUE))
  r2   <- function(a,b) 1 - sum((a-b)^2)/sum((a-mean(a))^2)
  result <- list(model=model, features=features,
    rmse_train=rmse(train$SOC_stock_tCha, pred_train),
    rmse_test =rmse(test$SOC_stock_tCha,  pred_test),
    r2_train  =r2(train$SOC_stock_tCha,   pred_train),
    r2_test   =r2(test$SOC_stock_tCha,    pred_test))
  cat(sprintf("RF -- RMSE test: %.3f | R2 test: %.3f\n",
              result$rmse_test, result$r2_test))
  return(result)
}
