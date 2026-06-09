# farmCarbonR

## Description
Package R pour l estimation et la cartographie des stocks de carbone
organique du sol (SOC) en contexte agricole marocain, base sur Random Forest.

## Installation
```r
devtools::install_local("farmCarbonR")
library(farmCarbonR)
```

## Sources de donnees
| Donnee | Source | Resolution |
|--------|--------|-----------|
| SOC terrain | SoilGrids ISRIC | 250m |
| NDVI | MODIS MOD13Q1 | 250m |
| Temperature | WorldClim v2 | 2.5 min |
| Precipitations | WorldClim v2 | 2.5 min |
| Texture sol | SoilGrids ISRIC | 250m |

## Workflow complet
```r
library(farmCarbonR)

# 1. Import donnees sol
sol <- import_soil_data(source="csv", file="data/sol.csv")

# 2. Calcul stock SOC
sol_stock <- calculate_soc_stock(sol, depth=30)

# 3. Chargement covariables
wc   <- load_worldclim(country="MA")
ndvi <- load_ndvi(ndvi_value=0.35)

# 4. Modele Random Forest
rf_result <- train_rf_model(sol_stock)

# 5. Carte SOC
soc_map <- predict_soc_map(rf_result, env_stack)

# 6. Sequestration
seq_pot <- estimate_sequestration_potential(sol_stock,
  scenarios=c("cover_crop","no_tillage","organic_fert","all_combined"))

# 7. Resume + recommandations
farm_sum <- summarize_farms(sol_stock, seq_pot)
recos    <- generate_recommendations(farm_sum, seq_pot)

# 8. Rapport HTML
generate_report(sol_stock, farm_sum, seq_pot, recos, rf_result, soc_map)
```

## Resultats obtenus

### Stock SOC moyen : 79.79 tC/ha (20 parcelles)

| Categorie | Parcelles |
|-----------|-----------|
| Tres faible (<40 tC/ha) | 2 |
| Faible (40-70 tC/ha) | 1 |
| Moyen (70-90 tC/ha) | 14 |
| Eleve (>90 tC/ha) | 3 |

### Potentiel de sequestration

| Scenario | Gain moyen (tC/ha) |
|----------|-------------------|
| Couvert vegetal | +11.97 |
| Sans labour | +7.98 |
| Fertilisation organique | +15.96 |
| Toutes pratiques | +31.92 |

### Performance du modele Random Forest
| Metrique | Valeur |
|----------|--------|
| RMSE Test | voir rf_result$rmse_test |
| R2 Test | voir rf_result$r2_test |

### Variabilite spatiale
- Coefficient de variation : 22.6%
- Indice de Moran I : 0.1317 (p=0.0585)
- Pas d autocorrelation spatiale significative

## Fonctions principales

| Fonction | Description |
|----------|-------------|
| `import_soil_data()` | Import donnees sol CSV |
| `load_worldclim()` | Donnees climatiques WorldClim v2 |
| `load_ndvi()` | NDVI MODIS |
| `load_soilgrids()` | Donnees sol SoilGrids ISRIC |
| `calculate_soc_stock()` | Calcul stock SOC en tC/ha |
| `preprocess_data()` | Normalisation train/test |
| `train_rf_model()` | Modele Random Forest |
| `predict_soc_map()` | Carte spatiale SOC |
| `estimate_sequestration_potential()` | Scenarios sequestration |
| `analyze_spatial_variability()` | Indice Moran + stats |
| `summarize_farms()` | Tableau de bord parcelles |
| `generate_recommendations()` | Recommandations agronomiques |
| `plot_soc_map()` | Visualisation carte SOC |
| `plot_feature_importance()` | Importance des variables |
| `generate_report()` | Rapport HTML/PDF |
## 📊 Visualizations


### SOC Map
![SOC Map](https://raw.githubusercontent.com/hebaelLLL/farmCarboneR/main/outputs/soc_map.png)

### Feature Importance
![Feature Importance](https://raw.githubusercontent.com/hebaelLLL/farmCarboneR/main/outputs/feature_importance.png)
## 📄 Rapport complet

Le rapport d'analyse est disponible ici :
- [Voir le rapport HTML](https://htmlpreview.github.io/?https://github.com/hebaelLLL/farmCarboneR/blob/main/outputs/rapport_carbone.html)
## Licence
MIT (c) 2024
