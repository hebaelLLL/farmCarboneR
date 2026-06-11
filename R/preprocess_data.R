#' Pretraitement des donnees pour la modelisation
#'
#' Normalise les variables numeriques, supprime les variables trop correlees
#' (Pearson > seuil), calcule le VIF et divise en jeux train/test.
#'
#' @param data data.frame issu de extract_covariates()
#' @param target Nom de la colonne cible (defaut: "SOC_stock")
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
#' processed <- preprocess_data(sample_soil_data, target = "SOC_mean")
#' }
preprocess_data <- function(data,
                            target         = "SOC_stock",
                            cor_threshold  = 0.85,
                            vif_threshold  = 10,
                            train_ratio    = 0.8,
                            seed           = 42) {

  if (!target %in% names(data))
    stop("Colonne cible '", target, "' absente des donnees.")

  # Colonnes numeriques explicatives
  num_cols <- names(data)[sapply(data, is.numeric)]
  num_cols <- setdiff(num_cols, target)

  # 1. Suppression variables trop correlees (Pearson)
  cor_mat  <- stats::cor(data[, num_cols], use = "complete.obs")
  cor_upper <- abs(cor_mat)
  cor_upper[lower.tri(cor_upper, diag = TRUE)] <- 0
  to_remove <- c()
  for (i in seq_len(ncol(cor_upper))) {
    for (j in seq_len(nrow(cor_upper))) {
      if (cor_upper[j, i] > cor_threshold) {
        to_remove <- c(to_remove, colnames(cor_upper)[i])
      }
    }
  }
  to_remove <- unique(to_remove)
  features  <- setdiff(num_cols, to_remove)
  if (length(to_remove) > 0)
    message("  Variables retirees (correlation > ", cor_threshold, ") : ",
            paste(to_remove, collapse = ", "))

  # 2. VIF simplifie
  vif_remove <- c()
  if (length(features) > 1) {
    for (feat in features) {
      other <- setdiff(features, feat)
      fm    <- stats::lm(
        stats::as.formula(paste(feat, "~", paste(other, collapse = "+"))),
        data = data
      )
      r2  <- summary(fm)$r.squared
      vif <- if (r2 < 1) 1 / (1 - r2) else Inf
      if (vif > vif_threshold) {
        vif_remove <- c(vif_remove, feat)
        message("  Variable retiree (VIF=", round(vif, 1), ") : ", feat)
      }
    }
    features <- setdiff(features, vif_remove)
  }

  # 3. Normalisation (z-score)
  data_norm <- data
  for (col in features) {
    m <- mean(data[[col]], na.rm = TRUE)
    s <- stats::sd(data[[col]],   na.rm = TRUE)
    if (s > 0) data_norm[[col]] <- (data[[col]] - m) / s
  }

  # 4. Split train/test
  set.seed(seed)
  n      <- nrow(data_norm)
  idx    <- sample(seq_len(n), size = floor(train_ratio * n))
  train  <- data_norm[ idx, ]
  test   <- data_norm[-idx, ]

  message("  Pretraitement termine : ", length(features), " variables conservees")
  message("  Train : ", nrow(train), " lignes | Test : ", nrow(test), " lignes")

  list(
    train         = train,
    test          = test,
    features_kept = features,
    removed_vars  = c(to_remove, vif_remove)
  )
}
