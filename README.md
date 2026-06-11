# farmCarbonR <img src="https://img.shields.io/badge/R-package-blue" align="right"/>

> Package R pour l'estimation, la modélisation et la cartographie du stock de carbone organique des sols agricoles (SOC).

---

## Table des matières

- [Description](#description)
- [Installation](#installation)
- [Dépendances](#dépendances)
- [Sources des données](#sources-des-données)
- [Structure du package](#structure-du-package)
- [Workflow complet](#workflow-complet)
- [Fonctions & Utilisation](#fonctions--utilisation)
  - [1. import_soil_data()](#1-import_soil_data)
  - [2. import_agricultural_practices()](#2-import_agricultural_practices)
  - [3. calculate_soc_stock()](#3-calculate_soc_stock)
  - [4. load_environmental_covariates()](#4-load_environmental_covariates)
  - [5. extract_covariates()](#5-extract_covariates)
  - [6. preprocess_data()](#6-preprocess_data)
  - [7. train_rf_model()](#7-train_rf_model)
  - [8. predict_soc_map()](#8-predict_soc_map)
  - [9. estimate_sequestration_potential()](#9-estimate_sequestration_potential)
  - [10. analyze_spatial_variability()](#10-analyze_spatial_variability)
  - [11. summarize_farms()](#11-summarize_farms)
  - [12. plot_soc_map()](#12-plot_soc_map)
  - [13. plot_feature_importance()](#13-plot_feature_importance)
  - [14. generate_recommendations()](#14-generate_recommendations)
  - [15. generate_report()](#15-generate_report)
- [Rapport généré](#rapport-généré)
- [Auteur](#auteur)

---

## Description

`farmCarbonR` est un outil scientifique complet permettant :

- d'**estimer le stock actuel de carbone (SOC)** à partir de données SoilGrids
- d'**évaluer l'impact des pratiques agricoles** sur le carbone du sol
- d'**identifier les zones prioritaires** pour la séquestration
- de **modéliser le SOC** avec un modèle Random Forest
- de **générer des rapports HTML/PDF automatiques** avec visualisations

---

## Installation

```r
# Depuis le dossier local
devtools::install(".")

# Depuis GitHub
devtools::install_github("votre_nom/farmCarbonR")
```

---

## Dépendances

```r
install.packages(c(
  "httr", "jsonlite", "readr", "readxl",
  "dplyr", "tidyr", "purrr", "sf", "terra",
  "geodata", "MODISTools", "spdep", "gstat",
  "randomForest", "caret", "ggplot2",
  "rmarkdown", "knitr", "gridExtra", "corrplot"
))
```

---

## Sources des données

| Donnée | Package R | Source | URL |
|--------|-----------|--------|-----|
| SOC, texture, densité | `httr` | SoilGrids v2.0 ISRIC | https://rest.isric.org/soilgrids/v2.0 |
| NDVI | `MODISTools` | MODIS MOD13A3 NASA | https://modis.gsfc.nasa.gov |
| Température, précipitations | `geodata` | WorldClim v2 | https://worldclim.org |
| Altitude | `geodata` | SRTM NASA | https://srtm.csi.cgiar.org |
| Pratiques agricoles | — | Terrain CSV/Excel | — |

> **Note :** la taille de l'échantillon de parcelles a été augmentée par rapport aux versions précédentes, afin d'améliorer la robustesse statistique du modèle Random Forest et la représentativité spatiale des cartes générées.

---

## Structure du package

```
farmCarbonR/
├── R/
│   ├── import_soil_data.R                  # SoilGrids + CSV + shapefile
│   ├── import_agricultural_practices.R     # CSV + Excel
│   ├── load_environmental_covariates.R     # MODIS + WorldClim + SRTM
│   ├── load_ndvi.R                         # MODIS MOD13A3
│   ├── extract_covariates.R                # Jointure sol + env
│   ├── calculate_soc_stock.R               # Formule SOC
│   ├── preprocess_data.R                   # Pearson + VIF + split
│   ├── train_rf_model.R                    # Random Forest
│   ├── predict_soc_map.R                   # Raster GeoTIFF
│   ├── estimate_sequestration_potential.R  # 3 scénarios
│   ├── analyze_spatial_variability.R       # Moran + variogramme
│   ├── summarize_farms.R                   # Tableau synthèse
│   ├── plot_soc_map.R                      # 3 cartes ggplot2
│   ├── plot_feature_importance.R           # Barplot RF
│   ├── generate_recommendations.R          # Recommandations auto
│   ├── generate_report.R                   # Rapport HTML/PDF
│   ├── set_study_area.R                    # Zone d'étude
│   └── farmCarbonR-package.R
├── inst/extdata/
│   ├── exemple_sol.csv
│   └── exemple_pratiques.csv
├── outputs/
│   ├── soc_map.tif
│   ├── cartes_soc.pdf
│   ├── importance.png
│   └── rapport_farmCarbonR.html      # ← Rapport final généré par generate_report()
├── man/
├── DESCRIPTION
├── NAMESPACE
└── README.md
```

---

## Workflow complet

```
coords / shapefile
       │
       ▼
import_soil_data()          ←── SoilGrids ISRIC
       │
       ├── import_agricultural_practices()   ←── CSV / Excel terrain
       │
       ▼
calculate_soc_stock()       ←── SOC × BD × Depth × (1 - RF) / 10
       │
       ├── load_environmental_covariates()   ←── MODIS + WorldClim + SRTM
       │
       ▼
extract_covariates()         ←── Jointure sol + environnement
       │
       ▼
preprocess_data()            ←── Pearson + VIF + normalisation + split
       │
       ▼
train_rf_model()             ←── Random Forest
       │
       ├── predict_soc_map()              ←── Raster GeoTIFF
       │
       ▼
estimate_sequestration_potential()  ←── 3 scénarios
       │
       ├── analyze_spatial_variability()  ←── Moran + variogramme
       ├── summarize_farms()              ←── Tableau synthèse
       ├── plot_soc_map()                 ←── 3 cartes
       ├── plot_feature_importance()      ←── Barplot RF
       ├── generate_recommendations()     ←── Recommandations
       │
       ▼
generate_report()            ←── Rapport HTML / PDF
```

---

## Fonctions & Utilisation

### 1. `import_soil_data()`

Importe les données pédologiques depuis l'API SoilGrids ou un fichier local.

```r
library(farmCarbonR)

# Option A : coordonnées GPS
coords <- data.frame(
  parcelle_id = paste0("P", sprintf("%03d", 1:5)),
  lon = c(-5.96, -6.38, -5.23, -6.36, -6.97),
  lat = c(31.08, 32.61, 30.30, 33.36, 33.81)
)
sol <- import_soil_data(source = "soilgrids", coords = coords)

# Option B : shapefile
sol <- import_soil_data(source = "soilgrids", shapefile = "parcelles.shp")
```

**Variables retournées :**

| Colonne | Description | Unité | Source |
|---------|-------------|-------|--------|
| `SOC` | Carbone organique | % | SoilGrids |
| `bulk_density` | Densité apparente | g/cm³ | SoilGrids |
| `clay` | Argile | % | SoilGrids |
| `sand` | Sable | % | SoilGrids |
| `silt` | Limon | % | SoilGrids |
| `rock_fragment` | Fragments grossiers | fraction | SoilGrids |
| `depth` | Profondeur | cm | SoilGrids |

**Visualisation — Composition texturale :**

```r
library(ggplot2)
library(tidyr)

texture_long <- pivot_longer(
  sol$dataframe[, c("parcelle_id","clay","sand","silt")],
  cols = c(clay, sand, silt),
  names_to = "fraction", values_to = "pct"
)

ggplot(texture_long, aes(x = parcelle_id, y = pct, fill = fraction)) +
  geom_col(position = "stack") +
  scale_fill_manual(
    values = c(clay = "#a6611a", sand = "#dfc27d", silt = "#80cdc1"),
    labels = c("Argile","Sable","Limon")
  ) +
  labs(title = "Composition texturale des sols",
       x = "Parcelle", y = "Fraction (%)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

---

### 2. `import_agricultural_practices()`

Importe et joint les pratiques agricoles au jeu de données sol (CSV ou Excel).

```r
path_pratiques <- system.file("extdata", "exemple_pratiques.csv",
                               package = "farmCarbonR")

pratiques <- import_agricultural_practices(
  path      = path_pratiques,
  format    = "csv",
  join_data = sol$dataframe,
  join_by   = "parcelle_id"
)
```

**Format CSV attendu :**

| parcelle_id | travail_sol | couvert_vegetal | irrigation | fertilisation_organique | rotation |
|-------------|-------------|-----------------|------------|------------------------|----------|
| P001 | semis_direct | oui | oui | aucune | triennale |
| P002 | labour | oui | non | fumier | triennale |
| P003 | semis_direct | non | non | compost | biennale |

**Visualisation — Travail du sol et couvert végétal :**

```r
ggplot(pratiques, aes(x = travail_sol, fill = couvert_vegetal)) +
  geom_bar(position = "dodge") +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Travail du sol et couvert végétal",
       x = "Travail du sol", y = "N parcelles",
       fill = "Couvert") +
  theme_minimal()
```

---

### 3. `calculate_soc_stock()`

Calcule le stock de carbone organique (tC/ha) selon la formule standard.

**Formule :**
```
SOC_stock (tC/ha) = SOC × BulkDensity × Depth × (1 - RockFragment) / 10
```

```r
sol_stock <- calculate_soc_stock(pratiques)
```

**Visualisation — Distribution du stock SOC :**

```r
ggplot(sol_stock, aes(x = SOC_stock_tCha)) +
  geom_histogram(bins = 10, fill = "#1a9850", color = "white", alpha = 0.8) +
  geom_vline(xintercept = mean(sol_stock$SOC_stock_tCha, na.rm = TRUE),
             color = "#d73027", linetype = "dashed", size = 1) +
  labs(title = "Distribution du stock SOC",
       x = "SOC stock (tC/ha)", y = "Nombre de parcelles") +
  theme_minimal()
```

---

### 4. `load_environmental_covariates()`

Télécharge les covariables environnementales depuis MODIS, WorldClim et SRTM.

```r
covars <- load_environmental_covariates(
  coords     = coords,
  start_date = "2023-01-01",
  end_date   = "2023-12-31"
)
```

**Variables retournées :**

| Variable | Package | Source | Unité |
|----------|---------|--------|-------|
| `ndvi` | `MODISTools` | MODIS MOD13A3 | indice 0–1 |
| `temp` | `geodata` | WorldClim tavg | °C |
| `precip` | `geodata` | WorldClim prec | mm/mois |
| `alt` | `geodata` | SRTM | m |

**Visualisation — NDVI moyen annuel :**

```r
ggplot(covars, aes(x = lon, y = lat, color = ndvi, size = ndvi)) +
  geom_point(alpha = 0.8) +
  scale_color_gradientn(
    colors = c("#d73027","#fee08b","#1a9850"),
    name = "NDVI") +
  labs(title = "NDVI moyen annuel (MODIS)",
       x = "Longitude", y = "Latitude") +
  theme_minimal()
```

---

### 5. `extract_covariates()`

Joint les données sol et les covariables environnementales pour modélisation.

```r
df_model <- extract_covariates(
  soil_data = sol_stock,
  env_data  = covars
)
```

---

### 6. `preprocess_data()`

Prépare les données pour la modélisation : sélection de variables, normalisation, split train/test.

```r
prep <- preprocess_data(
  data          = df_model,
  target        = "SOC_stock_tCha",
  cor_threshold = 0.9,
  train_ratio   = 0.8,
  normalize     = TRUE
)
```

**Méthodes appliquées :**

| Méthode | Description |
|---------|-------------|
| Pearson | Suppression variables corrélées > 0.9 |
| VIF | Suppression variables colinéaires > 10 |
| Min-max | Normalisation 0–1 |
| Split | 80% train / 20% test |

**Objets retournés :** `prep$train`, `prep$test`, `prep$removed_vars`

**Visualisation — Matrice de corrélation :**

```r
library(corrplot)
mat_cor <- cor(prep$train, use = "complete.obs")
corrplot(mat_cor, method = "color", type = "upper",
         tl.cex = 0.8, title = "Matrice de corrélation")
```

---

### 7. `train_rf_model()`

Entraîne un modèle Random Forest pour prédire le stock SOC.

```r
rf <- train_rf_model(
  train_data = prep$train,
  test_data  = prep$test,
  target     = "SOC_stock_tCha",
  ntree      = 500
)
```

**Métriques retournées :**

| Objet | Description |
|-------|-------------|
| `rf$model` | Modèle Random Forest |
| `rf$importance` | Importance des variables |
| `rf$oob_error` | Erreur OOB (RMSE) |
| `rf$rmse_train` | RMSE train |
| `rf$rmse_test` | RMSE test |
| `rf$r2_train` | R² train |
| `rf$r2_test` | R² test |

---

### 8. `predict_soc_map()`

Génère une carte raster (GeoTIFF) du stock SOC prédit sur la zone d'étude.

```r
carte_soc <- predict_soc_map(
  rf_result    = rf,
  raster_stack = covars_raster,
  output_path  = "outputs/soc_map.tif"
)
```

**Visualisation du raster :**

```r
library(terra)
plot(carte_soc, main = "Carte SOC prédite (tC/ha)",
     col = colorRampPalette(c("#d73027","#fee08b","#1a9850"))(100))
```

**Output généré :** `outputs/soc_map.tif`

---

### 9. `estimate_sequestration_potential()`

Estime le potentiel de séquestration selon 3 scénarios de pratiques agricoles améliorées.

```r
sequestration <- estimate_sequestration_potential(
  data              = sol_stock,
  gain_couvert      = 0.3,
  gain_semis_direct = 0.25,
  gain_compost      = 0.4
)
```

**Scénarios calculés :**

| Scénario | Gain (tC/ha) | Condition déclenchante |
|----------|-------------|----------------------|
| Couvert végétal | +0.30 | `couvert_vegetal == "non"` |
| Semis direct | +0.25 | `travail_sol == "labour"` |
| Apport organique | +0.40 | `fertilisation == "aucune"` |

**Colonnes ajoutées :** `gain_couvert_tCha`, `gain_semis_direct_tCha`, `gain_pratiques_tCha`, `gain_total_tCha`, `SOC_potentiel_tCha`

**Visualisation — Gains par scénario :**

```r
library(tidyr)
sc_long <- pivot_longer(
  sequestration[, c("parcelle_id","gain_couvert_tCha",
                    "gain_semis_direct_tCha","gain_pratiques_tCha")],
  cols = -parcelle_id,
  names_to = "scenario", values_to = "gain"
)

ggplot(sc_long, aes(x = scenario, y = gain, fill = scenario)) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Gain potentiel par scénario",
       x = "Scénario", y = "Gain SOC (tC/ha)") +
  theme_minimal() +
  theme(legend.position = "none")
```

---

### 10. `analyze_spatial_variability()`

Analyse la structure spatiale du SOC (variogramme, test de Moran, krigeage optionnel).

```r
spatial <- analyze_spatial_variability(sequestration)
print(spatial$stats)
print(spatial$moran)
```

**Méthodes appliquées :**

| Méthode | Package | Description |
|---------|---------|-------------|
| Variogramme | `base R` | Structure spatiale du SOC |
| Test de Moran | `spdep` | Autocorrélation spatiale |
| Krigeage | `gstat` | Interpolation spatiale (optionnel) |

**Visualisation — Variogramme empirique :**

```r
variogram_df <- spatial$variogram_df

ggplot(variogram_df, aes(x = distance, y = gamma)) +
  geom_point(size = 3, color = "#1a9850") +
  geom_line(color = "#1a9850", alpha = 0.6) +
  labs(title = "Variogramme empirique du SOC",
       x = "Distance", y = "Semi-variance") +
  theme_minimal()
```

---

### 11. `summarize_farms()`

Produit un tableau synthétique des indicateurs clés par parcelle et par exploitation.

```r
resume <- summarize_farms(sequestration)
print(resume$stats)
```

**Exemple de sortie :**

| n_parcelles | SOC_moyen | SOC_min | SOC_max | gain_moyen_tCha | pratique_dominante |
|-------------|-----------|---------|---------|-----------------|-------------------|
| 20 | 58.34 | 9.87 | 118.45 | 0.38 | semis_direct |

---

### 12. `plot_soc_map()`

Génère 3 cartes ggplot2 du SOC actuel, du potentiel et des scénarios agricoles.

```r
plot_soc_map(sequestration, output_path = "outputs/cartes_soc.pdf")
```

**Cartes générées :**

| Carte | Description |
|-------|-------------|
| Carte 1 | Stock SOC actuel — points colorés par intensité |
| Carte 2 | Potentiel de séquestration — gradient bleu |
| Carte 3 | Gain par scénario agricole — boxplots comparatifs |

**Output généré :** `outputs/cartes_soc.pdf`

---

### 13. `plot_feature_importance()`

Visualise l'importance des variables du modèle Random Forest (barplot).

```r
plot_feature_importance(rf, top_n = 10,
                        output_path = "outputs/importance.png")
```

**Output généré :** `outputs/importance.png`

---

### 14. `generate_recommendations()`

Génère automatiquement des recommandations agronomiques par parcelle selon les seuils SOC et les pratiques.

```r
reco <- generate_recommendations(sequestration, seuil_faible = 40)
```

**Règles appliquées :**

| Condition | Recommandation générée |
|-----------|----------------------|
| `SOC < 40 tC/ha` | Augmenter la matière organique |
| `travail_sol == "labour"` | Passer en semis direct |
| `couvert_vegetal == "non"` | Ajouter des couverts végétaux |
| `fertilisation == "aucune"` | Ajouter compost ou fumier |
| `rotation == "monoculture"` | Améliorer la rotation culturale |
| Aucune condition | Maintenir les pratiques actuelles |

---

### 15. `generate_report()`

Génère un rapport complet en HTML ou PDF avec toutes les visualisations et recommandations.

```r
generate_report(
  data          = reco,
  rf_result     = rf,
  output_format = "html",   # ou "pdf"
  output_dir    = "outputs/",
  titre         = "Rapport farmCarbonR"
)
```

**Sections du rapport généré :**

| Section | Contenu | Visualisation |
|---------|---------|---------------|
| Résumé exécutif | Indicateurs clés | Tableau |
| Données sol | SOC, texture, densité | Tableau + histogramme + barres empilées |
| Pratiques agricoles | Travail sol, couverts | Tableaux + barplots + boxplots |
| Carte SOC actuel | Points géolocalisés | Carte points colorés |
| Potentiel séquestration | Gains par scénario | Carte + boxplots + tableau |
| Modèle RF | Métriques de performance | Tableau + barplot importance |
| Recommandations | Par parcelle | Tableau |
| Sources | Références | Tableau |

**Output généré :** `outputs/rapport_farmCarbonR.html` (ou `.pdf`)

---

## Rapport généré

Le rapport final, produit par `generate_report()`, est disponible localement après exécution du package :

📄 **`outputs/rapport_farmCarbonR.html`**

> Ce fichier est généré automatiquement à la fin du workflow R. Ouvrez-le dans votre navigateur pour consulter l'ensemble des résultats : indicateurs clés, cartes SOC, potentiel de séquestration, performance du modèle Random Forest et recommandations par parcelle.

---

## Auteur
Hiba Elguarouani IDSA IAV
Package développé dans le cadre d'un projet scientifique d'évaluation du carbone organique des sols agricoles.
