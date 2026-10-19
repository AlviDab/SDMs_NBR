###### Script to fetch the trend data ######

pacman::p_load(europepmc, tidyverse, ggplot2, parallel, litsearchr)

date_today <- Sys.Date()

sdm_query <- c('("species distribution model*"
  OR "ecological niche model*"
  OR "environmental niche model*"
  OR "habitat suitability model*"
  OR "bioclimatic model*"
  OR "bioclimate envelope model*"
  OR "climate envelope model*")')

combine_queries <- function(first, second) {
  if (length(second) == 1L) {
    second <- rep(second, length(first))
  }
  if (length(first) != length(second)) {
    stop("Query vectors must have equal lengths or second must have length one.")
  }
  ifelse(
    nzchar(first) & nzchar(second),
    paste0("(", first, ") AND (", second, ")"),
    ifelse(nzchar(first), first, second)
  )
}

search_terms <- c(
  # Realms
  '("terrestrial ecosystem*" OR "terrestrial habitat*"
  OR "forest ecosystem*" OR "grassland*"
  OR "savanna*" OR "soil ecosystem*"
  OR "tundra*" OR "taiga*" OR "prairie*"
  OR "desert*" OR "mountain*"
  OR "alpine*" OR "steppe*"
  )',
  '("marine ecosystem*" OR "marine habitat*"
  OR "oceanic ecosystem*" OR "pelagic*"
  OR "benthic*" OR "coral reef*"
  OR "seagrass*" OR "kelp forest*"
  OR "deep-sea" OR "hydrothermal vent*"
  OR "cold seep*" OR "seamount*"
  OR "continental shelf*" OR "continental slope*"
  OR "abyssal plain*" OR "oceanic trench*"
  OR "oceanic ridge*")',
  '("intertidal" OR "littoral zone*"
  OR "tidal zone*" OR "shoreline*"
  OR "estuar*" OR "salt marsh*"
  OR "saltmarsh" OR "rocky shore*"
  OR "mudflat*" OR "mangrove*"
  OR "coastal wetland*" OR "sandy beach*"
  OR "coastal dune*" OR "tidal flat*")',
  '("freshwater ecosystem*" OR "freshwater habitat*"
  OR "lentic*" OR "lotic*" OR "riverine"
  OR "lacustrine" OR "freshwater wetland*"
  OR "riparian" OR "floodplain*"
  OR "freshwater marsh*" OR "freshwater swamp*"
  OR "freshwater bog*" OR "freshwater fen*")',

  # Methodology

  ## Niche/Envelop models
  '("BIOCLIM" OR "bioclimatic model*"
  OR "bioclimate envelope model*" OR "bioclimate envelope"
  OR "climate envelope model*" OR "climate envelope"
  OR "envelope model*" OR "envelope approach*" OR "envelope method*")',

  ## Machine learning
  '("machine learning" OR "machine-learning"
    OR "random forest*" OR "decision tree*"
    OR "boosted regression tree*" OR "boosted regression"
    OR "gradient boost*" OR "gradient boosting"
    OR "XGBoost" OR "LightGBM" OR "CatBoost"
    OR "AdaBoost"
    OR "support vector machine*" OR "support vector classifier*"
    OR "MaxEnt" OR "MaxNet" OR "Maximum Entropy model*"
    OR "k-nearest-neighbor*" OR "k nearest neighbor*"
    OR "ridge regression" OR "lasso regression"
    OR "elastic-net" OR "elastic net"
    OR "naive bayes classifier*"
    OR "multivariate adaptive regression spline*")',

  ## Deep learning models
  '("deep learning" OR "deep-learning"
    OR "deep species distribution model*"
    OR "deep neural network*"
    OR "convolutional neural network*"
    OR "recurrent neural network*"
    OR "graph neural network*")',

  ## Statistical models
  '("generalized linear model*" OR "generalised linear model*" OR "GLM"
    OR "generalized additive model*" OR "generalised additive model*"
    OR "GAM")',

  ## Process-explicit models
  '("mechanistic model*" OR "mechanistic approach*"
    OR "process-explicit model*" OR "process explicit model*"
    OR "process-based model*" OR "process based model*"
    OR "abundance dynamic*" OR "abundance dynamics model*"
    OR "dynamic occupancy model*" OR "occupancy model*"
    OR "patch occupancy model*"
    OR "demographic distribution model*" OR "demographic model*"
    OR "eco-physiological model*" OR "ecophysiological model*"
    OR "individual-based model*" OR "individual based model*"
    OR "agent-based model*" OR "agent based model*"
    OR "dynamic energy budget model*" OR "dynamic energy budget"
    OR "species energy budget model*" OR "species energy budget"
    OR "dynamic global vegetation model*"
    OR "DGVM" OR "dynamic vegetation model*")',

  ## Hybrid models
  '("hybrid model*" OR "hybrid method*"
    OR "coupled model*" OR "linked model*")'
)

# Check for publications that hit more than one search term

search_names <- c(
  "Terrestrial", "Marine", "Intertidal", "Freshwater",
  "Niche", "ML", "DL", "Stats", "Process", "Hybrid"
)

names(search_terms) <- search_names

cl <- makeCluster(14L)

if (TRUE) {
  results <- parLapply(cl, combine_queries(search_terms, ""),
    fun = function(q) {
      europepmc::epmc_hits_trend(
        query = q,
        period = 1920:2026
      )
    }
  )
  saveRDS(results, paste0("Figures/data/all_niche_realms_", date_today, ".RDS"))
}

if (TRUE) {
  results_sdm <- parLapply(cl,
    combine_queries(
      c("", search_terms),
      sdm_query
    ),
    fun = function(q) {
      europepmc::epmc_hits_trend(
        query = q,
        period = 1920:2026
      )
    }
  )
  saveRDS(results_sdm, paste0("Figures/data/all_niche_realms_sdm_methods_", date_today, ".RDS"))
}

on.exit(parallel::stopCluster(cl), add = TRUE)
