
#' Entrainer le modele Random Forest
#'
#' @param train_data Data frame d'entrainement.
#' @param test_data Data frame de test (optionnel).
#' @param target Variable cible. Par defaut "SOC_stock_tCha".
#' @param exclude Vecteur de colonnes a exclure des predicteurs. Par defaut NULL.
#' @param test_size Proportion pour le split test si test_data NULL. Par defaut 0.2.
#' @param ntree Nombre d'arbres. Par defaut 500.
#' @param mtry Variables par split. Par defaut NULL (auto).
#' @param seed Graine. Par defaut 42.
#' @return Liste : model, importance, oob_error, rmse_train, rmse_test,
#'   r2_train, r2_test, predicteurs.
#' @export
train_rf_model <- function(train_data,
                           test_data  = NULL,
                           target     = "SOC_stock_tCha",
                           exclude    = NULL,
                           test_size  = 0.2,
                           ntree      = 500,
                           mtry       = NULL,
                           seed       = 42) {

  if (!target %in% names(train_data))
    stop(paste("Variable cible introuvable :", target))

  # =========================
  # SPLIT TRAIN / TEST AUTO
  # =========================
  if (is.null(test_data)) {
    set.seed(seed)
    n        <- nrow(train_data)
    idx_test <- sample(seq_len(n), size = floor(test_size * n))
    test_data  <- train_data[idx_test,  ]
    train_data <- train_data[-idx_test, ]
    message(sprintf("Split auto : %d train / %d test (%.0f%%)",
                    nrow(train_data), nrow(test_data), test_size * 100))
  }

  # =========================
  # SELECTION DES PREDICTEURS
  # =========================
  # Exclure : cible + colonnes non numeriques + colonnes explicitement exclues
  a_exclure  <- union(target, exclude)
  predicteurs <- setdiff(
    names(train_data)[sapply(train_data, is.numeric)],
    a_exclure
  )

  if (length(predicteurs) == 0)
    stop("Aucune variable explicative numerique trouvee.")

  message("Predicteurs utilises : ", paste(predicteurs, collapse = ", "))

  X <- train_data[, predicteurs, drop = FALSE]
  y <- train_data[[target]]

  if (is.null(mtry)) mtry <- max(1, floor(length(predicteurs) / 3))

  set.seed(seed)
  message(sprintf("Entrainement RF : %d arbres, %d variables, mtry=%d...",
                  ntree, length(predicteurs), mtry))

  rf_model <- randomForest::randomForest(
    x          = X,
    y          = y,
    ntree      = ntree,
    mtry       = mtry,
    importance = TRUE
  )

  # =========================
  # IMPORTANCE
  # =========================
  imp          <- as.data.frame(randomForest::importance(rf_model))
  imp$variable <- rownames(imp)
  imp          <- dplyr::arrange(imp, dplyr::desc(`%IncMSE`))

  # =========================
  # METRIQUES TRAIN
  # =========================
  pred_train <- predict(rf_model, X)
  ss_res_tr  <- sum((y - pred_train)^2, na.rm = TRUE)
  ss_tot_tr  <- sum((y - mean(y, na.rm = TRUE))^2, na.rm = TRUE)
  rmse_train <- sqrt(mean((y - pred_train)^2, na.rm = TRUE))
  r2_train   <- 1 - ss_res_tr / ss_tot_tr

  # =========================
  # METRIQUES TEST
  # =========================
  rmse_test <- NA_real_
  r2_test   <- NA_real_

  if (!is.null(test_data) && target %in% names(test_data)) {
    pred_test_vars <- intersect(predicteurs, names(test_data))
    if (length(pred_test_vars) == length(predicteurs)) {
      X_test    <- test_data[, predicteurs, drop = FALSE]
      y_test    <- test_data[[target]]
      pred_test <- predict(rf_model, X_test)
      ss_res_te <- sum((y_test - pred_test)^2, na.rm = TRUE)
      ss_tot_te <- sum((y_test - mean(y_test, na.rm = TRUE))^2, na.rm = TRUE)
      rmse_test <- sqrt(mean((y_test - pred_test)^2, na.rm = TRUE))
      r2_test   <- 1 - ss_res_te / ss_tot_te
    } else {
      warning("Certains predicteurs absents de test_data — metriques test non calculees.")
    }
  }

  oob_rmse <- sqrt(rf_model$mse[ntree])

  message(sprintf(
    "RF entraine.\n  OOB RMSE   = %.4f\n  RMSE Train = %.4f | R2 Train = %.4f\n  RMSE Test  = %.4f | R2 Test  = %.4f",
    oob_rmse, rmse_train, r2_train,
    ifelse(is.na(rmse_test), -999, rmse_test),
    ifelse(is.na(r2_test),   -999, r2_test)
  ))

  return(list(
    model       = rf_model,
    importance  = imp,
    oob_error   = oob_rmse,
    rmse_train  = rmse_train,
    r2_train    = r2_train,
    rmse_test   = rmse_test,
    r2_test     = r2_test,
    predicteurs = predicteurs
  ))
}
