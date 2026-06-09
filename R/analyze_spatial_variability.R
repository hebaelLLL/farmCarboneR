#' @title Analyser la variabilite spatiale du SOC
#' @description Calcule statistiques descriptives et indice de Moran.
#' @param sol_stock sf object avec colonne SOC_stock_tCha
#' @param output_dir dossier de sauvegarde
#' @return liste avec stats, moran et sol_classified
#' @export
#' @examples
#' # res <- analyze_spatial_variability(sol_stock)
analyze_spatial_variability <- function(sol_stock,
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/data") {
  if (!requireNamespace("sf",    quietly=TRUE)) stop("Package sf requis.")
  if (!requireNamespace("spdep", quietly=TRUE)) stop("Package spdep requis.")
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  soc   <- sol_stock$SOC_stock_tCha
  stats <- list(n=length(soc), mean=round(mean(soc,na.rm=TRUE),3),
                sd=round(sd(soc,na.rm=TRUE),3), min=round(min(soc,na.rm=TRUE),3),
                max=round(max(soc,na.rm=TRUE),3), median=round(median(soc,na.rm=TRUE),3),
                cv=round(sd(soc,na.rm=TRUE)/mean(soc,na.rm=TRUE)*100,2))
  coords_mat <- sf::st_coordinates(sol_stock)
  nb    <- spdep::knn2nb(spdep::knearneigh(coords_mat, k=4))
  lw    <- spdep::nb2listw(nb, style="W")
  moran <- spdep::moran.test(soc, lw)
  sol_stock$SOC_class <- cut(soc,
    breaks=quantile(soc, probs=c(0,0.25,0.50,0.75,1), na.rm=TRUE),
    labels=c("Faible","Moyen-faible","Moyen-eleve","Eleve"), include.lowest=TRUE)
  write.csv(as.data.frame(stats), file.path(output_dir,"spatial_stats.csv"), row.names=FALSE)
  list(stats=stats, moran=moran, sol_classified=sol_stock)
}
