
generate_report <- function(sol_stock,
                            farm_summary,
                            seq_potential,
                            recommendations,
                            rf_result,
                            soc_map,
                            format     = "html",
                            output_dir = "C:/Users/PC Paradise/Desktop/farmCarbonR/outputs") {

  if (!requireNamespace("rmarkdown", quietly=TRUE)) stop("Package rmarkdown requis.")

  dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)

  rmd_path <- file.path(output_dir, "rapport_carbone.Rmd")

  rmd_content <- paste0('---
title: "Rapport Carbone Agricole -- farmCarbonR"
date: "', format(Sys.Date(), "%d %B %Y"), '"
output:
  ', if(format=="pdf") "pdf_document" else "html_document", ':
    toc: true
    toc_depth: 3
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo=FALSE, warning=FALSE, message=FALSE)
library(ggplot2); library(knitr); library(terra); library(sf); library(randomForest)
```

# 1. Resume Executif

```{r}
cat(sprintf("Nombre de parcelles analysees : %d\n",     nrow(farm_summary)))
cat(sprintf("Stock SOC moyen               : %.2f tC/ha\n", mean(farm_summary$SOC_stock_tCha, na.rm=TRUE)))
cat(sprintf("Gain sequestration moyen      : %.2f tC/ha\n", mean(farm_summary$max_gain_tCha,  na.rm=TRUE)))
cat(sprintf("Parcelles urgentes (SOC<40)   : %d\n",     sum(farm_summary$SOC_stock_tCha < 40, na.rm=TRUE)))
```

# 2. Stocks de Carbone par Parcelle

```{r}
knitr::kable(
  farm_summary[, c("parcelle_id","SOC_stock_tCha","SOC_categorie","max_gain_tCha","best_scenario")],
  col.names = c("Parcelle","SOC (tC/ha)","Categorie","Gain max (tC/ha)","Meilleur scenario"),
  digits  = 2,
  caption = "Stocks SOC et potentiel de sequestration"
)
```

# 3. Carte SOC Predite

```{r fig.width=9, fig.height=7}
soc_df <- as.data.frame(soc_map, xy=TRUE)
names(soc_df)[3] <- "SOC"
soc_df <- soc_df[!is.na(soc_df$SOC), ]

pts <- as.data.frame(sf::st_coordinates(sol_stock))
pts$parcelle_id <- sol_stock$parcelle_id

ggplot() +
  geom_raster(data=soc_df, aes(x=x, y=y, fill=SOC)) +
  scale_fill_viridis_c(name="tC/ha", option="magma", direction=-1) +
  geom_point(data=pts, aes(x=X, y=Y),
             color="black", size=2, shape=21, fill="white", stroke=0.8) +
  geom_text(data=pts, aes(x=X, y=Y, label=parcelle_id),
            size=2.5, vjust=-0.8, color="black") +
  labs(title="Stock SOC predit (tC/ha)", x="Longitude", y="Latitude") +
  theme_minimal(base_size=12) +
  theme(plot.title=element_text(hjust=0.5, face="bold"))
```

# 4. Importance des Variables

```{r fig.width=7, fig.height=4}
imp <- as.data.frame(randomForest::importance(rf_result$model))
imp$Variable <- rownames(imp)

ggplot(imp, aes(x=reorder(Variable, `%IncMSE`), y=`%IncMSE`, fill=`%IncMSE`)) +
  geom_bar(stat="identity", width=0.6) +
  scale_fill_gradient(low="#fdae61", high="#d7191c") +
  coord_flip() +
  labs(title="Importance des Variables -- Random Forest",
       x="Variable", y="% Augmentation MSE") +
  theme_minimal(base_size=12) +
  theme(plot.title=element_text(hjust=0.5, face="bold"),
        legend.position="none")
```

# 5. Potentiel de Sequestration

```{r}
cols_seq <- intersect(
  c("parcelle_id","SOC_stock_tCha",
    "gain_cover_crop_tCha","gain_no_tillage_tCha",
    "gain_organic_fert_tCha","gain_all_combined_tCha","max_gain_tCha"),
  names(seq_potential)
)
knitr::kable(
  seq_potential[, cols_seq],
  digits  = 2,
  caption = "Gains potentiels par scenario (tC/ha)"
)
```

# 6. Recommandations

```{r}
knitr::kable(
  recommendations[, c("parcelle_id","SOC_stock_tCha","recommandations")],
  col.names = c("Parcelle","SOC (tC/ha)","Recommandations"),
  digits  = 2,
  caption = "Recommandations par parcelle"
)
```

# 7. Performance du Modele

```{r}
perf <- data.frame(
  Metrique = c("RMSE Train","RMSE Test","R² Train","R² Test"),
  Valeur   = round(c(rf_result$rmse_train, rf_result$rmse_test,
                     rf_result$r2_train,   rf_result$r2_test), 4)
)
knitr::kable(perf, caption="Performance du modele Random Forest")
```

# 8. Variabilite Spatiale

```{r}
stats_soc <- data.frame(
  Statistique = c("N","Moyenne (tC/ha)","Ecart-type","CV (%)","Min (tC/ha)","Max (tC/ha)","Mediane (tC/ha)"),
  Valeur      = c(
    nrow(farm_summary),
    round(mean(farm_summary$SOC_stock_tCha, na.rm=TRUE), 2),
    round(sd(farm_summary$SOC_stock_tCha,   na.rm=TRUE), 2),
    round(sd(farm_summary$SOC_stock_tCha,   na.rm=TRUE) /
          mean(farm_summary$SOC_stock_tCha, na.rm=TRUE) * 100, 1),
    round(min(farm_summary$SOC_stock_tCha,    na.rm=TRUE), 2),
    round(max(farm_summary$SOC_stock_tCha,    na.rm=TRUE), 2),
    round(median(farm_summary$SOC_stock_tCha, na.rm=TRUE), 2)
  )
)
knitr::kable(stats_soc, caption="Statistiques descriptives SOC")
```
')

writeLines(rmd_content, rmd_path)
cat("Template Rmd cree\n")

out_file <- paste0("rapport_carbone.", if(format=="pdf") "pdf" else "html")

rmarkdown::render(
  input       = rmd_path,
  output_file = out_file,
  output_dir  = output_dir,
  envir       = environment()
)

cat(sprintf("\nRapport genere : %s\n", file.path(output_dir, out_file)))
return(file.path(output_dir, out_file))
}

