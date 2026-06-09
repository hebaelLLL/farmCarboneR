#' @title Resumer les donnees des parcelles agricoles
#' @description Produit un tableau de bord par parcelle.
#' @param sol_stock sf object avec colonnes SOC
#' @param seq_potential data.frame retourne par estimate_sequestration_potential()
#' @param pratiques data.frame de pratiques agricoles (optionnel)
#' @param output_dir dossier de sauvegarde
#' @return data.frame resume par parcelle
#' @export
#' @examples
#' # farm_summary <- summarize_farms(sol_stock, seq_potential)
summarize_farms <- function(sol_stock, seq_potential, pratiques=NULL,
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  sol_df <- sf::st_drop_geometry(sol_stock)[,c("parcelle_id","SOC_mean","BD_mean","SOC_stock_tCha")]
  summary_df <- merge(sol_df, seq_potential[,c("parcelle_id","max_gain_tCha","best_scenario")],
                      by="parcelle_id", all.x=TRUE)
  if (!is.null(pratiques) && "parcelle_id" %in% names(pratiques))
    summary_df <- merge(summary_df, pratiques, by="parcelle_id", all.x=TRUE)
  summary_df$SOC_categorie <- cut(summary_df$SOC_stock_tCha,
    breaks=c(0,40,70,90,Inf),
    labels=c("Tres faible","Faible","Moyen","Eleve"), include.lowest=TRUE)
  summary_df$priorite_seq <- cut(summary_df$max_gain_tCha,
    breaks=quantile(summary_df$max_gain_tCha, probs=c(0,0.33,0.67,1), na.rm=TRUE),
    labels=c("Faible","Moyenne","Haute"), include.lowest=TRUE)
  write.csv(summary_df, file.path(output_dir,"farm_summary.csv"), row.names=FALSE)
  return(summary_df)
}
