#' Pretraitement des donnees pour la modelisation
#'
#' Normalise les variables numeriques, supprime les variables trop correlees
#' (Pearson > seuil), calcule le VIF et divise en jeux train/test.
#'
#' @param data data.frame issu de extract_covariates()
#' @param target Nom de la colonne cible (defaut: "SOC_stock_tCha")
#' @param cor_threshold Seuil correlation Pearson (defaut: 0.85)
#' @param vif_threshold Seuil VIF (defaut: 10)
#' @param train_ratio Proportion jeu entrainement (defaut: 0.8)
#' @param seed Graine aleatoire (defaut: 42)
#'
#' @return Liste avec train, test, features_kept, removed_vars
#' @export
#'
#' @examples
#' \dontrun{
#' data(sample_soil_data)
#' processed <- preprocess_data(sample_soil_data, target = "SOC_stock_tCha")
#' }
preprocess_data <- function(data,
                            target         = "SOC_stock_tCha",
                            cor_threshold  = 0.85,
                            vif_threshold  = 10,
                            train_ratio    = 0.8,
                            seed           = 42) {

  if (!target %in% names(data))
    stop("Colonne cible '", target, "' absente des donnees.")

  # ================================
  # 1. Colonnes numériques
  # ================================
  num_cols <- names(data)[sapply(data, is.numeric)]
  num_cols <- setdiff(num_cols, target)

  # ================================
  # 2. SUPPRESSION VARIANCE NULLE
  # ================================
  var_vals <- sapply(data[, num_cols, drop = FALSE],
                     function(x) sd(x, na.rm = TRUE))

  zero_var <- names(var_vals[is.na(var_vals) | var_vals == 0])

  if (length(zero_var) > 0) {
    message("Variables supprimées (variance nulle) : ",
            paste(zero_var, collapse = ", "))
  }

  num_cols <- setdiff(num_cols, zero_var)

  # ================================
  # 3. CORRELATION MATRIX SAFE
  # ================================
  cor_mat <- stats::cor(data[, num_cols, drop = FALSE],
                        use = "pairwise.complete.obs")

  cor_mat[is.na(cor_mat)] <- 0

  cor_upper <- abs(cor_mat)
  cor_upper[lower.tri(cor_upper, diag = TRUE)] <- 0

  to_remove <- colnames(cor_upper)[
    apply(cor_upper, 2, function(col) any(col > cor_threshold))
  ]

  features <- setdiff(num_cols, to_remove)

  if (length(to_remove) > 0) {
    message("Variables retirees (correlation > ", cor_threshold, ") : ",
            paste(to_remove, collapse = ", "))
  }

  # ================================
  # 4. VIF (simplifié mais stable)
  # ================================
  vif_remove <- c()

  if (length(features) > 1) {
    for (feat in features) {

      other <- setdiff(features, feat)

      if (length(other) == 0) next

      fm <- tryCatch(
        stats::lm(
          stats::as.formula(paste(feat, "~", paste(other, collapse = "+"))),
          data = data
        ),
        error = function(e) NULL
      )

      if (is.null(fm)) next

      r2 <- summary(fm)$r.squared
      vif <- ifelse(r2 >= 1, Inf, 1 / (1 - r2))

      if (vif > vif_threshold) {
        vif_remove <- c(vif_remove, feat)
      }
    }

    features <- setdiff(features, vif_remove)
  }

  # ================================
  # 5. NORMALISATION (SAFE)
  # ================================
  data_norm <- data

  for (col in features) {
    m <- mean(data[[col]], na.rm = TRUE)
    s <- sd(data[[col]], na.rm = TRUE)

    if (!is.na(s) && s > 0) {
      data_norm[[col]] <- (data[[col]] - m) / s
    }
  }
  features <- setdiff(features, target)
  # ================================
  # 6. TRAIN / TEST SPLIT
  # ================================
  set.seed(seed)

  n <- nrow(data_norm)
  idx <- sample(seq_len(n), size = floor(train_ratio * n))

  train <- data_norm[idx, , drop = FALSE]
  test  <- data_norm[-idx, , drop = FALSE]

  # ================================
  # OUTPUT
  # ================================
  message("Pretraitement termine : ", length(features), " variables conservees")
  message("Train : ", nrow(train), " | Test : ", nrow(test))

  return(list(
    train         = train,
    test          = test,
    features_kept = features,
    removed_vars  = unique(c(to_remove, vif_remove))
  ))
}
