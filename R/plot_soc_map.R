#' @title Visualiser la carte SOC
#' @description Produit une carte ggplot2 du stock SOC predit.
#' @param soc_map SpatRaster retourne par predict_soc_map()
#' @param sol_stock sf object des parcelles (optionnel)
#' @param output_dir dossier de sauvegarde
#' @param filename nom du fichier PNG
#' @param title titre de la carte
#' @return objet ggplot2
#' @export
#' @examples
#' # p <- plot_soc_map(soc_map, sol_stock)
plot_soc_map <- function(soc_map, sol_stock=NULL,
  output_dir="C:/Users/PC Paradise/Desktop/farmCarbonR/outputs",
  filename="soc_map.png", title="Stock de Carbone Organique (tC/ha)") {
  if (!requireNamespace("terra",   quietly=TRUE)) stop("Package terra requis.")
  if (!requireNamespace("ggplot2", quietly=TRUE)) stop("Package ggplot2 requis.")
  if (!requireNamespace("viridis", quietly=TRUE)) stop("Package viridis requis.")
  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)
  soc_df <- as.data.frame(soc_map, xy=TRUE)
  names(soc_df)[3] <- "SOC"
  soc_df <- soc_df[!is.na(soc_df$SOC),]
  x <- y <- SOC <- X <- Y <- parcelle_id <- NULL
  p <- ggplot2::ggplot() +
    ggplot2::geom_raster(data=soc_df, ggplot2::aes(x=x, y=y, fill=SOC)) +
    viridis::scale_fill_viridis(name="tC/ha", option="magma", direction=-1) +
    ggplot2::labs(title=title, x="Longitude", y="Latitude") +
    ggplot2::theme_minimal(base_size=12) +
    ggplot2::theme(plot.title=ggplot2::element_text(hjust=0.5,face="bold"))
  if (!is.null(sol_stock)) {
    pts <- as.data.frame(sf::st_coordinates(sol_stock))
    pts$parcelle_id <- sol_stock$parcelle_id
    p <- p + ggplot2::geom_point(data=pts, ggplot2::aes(x=X,y=Y),
      color="black", size=2, shape=21, fill="white", stroke=0.8) +
      ggplot2::geom_text(data=pts, ggplot2::aes(x=X,y=Y,label=parcelle_id),
        size=2.5, vjust=-0.8, color="black")
  }
  ggplot2::ggsave(file.path(output_dir,filename), plot=p, width=10, height=8, dpi=150)
  return(p)
}
