# farmCarbonR

> Package R pour l'estimation, la modélisation et la cartographie
> du stock de carbone organique des sols agricoles (SOC).

---

## Description

**farmCarbonR** est un outil scientifique complet permettant :

- d'**estimer le stock actuel de carbone** (SOC) à partir de données SoilGrids
- d'**évaluer l'impact des pratiques agricoles** sur le carbone du sol
- d'**identifier les zones prioritaires** pour la séquestration
- de **modéliser le SOC** avec un Random Forest
- de **générer des rapports** HTML/PDF automatiques avec visualisations

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
  "rmarkdown", "knitr", "gridExtra"
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

---

## Workflow complet
coords / shapefile
│
▼
import_soil_data()          ← SoilGrids ISRIC
│
├── import_agricultural_practices()   ← CSV / Excel terrain
│
▼
calculate_soc_stock()       ← SOC × BD × Depth × (1 - RF) / 10
│
├── load_environmental_covariates()   ← MODIS + WorldClim + SRTM
│
▼
extract_covariates()        ← Jointure sol + environnement
│
▼
preprocess_data()           ← Pearson + VIF + normalisation + split
│
▼
train_rf_model()            ← Random Forest
│
├── predict_soc_map()               ← Raster GeoTIFF
│
▼
estimate_sequestration_potential()  ← 3 scénarios
│
├── analyze_spatial_variability()   ← Moran + variogramme
├── summarize_farms()               ← Tableau synthèse
├── plot_soc_map()                  ← 3 cartes
├── plot_feature_importance()       ← Barplot RF
├── generate_recommendations()      ← Recommandations
│
▼
generate_report()           ← Rapport HTML / PDF

---

## Étape 1 — Coordonnées des parcelles

```r
library(farmCarbonR)

# Option A : coordonnées GPS
coords <- data.frame(
  parcelle_id = paste0("P", sprintf("%03d", 1:5)),
  lon = c(-5.96, -6.38, -5.23, -6.36, -6.97),
  lat = c(31.08, 32.61, 30.30, 33.36, 33.81)
)

# Option B : shapefile
sol <- import_soil_data(source = "soilgrids", shapefile = "parcelles.shp")
```

---

## Étape 2 — Import des données sol (SoilGrids)

```r
sol <- import_soil_data(source = "soilgrids", coords = coords)
```

**Output console :**
[1/5] P001 SOC=17.90 BD=1.43
[2/5] P002 SOC=15.10 BD=1.57
[3/5] P003 SOC=3.50  BD=1.44
Import termine : 5 points.

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

**Visualisation texture :**
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
    values = c(clay="#a6611a", sand="#dfc27d", silt="#80cdc1"),
    labels = c("Argile","Sable","Limon")
  ) +
  labs(title = "Composition texturale des sols",
       x = "Parcelle", y = "Fraction (%)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

---

## Étape 3 — Import des pratiques agricoles

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

**Visualisation des pratiques :**
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

## Étape 4 — Calcul du stock de carbone

```r
sol_stock <- calculate_soc_stock(pratiques)
```

**Formule appliquée :**
SOC_stock (tC/ha) = SOC × BulkDensity × Depth × (1 - RockFragment) / 10

**Visualisation de la distribution :**
```r
ggplot(sol_stock, aes(x = SOC_stock_tCha)) +
  geom_histogram(bins = 10, fill = "#1a9850",
                 color = "white", alpha = 0.8) +
  geom_vline(xintercept = mean(sol_stock$SOC_stock_tCha, na.rm = TRUE),
             color = "#d73027", linetype = "dashed", size = 1) +
  labs(title = "Distribution du stock SOC",
       x = "SOC stock (tC/ha)", y = "Nombre de parcelles") +
  theme_minimal()
```

---

## Étape 5 — Covariables environnementales

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
| `ndvi` | `MODISTools` | MODIS MOD13A3 | indice 0-1 |
| `temp` | `geodata` | WorldClim tavg | °C |
| `precip` | `geodata` | WorldClim prec | mm/mois |
| `alt` | `geodata` | SRTM | m |

**Visualisation NDVI :**
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

## Étape 6 — Extraction des covariables

```r
df_model <- extract_covariates(
  soil_data = sol_stock,
  env_data  = covars
)
```

---

## Étape 7 — Prétraitement des données

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
| Min-max | Normalisation 0-1 |
| Split | 80% train / 20% test |

**Output :** `prep$train`, `prep$test`, `prep$removed_vars`

**Visualisation corrélations :**
```r
library(corrplot)
mat_cor <- cor(prep$train, use = "complete.obs")
corrplot(mat_cor, method = "color", type = "upper",
         tl.cex = 0.8, title = "Matrice de corrélation")
```

---

## Étape 8 — Modèle Random Forest

```r
rf <- train_rf_model(
  train_data = prep$train,
  test_data  = prep$test,
  target     = "SOC_stock_tCha",
  ntree      = 500
)
```

**Output console :**
Entrainement RF : 500 arbres, mtry=3...
RF entraine.
OOB RMSE   = 8.43
RMSE Train = 3.21 | R2 Train = 0.98
RMSE Test  = 9.12 | R2 Test  = 0.87

**Objets retournés :**

| Objet | Description |
|-------|-------------|
| `rf$model` | Modèle Random Forest |
| `rf$importance` | Importance des variables |
| `rf$oob_error` | Erreur OOB (RMSE) |
| `rf$rmse_train` | RMSE train |
| `rf$rmse_test` | RMSE test |
| `rf$r2_train` | R² train |
| `rf$r2_test` | R² test |

**Visualisation importance :**
```r
plot_feature_importance(rf, top_n = 10,
                        output_path = "outputs/importance.png")
```

---

## Étape 9 — Prédiction carte SOC

```r
carte_soc <- predict_soc_map(
  rf_result    = rf,
  raster_stack = covars_raster,
  output_path  = "outputs/soc_map.tif"
)
```

**Output :** Raster GeoTIFF exporté

**Visualisation du raster :**
```r
library(terra)
plot(carte_soc, main = "Carte SOC prédite (tC/ha)",
     col = colorRampPalette(c("#d73027","#fee08b","#1a9850"))(100))
```

---

## Étape 10 — Potentiel de séquestration

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
|----------|-------------|------------------------|
| Couvert végétal | +0.30 | couvert_vegetal == "non" |
| Semis direct | +0.25 | travail_sol == "labour" |
| Apport organique | +0.40 | fertilisation == "aucune" |

**Colonnes ajoutées :**
`gain_couvert_tCha`, `gain_semis_direct_tCha`,
`gain_pratiques_tCha`, `gain_total_tCha`, `SOC_potentiel_tCha`

**Visualisation scénarios :**
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

## Étape 11 — Analyse spatiale

```r
spatial <- analyze_spatial_variability(sequestration)
print(spatial$stats)
print(spatial$moran)
```

**Output :**
moyenne mediane ecart_type   min    max cv_pct
1   58.34   54.21      22.41  9.87 118.45  38.41
$interpretation
[1] "Autocorrelation spatiale significative"

**Méthodes appliquées :**

| Méthode | Package | Description |
|---------|---------|-------------|
| Variogramme | base R | Structure spatiale du SOC |
| Test de Moran | `spdep` | Autocorrélation spatiale |
| Krigeage | `gstat` | Interpolation spatiale (optionnel) |

**Visualisation variogramme :**
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

## Étape 12 — Résumé des parcelles

```r
resume <- summarize_farms(sequestration)
print(resume$stats)
```

**Output :**
n_parcelles SOC_moyen SOC_min SOC_max gain_moyen_tCha pratique_dominante
1          20     58.34    9.87  118.45            0.38       semis_direct

---

## Étape 13 — Cartes SOC

```r
plot_soc_map(sequestration, output_path = "outputs/cartes_soc.pdf")
```

**Cartes générées :**

| Carte | Description |
|-------|-------------|
| Carte 1 | Stock SOC actuel — points colorés par intensité |
| Carte 2 | Potentiel de séquestration — gradient bleu |
| Carte 3 | Gain par scénario agricole — boxplots comparatifs |

---

## Étape 14 — Recommandations

```r
reco <- generate_recommendations(sequestration, seuil_faible = 40)
```

**Règles appliquées :**

| Condition | Recommandation générée |
|-----------|------------------------|
| SOC < 40 tC/ha | Augmenter matière organique |
| travail_sol == "labour" | Passer en semis direct |
| couvert_vegetal == "non" | Ajouter couverts végétaux |
| fertilisation == "aucune" | Ajouter compost ou fumier |
| rotation == "monoculture" | Améliorer la rotation culturale |
| Aucune condition | Maintenir les pratiques actuelles |

---

## Étape 15 — Rapport final

```r
generate_report(
  data          = reco,
  rf_result     = rf,
  output_format = "html",
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
| Modèle RF | Métriques performance | Tableau + barplot importance |
| Recommandations | Par parcelle | Tableau |
| Sources | Références | Tableau |

---

## Structure du package
farmCarbonR/
├── R/
│   ├── import_soil_data.R            # SoilGrids + CSV + shapefile
│   ├── import_agricultural_practices.R  # CSV + Excel
│   ├── load_environmental_covariates.R  # MODIS + WorldClim + SRTM
│   ├── load_ndvi.R                   # MODIS MOD13A3
│   ├── extract_covariates.R          # Jointure sol + env
│   ├── calculate_soc_stock.R         # Formule SOC
│   ├── preprocess_data.R             # Pearson + VIF + split
│   ├── train_rf_model.R              # Random Forest
│   ├── predict_soc_map.R             # Raster GeoTIFF
│   ├── estimate_sequestration_potential.R  # 3 scénarios
│   ├── analyze_spatial_variability.R # Moran + variogramme
│   ├── summarize_farms.R             # Tableau synthèse
│   ├── plot_soc_map.R                # 3 cartes ggplot2
│   ├── plot_feature_importance.R     # Barplot RF
│   ├── generate_recommendations.R    # Recommandations auto
│   ├── generate_report.R             # Rapport HTML/PDF
│   ├── set_study_area.R              # Zone d étude
│   └── farmCarbonR-package.R
├── inst/extdata/
│   ├── exemple_sol.csv
│   └── exemple_pratiques.csv
├── man/
├── DESCRIPTION
├── NAMESPACE
└── README.md

---

## Auteur

Package développé dans le cadre d'un projet scientifique
d'évaluation du carbone agricole des sols agricoles.
