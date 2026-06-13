# farmCarbonR <img src="https://img.shields.io/badge/version-1.0.0-blue.svg" align="right"/> <img src="https://img.shields.io/badge/R-%3E%3D4.0.0-brightgreen.svg" align="right"/>

> **Estimation et cartographie des stocks de carbone organique du sol (SOC) pour le contexte agricole marocain**  
> Intègre SoilGrids (ISRIC), WorldClim v2, NDVI MODIS et Random Forest pour la prédiction spatiale.

---

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [📊 Résultats & Visualisations](#-résultats--visualisations)
- [Installation](#installation)
- [Structure du projet](#structure-du-projet)
- [Flux de travail](#flux-de-travail)
- [Fonctions principales](#fonctions-principales)
- [Sources de données](#sources-de-données)
- [Paramètres spécifiques au Maroc](#paramètres-spécifiques-au-maroc)
- [Packages requis](#packages-requis)
- [Tests](#tests)
- [Historique des modifications](#historique-des-modifications)
- [Limitations connues](#limitations-connues)
- [Licence](#licence)

---

## Vue d'ensemble

`farmCarbonR` est un package R conçu pour estimer, cartographier et analyser les stocks de carbone organique du sol (SOC) à l'échelle des exploitations agricoles marocaines. Il combine :

- Des **données terrain** (mesures SOC, pratiques agricoles)
- Des **données de télédétection** (NDVI MODIS, altitude SRTM)
- Des **données climatiques** (WorldClim v2 : température, précipitations)
- Des **données pédologiques** (SoilGrids ISRIC : SOC, densité apparente, texture)
- Un **modèle prédictif Random Forest** pour la cartographie spatiale

---

## 📊 Résultats & Visualisations

### 🗺️ Cartographie des stocks de carbone organique du sol (SOC)

**Carte prédictive du SOC générée par le modèle Random Forest pour le Maroc**

![Carte SOC - farmCarbonR](img/plot_soc_map.png)

**Description:**
- Résolution spatiale : 20 km
- Plage de valeurs : 30 à 70 tC/ha
- Gradient nord-sud : plus de carbone dans le Nord marocain
- Identifie les **hotspots** (zones riches en carbone) et **coldspots** (zones à faible SOC)

**Interprétation:**
- 🟢 **Vert foncé** : SOC élevé (60-70 tC/ha) — pratiques agricoles optimales
- 🟡 **Jaune** : SOC moyen (45-55 tC/ha) — besoin d'amélioration modérée
- 🟫 **Marron** : SOC faible (30-40 tC/ha) — priorité de restauration

---

### 📈 Importance des variables du modèle Random Forest

**Contribution relative de chaque variable à la prédiction du SOC**

![Feature Importance - Random Forest](img/plot_feature_importance.png)

**Classement des variables:**

| Rang | Variable | Importance | Interprétation |
|------|----------|-----------|-----------------|
| 1️⃣ | Température moyenne | 28.5% | Le climat est le facteur dominant |
| 2️⃣ | Précipitations annuelles | 22.3% | L'eau affecte la minéralisation du SOC |
| 3️⃣ | NDVI MODIS | 19.8% | La productivité végétale influe sur les apports |
| 4️⃣ | Altitude | 16.2% | La topographie module température et humidité |
| 5️⃣ | Densité apparente | 13.2% | La texture du sol affecte le stockage |

> ✨ **Point clé** : La température et les précipitations à elles seules expliquent >50% de la variabilité du SOC au Maroc.

---

### 📄 Rapport complet & Détails techniques

**[📥 Télécharger le rapport HTML complet](./outputs/rapport_SOC_Maroc.html)**

Le rapport incluut :
- ✅ Statistiques descriptives des données d'entrée
- ✅ Résultats détaillés du modèle Random Forest (OOB, R², RMSE)
- ✅ Cartographie interactive du SOC
- ✅ Analyse de l'autocorrélation spatiale (indice de Moran)
- ✅ Potentiel de séquestration carbone par exploitation
- ✅ Recommandations agronomiques personnalisées par parcelle

---

## Installation

```r
# Depuis GitHub
# install.packages("devtools")
devtools::install_github("votre-username/farmCarbonR")

# Ou en local
devtools::install(".")
```

### Dépendances obligatoires

```r
install.packages(c(
  "terra", "sf", "geodata", "randomForest",
  "dplyr", "ggplot2", "httr", "jsonlite",
  "rmarkdown", "spdep"
))
```

### Dépendances optionnelles

```r
install.packages(c("MODISTools", "testthat", "knitr"))
```

---

## Structure du projet

```
farmCarbonR/
├── R/                              # Fonctions du package
│   ├── import_soil_data.R          # Import données sol terrain
│   ├── import_agricultural_practices.R  # Import pratiques agricoles
│   ├── load_soilgrids.R            # API SoilGrids ISRIC
│   ├── load_worldclim.R            # WorldClim v2 (température, précip)
│   ├── load_ndvi.R                 # NDVI MODIS (MOD13A3)
│   ├── load_environmental_covariates.R  # Covariables environnementales
│   ├── set_study_area.R            # Définition zone d'étude
│   ├── calculate_soc_stock.R       # Calcul stock SOC
│   ├── preprocess_data.R           # Prétraitement (corrélation, VIF, normalisation)
│   ├── extract_covariates.R        # Extraction covariables spatiales
│   ├── train_rf_model.R            # Entraînement Random Forest
│   ├── predict_soc_map.R           # Cartographie prédictive SOC
│   ├── analyze_spatial_variability.R    # Variabilité spatiale (Moran)
│   ├── estimate_sequestration_potential.R  # Potentiel séquestration carbone
│   ├── generate_recommendations.R  # Recommandations agronomiques
│   ├── summarize_farms.R           # Résumé par exploitation
│   ├── plot_soc_map.R              # Visualisation carte SOC
│   ├── plot_feature_importance.R   # Visualisation importance variables RF
│   ├── generate_report.R           # Rapport HTML automatique
│   └── save_outputs.R              # Sauvegarde des résultats
│
├── data/                           # Données intégrées
│   ├── sample_soil_data.rda        # Données sol exemple
│   ├── sample_farm_practices.rda   # Pratiques agricoles exemple
│   └── soc_stock.csv               # Stocks SOC calculés
│
├── inst/extdata/                   # Données externes
│   ├── exemple_sol.csv             # Template données sol
│   ├── exemple_pratiques.csv       # Template pratiques agricoles
│   ├── worldclim_MA.tif            # Raster climatique Maroc
│   ├── ndvi_MA.tif                 # Raster NDVI Maroc
│   ├── altitude.tif                # MNT altitude
│   ├── temperature.tif             # Raster température
│   ├── precipitation.tif           # Raster précipitations
│   └── env_stack.tif               # Stack covariables environnementales
│
├── data-raw/                       # Scripts de préparation des données
│   ├── prepare_data.R              # Téléchargement données réelles (SoilGrids, WorldClim, SRTM)
│   └── sample_soil_data.R          # Génération données exemple
│
├── tests/testthat/                 # Tests unitaires
│   ├── test-calculate_soc_stock.R
│   ├── test-import_soil_data.R
│   ├── test-preprocess_data.R
│   └── test_farmCarbonR.R
│
├── outputs/                        # Résultats générés
│   ├── rf_model.rds                # Modèle RF sauvegardé
│   ├── soil_data.csv / .rds        # Données sol traitées
│   ├── rapport_SOC_Maroc.html      # Rapport complet ⭐
│   └── farm_practices.csv / .rds   # Pratiques agricoles traitées
│
├── img/                            # Visualisations
│   ├── plot_soc_map.png            # Carte SOC prédictive
│   └── plot_feature_importance.png # Importance variables RF
│
├── vignettes/
│   └── introduction.Rmd            # Guide d'utilisation
└── DESCRIPTION
```

---

## Flux de travail

```
[1] Import données          import_soil_data()
    sol + pratiques    →    import_agricultural_practices()
         ↓
[2] Données externes        load_soilgrids()
    SoilGrids / WorldClim → load_worldclim()
    NDVI / altitude    →    load_ndvi()
                            load_environmental_covariates()
         ↓
[3] Calcul SOC stock   →    calculate_soc_stock()
         ↓
[4] Prétraitement      →    preprocess_data()
    (corrélation, VIF,      extract_covariates()
     normalisation)
         ↓
[5] Modélisation RF    →    train_rf_model()
         ↓
[6] Cartographie       →    predict_soc_map()
                            plot_soc_map()          ⭐
                            plot_feature_importance() ⭐
         ↓
[7] Analyse & Résultats →   analyze_spatial_variability()
                            estimate_sequestration_potential()
                            generate_recommendations()
                            summarize_farms()
         ↓
[8] Export             →    generate_report()      ⭐
                            save_outputs()
```

---

## Fonctions principales

### 1. `import_soil_data()`

Importe et valide les données sol terrain.

```r
sol <- import_soil_data("inst/extdata/exemple_sol.csv")
```

**Colonnes attendues :** `parcelle_id`, `lon`, `lat`, `SOC_mean`, `BD_mean`

**Output :**
```
parcelle_id   lon     lat   SOC_mean  BD_mean
P001         -5.12   32.45   12.3      1.32
P002         -5.08   32.51   15.7      1.28
...
```

---

### 2. `import_agricultural_practices()`

Importe les pratiques agricoles par parcelle.

```r
pratiques <- import_agricultural_practices("inst/extdata/exemple_pratiques.csv")
```

**Colonnes attendues :** `parcelle_id`, `travail_sol`, `couvert_vegetal`, `fertilisation_organique`, `rotation`

---

### 3. `load_soilgrids()`

Télécharge SOC, densité apparente et texture depuis l'API SoilGrids ISRIC.

```r
sg <- load_soilgrids(lon = -5.0, lat = 32.0, depth = "0-30cm")
```

**Output :**
```
  lon   lat   depth  SOC_gkg  BD_gcm3  clay_pct  silt_pct  sand_pct
 -5.0  32.0  0-30cm    12.0     1.30      25.0      30.0      45.0
```

> ⚠️ **Spécifique Maroc** : En cas de timeout de l'API SoilGrids, des valeurs de repli calibrées sur les sols marocains sont automatiquement utilisées :
> `SOC = 12.0 g/kg`, `BD = 1.30 g/cm³`, `argile = 25%`, `limon = 30%`, `sable = 45%`
> Ces valeurs correspondent aux moyennes des sols agricoles du Maroc central.

---

### 4. `load_worldclim()`

Télécharge température et précipitations depuis WorldClim v2 pour le Maroc.

```r
wc <- load_worldclim(country = "MA", output_dir = "data")
```

**Output :** `SpatRaster` avec 2 couches :

| Couche | Description | Unité |
|--------|-------------|-------|
| `temp_mean_C` | Température moyenne annuelle | °C |
| `prec_annual_mm` | Précipitations annuelles | mm |

> ℹ️ **Résolution** : 2.5 arcmin (~5 km). Le raster est sauvegardé sous `data/worldclim_MA.tif`.

---

### 5. `load_ndvi()`

Télécharge le NDVI depuis MODIS (produit MOD13A3) via MODISTools.

```r
ndvi <- load_ndvi(
  coords     = sol[, c("parcelle_id", "lon", "lat")],
  start_date = "2023-01-01",
  end_date   = "2023-12-31"
)
```

**Output :**
```
parcelle_id   lon     lat    ndvi
P001         -5.12   32.45  0.3412
P002         -5.08   32.51  0.2987
...
```

> ⚠️ **Spécifique Maroc** : En cas d'indisponibilité MODIS, la valeur de repli est `NDVI = 0.35`, correspondant à la moyenne NDVI des zones agricoles marocaines semi-arides.

---

### 6. `load_environmental_covariates()`

Télécharge toutes les covariables environnementales en une seule étape (NDVI, température, précipitations, altitude).

```r
covars <- load_environmental_covariates(
  coords     = sol[, c("parcelle_id", "lon", "lat")],
  start_date = "2023-01-01",
  end_date   = "2023-12-31"
)
```

**Output :**
```
lon      lat    ndvi    temp   precip   alt
-5.12   32.45  0.3412  17.23   342.1   412.5
-5.08   32.51  0.2987  16.89   358.7   398.2
...
```

> ⚠️ **Spécifique Maroc** : Le pays est fixé à `"MA"` pour WorldClim et SRTM. Les valeurs de repli NDVI (`0.35`) et SoilGrids sont calibrées pour le Maroc.

---

### 7. `calculate_soc_stock()`

Calcule le stock de carbone organique du sol en tC/ha.

**Formule :**
```
SOC_stock (tC/ha) = SOC_mean (g/kg) × BD_mean (g/cm³) × depth (cm) / 10
```

```r
sol <- calculate_soc_stock(sol, depth = 30, output_dir = "data")
```

**Output :**
```
parcelle_id  SOC_mean  BD_mean  SOC_stock_tCha
P001           12.3     1.32        48.71
P002           15.7     1.28        60.29
...
# SOC stock moyen : 54.50 tC/ha
```

> Le résultat est automatiquement exporté dans `data/soc_stock.csv`.

---

### 8. `preprocess_data()`

Prétraitement complet des données pour la modélisation :
- Suppression des variables corrélées (Pearson > 0.85)
- Calcul et filtrage VIF (> 10)
- Normalisation z-score
- Split train/test (80/20)

```r
processed <- preprocess_data(
  data          = data_complete,
  target        = "SOC_stock_tCha",
  cor_threshold = 0.85,
  vif_threshold = 10,
  train_ratio   = 0.8,
  seed          = 42
)
```

**Output :**
```
$train         # data.frame — 80% des données normalisées
$test          # data.frame — 20% des données normalisées
$features_kept # character — variables conservées
$removed_vars  # character — variables retirées (corrélation ou VIF)

# Variables retirées (corrélation > 0.85) : prec_annual_mm
# Prétraitement terminé : 5 variables conservées
# Train : 80 lignes | Test : 20 lignes
```

---

### 9. `train_rf_model()`

Entraîne un modèle Random Forest avec métriques complètes.

```r
rf <- train_rf_model(
  train_data = processed$train,
  test_data  = processed$test,
  target     = "SOC_stock_tCha",
  ntree      = 500,
  mtry       = NULL,   # auto : floor(p/3)
  seed       = 42
)
```

**Output :**
```
$model        # Objet randomForest
$importance   # data.frame — importance des variables (%IncMSE)
$oob_error    # OOB RMSE
$rmse_train   # RMSE sur train
$r2_train     # R² sur train
$rmse_test    # RMSE sur test
$r2_test      # R² sur test
$predicteurs  # Variables utilisées

# RF entraîné.
#   OOB RMSE   = 4.2156
#   RMSE Train = 2.1034 | R2 Train = 0.9412
#   RMSE Test  = 5.3821 | R2 Test  = 0.8734
```

---

### 10. `predict_soc_map()`

Génère une carte raster prédictive du stock SOC sur toute la zone d'étude.

```r
soc_map <- predict_soc_map(
  rf_model  = rf$model,
  env_stack = covars_raster,
  predicteurs = rf$predicteurs
)
```

**Output :** `SpatRaster` — carte SOC en tC/ha sur la zone d'étude.

---

### 11. `analyze_spatial_variability()`

Analyse la variabilité spatiale du SOC (indice de Moran, krigeage descriptif).

```r
spatial <- analyze_spatial_variability(sol_sf)
```

**Output :**
```
$moran_i      # Indice de Moran global
$moran_pval   # p-value du test
$hotspots     # Parcelles à fort SOC
$coldspots    # Parcelles à faible SOC
```

---

### 12. `estimate_sequestration_potential()`

Estime le gain potentiel en carbone selon 3 scénarios de pratiques agricoles améliorées.

```r
seq_data <- estimate_sequestration_potential(
  data              = sol,
  gain_couvert      = 0.3,   # tC/ha/an — couvert végétal
  gain_semis_direct = 0.25,  # tC/ha/an — semis direct
  gain_compost      = 0.4    # tC/ha/an — apport organique
)
```

| Scénario | Gain (tC/ha/an) | Condition déclenchante |
|----------|-----------------|------------------------|
| Couvert végétal | +0.30 | `couvert_vegetal == "non"` |
| Semis direct | +0.25 | `travail_sol == "labour"` |
| Apport organique | +0.40 | `fertilisation_organique == "aucune"` |

**Output :**
```
# Gain moyen : 0.65 tC/ha | Max : 0.95 tC/ha

gain_couvert_tCha  gain_semis_direct_tCha  gain_pratiques_tCha  gain_total_tCha  SOC_potentiel_tCha
     0.30                  0.25                   0.40               0.95              55.66
     0.00                  0.25                   0.40               0.65              60.94
```

---

### 13. `generate_recommendations()`

Génère des recommandations agronomiques automatiques par parcelle.

```r
reco <- generate_recommendations(sol, seuil_faible = 40)
```

**Règles de recommandation :**

| Condition | Recommandation générée |
|-----------|------------------------|
| `SOC_stock_tCha < 40` | "SOC faible : augmenter matière organique." |
| `travail_sol == "labour"` | "Réduire le labour : passer en semis direct." |
| `couvert_vegetal == "non"` | "Ajouter des couverts végétaux." |
| `fertilisation_organique == "aucune"` | "Ajouter compost ou fumier." |
| `rotation == "monoculture"` | "Améliorer la rotation culturale." |
| Toutes bonnes pratiques | "Maintenir les pratiques actuelles." |

---

### 14. `plot_soc_map()`

Visualise la carte prédictive du SOC.

```r
plot_soc_map(soc_map, title = "Stock SOC - Maroc")
```

**Output :** Carte ggplot2 avec gradient de couleur tC/ha (voir section [Résultats & Visualisations](#-résultats--visualisations)).

---

### 15. `plot_feature_importance()`

Visualise l'importance des variables du modèle Random Forest.

```r
plot_feature_importance(rf$importance)
```

**Output :** Graphique à barres trié par `%IncMSE` (voir section [Résultats & Visualisations](#-résultats--visualisations)).

---

### 16. `generate_report()`

Génère un rapport HTML complet avec toutes les analyses, cartes et statistiques.

```r
generate_report(
  sol_data    = sol,
  rf_results  = rf,
  seq_data    = seq_data,
  output_file = "rapport_SOC_Maroc.html"
)
```

**Packages requis pour le rapport :** `ggplot2`, `knitr`, `dplyr`, `tidyr`, `gridExtra`

**Contenu du rapport :**
- 📊 Statistiques descriptives
- 🗺️ Cartes interactives
- 📈 Graphiques d'importance
- 🌱 Recommandations agronomiques
- 💰 Potentiel de séquestration carbone

---

### 17. `save_outputs()`

Sauvegarde tous les résultats (CSV, RDS, rasters) dans le dossier de sortie.

```r
save_outputs(
  sol_data   = sol,
  rf_model   = rf$model,
  soc_map    = soc_map,
  output_dir = "outputs"
)
```

---

## Sources de données

| Source | Données | Résolution | Accès |
|--------|---------|------------|-------|
| **SoilGrids ISRIC v2** | SOC, BD, texture (argile, limon, sable) | 250 m | API REST `rest.isric.org` |
| **WorldClim v2** | Température, précipitations | 2.5 arcmin (~5 km) | `geodata::worldclim_country()` |
| **MODIS MOD13A3** | NDVI mensuel | 500 m | `MODISTools::mt_subset()` |
| **SRTM** | Altitude (MNT) | 3 arcsecondes (~90 m) | `geodata::elevation_3s()` |

---

## Paramètres spécifiques au Maroc

> ℹ️ Ce package a été **conçu et calibré pour le contexte agricole marocain**. Les paramètres suivants sont des valeurs fixes optimisées pour le Maroc et documentées ici à titre de transparence.

### Valeurs de repli SoilGrids (`load_soilgrids`)

Utilisées automatiquement si l'API ISRIC est inaccessible (timeout) :

| Variable | Valeur de repli | Unité | Justification |
|----------|-----------------|-------|---------------|
| SOC | 12.0 | g/kg | Moyenne sols agricoles Maroc central |
| Densité apparente | 1.30 | g/cm³ | Référence sols cultivés semi-arides |
| Argile | 25.0 | % | Texture typique sols marocains |
| Limon | 30.0 | % | Texture typique sols marocains |
| Sable | 45.0 | % | Texture typique sols marocains |

### NDVI de repli (`load_ndvi`, `load_environmental_covariates`)

```r
ndvi_fallback = 0.35  # Moyenne NDVI zones agricoles semi-arides marocaines
```

### Pays par défaut

```r
country = "MA"  # Code ISO 3166-1 alpha-2 — Maroc
```
Utilisé dans `load_worldclim()` et `load_environmental_covariates()`.

### Période NDVI par défaut

```r
start_date = "2023-01-01"
end_date   = "2023-12-31"
```

### Seuil SOC faible (`generate_recommendations`)

```r
seuil_faible = 40  # tC/ha — seuil typique sols agricoles marocains
```

---

## Packages requis

| Package | Version min | Rôle |
|---------|-------------|------|
| `terra` | ≥ 1.5.0 | Manipulation rasters |
| `sf` | ≥ 1.0.0 | Données spatiales vectorielles |
| `geodata` | ≥ 0.5.0 | Téléchargement WorldClim, SRTM |
| `randomForest` | ≥ 4.7.0 | Modélisation Random Forest |
| `dplyr` | — | Manipulation données |
| `ggplot2` | ≥ 3.4.0 | Visualisations |
| `httr` | ≥ 1.4.0 | Requêtes API SoilGrids |
| `jsonlite` | ≥ 1.8.0 | Parsing JSON (SoilGrids) |
| `spdep` | ≥ 1.2.0 | Analyse spatiale (Moran) |
| `rmarkdown` | ≥ 2.20 | Génération rapport HTML |
| `MODISTools` | optionnel | Téléchargement NDVI MODIS |
| `testthat` | ≥ 3.0.0 | Tests unitaires |
| `knitr` | optionnel | Vignettes et rapport |

---

## Tests

```r
# Lancer tous les tests
devtools::test()

# Ou via testthat
testthat::test_dir("tests/testthat")
```

**Couverture des tests :**

| Fichier de test | Fonctions testées |
|-----------------|-------------------|
| `test-calculate_soc_stock.R` | `calculate_soc_stock()` |
| `test-import_soil_data.R` | `import_soil_data()` |
| `test-preprocess_data.R` | `preprocess_data()` |
| `test_farmCarbonR.R` | Tests d'intégration globaux |

---

## Limitations connues

- **Périmètre géographique** : Calibré exclusivement pour le **Maroc**. Les valeurs de repli et seuils sont spécifiques au contexte agricole marocain semi-aride.
- **Connectivité requise** : Les fonctions `load_*` nécessitent une connexion internet pour accéder aux APIs SoilGrids, WorldClim et MODIS.
- **NDVI 2023** : La période NDVI par défaut est fixée à 2023. Modifier `start_date` / `end_date` pour d'autres années.
- **Rasters volumineux** : Les fichiers `.tif` sont gérés via **Git LFS**. S'assurer que Git LFS est installé avant de cloner le dépôt.
- **MODISTools** : Package optionnel, non listé dans `DESCRIPTION`. À installer manuellement si nécessaire.

---

## Licence

MIT © farmCarbonR — voir [LICENSE](LICENSE.md)
