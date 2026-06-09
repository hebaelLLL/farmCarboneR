#' @title Generer des recommandations agronomiques
#' @description Produit des recommandations par parcelle selon le stock SOC.
#' @param farm_summary data.frame retourne par summarize_farms()
#' @param seq_potential data.frame retourne par estimate_sequestration_potential()
#' @param output_dir dossier de sauvegarde
#' @return data.frame avec recommandations par parcelle
#' @export
#' @examples
#' # reco <- generate_recommendations(farm_summary, seq_potential)
generate_recommendations <- function(farm_summary, seq_potential,
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/outputs") {
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  reco_list <- list()
  for (i in seq_len(nrow(farm_summary))) {
    pid <- farm_summary$parcelle_id[i]; soc <- farm_summary$SOC_stock_tCha[i]
    best_sc <- gsub("^gain_|_tCha$","", as.character(farm_summary$best_scenario[i]))
    recos <- if (!is.na(soc) && soc < 40) {
      c("URGENT: Stock tres faible","Introduire couverts vegetaux",
        "Apporter compost 10-15t/ha","Arreter labour profond")
    } else if (!is.na(soc) && soc < 70) {
      c("Stock faible","Legumineuses en rotation",
        "Reduire labour","Apports organiques reguliers")
    } else if (!is.na(soc) && soc < 90) {
      c("Stock moyen -- maintenir pratiques",
        "Maintenir couverts vegetaux","Rotation diversifiee")
    } else c("Stock eleve -- conserver pratiques","Parcelle de reference")
    sc_recos <- list(cover_crop="Priorite: couvert vegetal (+15%)",
                     no_tillage="Priorite: semis direct (+10%)",
                     organic_fert="Priorite: fertilisation organique (+20%)",
                     all_combined="Priorite: toutes pratiques (+40%)")
    if (!is.na(best_sc) && best_sc %in% names(sc_recos))
      recos <- c(recos, sc_recos[[best_sc]])
    reco_list[[pid]] <- data.frame(parcelle_id=pid, SOC_stock_tCha=soc,
      recommandations=paste(recos,collapse=" | "), stringsAsFactors=FALSE)
  }
  reco_df <- do.call(rbind, reco_list)
  write.csv(reco_df, file.path(output_dir,"recommendations.csv"), row.names=FALSE)
  return(reco_df)
}
