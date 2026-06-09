# =============================================================================
# import_agricultural_practices.R - farmCarbonR
# Import et harmonisation des pratiques agricoles
# =============================================================================

#' Importer les pratiques agricoles
#'
#' @param path       Chemin vers le fichier CSV ou Excel
#' @param coords_sf  Objet sf issu de import_soil_data() pour jointure spatiale
#'                   (optionnel -- jointure par parcelle_id si NULL)
#' @param join_by    Colonne de jointure (defaut: "parcelle_id")
#'
#' @return data.frame harmonise des pratiques agricoles avec colonnes standardisees :
#'   parcelle_id, travail_sol, couvert_vegetal, irrigation, fertilisation_organique
#'
#' @examples
#' # pratiques <- import_agricultural_practices('data/pratiques.csv')
import_agricultural_practices <- function(path,
                                          coords_sf = NULL,
                                          join_by   = "parcelle_id") {

  # --- Verifications ----------------------------------------------------------
  if (!file.exists(path)) stop("Fichier introuvable : ", path)

  ext <- tolower(tools::file_ext(path))
  if (!ext %in% c("csv", "xls", "xlsx"))
    stop("Format non supporte : ", ext, ". Utiliser CSV ou Excel.")

  # --- Lecture ----------------------------------------------------------------
  data <- if (ext == "csv") {
    utils::read.csv(path, stringsAsFactors = FALSE, encoding = "UTF-8")
  } else {
    if (!requireNamespace("utils", quietly=TRUE))
      stop("Package 'readxl' requis pour les fichiers Excel.")
    stop("Fichiers Excel non supportes. Utiliser CSV.")
  }

  cat("Fichier lu :", nrow(data), "parcelles,", ncol(data), "colonnes\n")

  # --- Normalisation des noms de colonnes ------------------------------------
  names(data) <- .normalize_colnames(names(data))

  # --- Harmonisation des colonnes cles ---------------------------------------
  data <- .harmonize_tillage(data)
  data <- .harmonize_cover_crop(data)
  data <- .harmonize_irrigation(data)
  data <- .harmonize_organic_fert(data)

  # --- Verification colonne de jointure --------------------------------------
  if (!join_by %in% names(data))
    stop("Colonne de jointure '", join_by, "' introuvable dans le fichier.")

  # --- Jointure spatiale (optionnelle) ----------------------------------------
  if (!is.null(coords_sf)) {
    if (!requireNamespace("sf", quietly = TRUE))
      stop("Package 'sf' requis pour la jointure spatiale.")
    if (!join_by %in% names(coords_sf))
      stop("Colonne '", join_by, "' absente de l'objet sf.")

    n_avant  <- nrow(data)
    data     <- merge(data,
                      sf::st_drop_geometry(coords_sf)[, join_by, drop = FALSE],
                      by   = join_by,
                      all.x = FALSE)   # inner join : garder seulement les parcelles communes
    n_apres  <- nrow(data)
    n_perdu  <- n_avant - n_apres

    if (n_perdu > 0)
      warning(n_perdu, " parcelle(s) sans correspondance spatiale supprimee(s).")

    cat("Jointure spatiale : ", n_apres, "parcelles appariees\n")
  }

  # --- Gestion des NA --------------------------------------------------------
  data <- .handle_na_practices(data)

  # --- Resume ----------------------------------------------------------------
  .print_practices_summary(data)

  return(data)
}


# =============================================================================
# FONCTIONS INTERNES
# =============================================================================

#' Normaliser les noms de colonnes (minuscules, sans accents, underscores)
#' @noRd
.normalize_colnames <- function(nms) {
  nms <- tolower(nms)
  nms <- gsub("[aáaãäå]", "a", nms)
  nms <- gsub("[eeeë]",   "e", nms)
  nms <- gsub("[iï]",     "i", nms)
  nms <- gsub("[oõö]",    "o", nms)
  nms <- gsub("[ùúuü]",   "u", nms)
  nms <- gsub("[c]",      "c", nms)
  nms <- gsub("[^a-z0-9_]", "_", nms)
  nms <- gsub("_+", "_", nms)
  nms <- gsub("^_|_$", "", nms)
  nms
}

#' Harmoniser la colonne travail du sol → "labour" / "non-labour" / "minimum"
#' @noRd
.harmonize_tillage <- function(data) {
  candidates <- c("travail_sol", "travail", "tillage", "labour", "labourage",
                  "type_travail", "travail_du_sol")
  col <- intersect(candidates, names(data))[1]
  if (is.na(col)) {
    warning("Colonne 'travail_sol' non trouvee -- colonne NA ajoutee.")
    data$travail_sol <- NA_character_
    return(data)
  }
  if (col != "travail_sol") {
    names(data)[names(data) == col] <- "travail_sol"
  }
  data$travail_sol <- case_when(
    grepl("non.labour|no.till|sans.labour|direct|zero|zero", data$travail_sol, ignore.case = TRUE) ~ "non-labour",
    grepl("minimum|reduit|reduit|superficiel|strip",         data$travail_sol, ignore.case = TRUE) ~ "minimum",
    grepl("labour|conventionnel|profond|deep|full",          data$travail_sol, ignore.case = TRUE) ~ "labour",
    TRUE ~ NA_character_
  )
  data
}

#' Harmoniser couvert vegetal → "oui" / "non"
#' @noRd
.harmonize_cover_crop <- function(data) {
  candidates <- c("couvert_vegetal", "couvert", "cover_crop", "culture_couverture",
                  "covert", "engrais_vert")
  col <- intersect(candidates, names(data))[1]
  if (is.na(col)) {
    warning("Colonne 'couvert_vegetal' non trouvee -- colonne NA ajoutee.")
    data$couvert_vegetal <- NA_character_
    return(data)
  }
  if (col != "couvert_vegetal") {
    names(data)[names(data) == col] <- "couvert_vegetal"
  }
  data$couvert_vegetal <- case_when(
    grepl("^(oui|yes|1|true|vrai|present|present)$", data$couvert_vegetal, ignore.case = TRUE) ~ "oui",
    grepl("^(non|no|0|false|faux|absent)$",           data$couvert_vegetal, ignore.case = TRUE) ~ "non",
    TRUE ~ NA_character_
  )
  data
}

#' Harmoniser irrigation → "oui" / "non"
#' @noRd
.harmonize_irrigation <- function(data) {
  candidates <- c("irrigation", "irrigue", "irrigated", "arrosage")
  col <- intersect(candidates, names(data))[1]
  if (is.na(col)) {
    warning("Colonne 'irrigation' non trouvee -- colonne NA ajoutee.")
    data$irrigation <- NA_character_
    return(data)
  }
  if (col != "irrigation") {
    names(data)[names(data) == col] <- "irrigation"
  }
  data$irrigation <- case_when(
    grepl("^(oui|yes|1|true|vrai|irrigue|irrigue)$", data$irrigation, ignore.case = TRUE) ~ "oui",
    grepl("^(non|no|0|false|faux|pluvial|sec)$",      data$irrigation, ignore.case = TRUE) ~ "non",
    TRUE ~ NA_character_
  )
  data
}

#' Harmoniser fertilisation organique → "oui" / "non"
#' @noRd
.harmonize_organic_fert <- function(data) {
  candidates <- c("fertilisation_organique", "fertilisation", "organic_fert",
                  "apport_organique", "fumure", "compost", "matiere_organique")
  col <- intersect(candidates, names(data))[1]
  if (is.na(col)) {
    warning("Colonne 'fertilisation_organique' non trouvee -- colonne NA ajoutee.")
    data$fertilisation_organique <- NA_character_
    return(data)
  }
  if (col != "fertilisation_organique") {
    names(data)[names(data) == col] <- "fertilisation_organique"
  }
  data$fertilisation_organique <- case_when(
    grepl("^(oui|yes|1|true|vrai)$", data$fertilisation_organique, ignore.case = TRUE) ~ "oui",
    grepl("^(non|no|0|false|faux)$", data$fertilisation_organique, ignore.case = TRUE) ~ "non",
    TRUE ~ NA_character_
  )
  data
}

#' Gerer les NA : signaler sans supprimer
#' @noRd
.handle_na_practices <- function(data) {
  key_cols <- c("travail_sol", "couvert_vegetal", "irrigation", "fertilisation_organique")
  key_cols <- intersect(key_cols, names(data))

  for (col in key_cols) {
    n_na <- sum(is.na(data[[col]]))
    if (n_na > 0)
      message("  [NA] ", col, " : ", n_na, " valeur(s) manquante(s) ou non reconnue(s)")
  }
  data
}

#' Afficher un resume des pratiques
#' @noRd
.print_practices_summary <- function(data) {
  cat("\n=== Resume des pratiques agricoles ===\n")
  key_cols <- c("travail_sol", "couvert_vegetal", "irrigation", "fertilisation_organique")
  key_cols <- intersect(key_cols, names(data))
  for (col in key_cols) {
    cat("\n", col, ":\n", sep = "")
    print(table(data[[col]], useNA = "ifany"))
  }
  cat("\n")
}
