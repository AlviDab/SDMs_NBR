# SDMs_NBR

R scripts for analysing how species distribution models (SDMs) and ecological
niche models are represented in the scientific literature. The analysis uses
Europe PMC publication counts to examine trends across habitat realms and
modelling approaches, and produces publication-ready figures.

## What is in this repository?

- [`00_fetch_data_SDMs.R`](./00_fetch_data_SDMs.R) builds Europe PMC queries and
  downloads annual publication-hit trends from 1920 through 2026. It searches
  for:
  - terrestrial, marine, intertidal, and freshwater realms;
  - niche/envelope, machine-learning, deep-learning, statistical,
    process-explicit, and hybrid methods; and
  - the same terms combined with a species-distribution/ecological-niche-model
    query.
- [`01_figures.R`](./01_figures.R) reads the downloaded RDS files, restricts
  the analysis to 1980–2026, calculates publication counts and proportions, and
  creates Figures 1 and 2:
  - SDM/niche-model publication trends by habitat realm;
  - total and smoothed proportions of publications by habitat realm; and
  - total counts and proportions by modelling method.

The committed PNG and PDF files are dated outputs from the analysis. Because
the scripts use `Sys.Date()`, rerunning them creates files with the current date
in their names.

## Requirements

The scripts require R and the following packages:

```r
install.packages(c(
  "pacman", "europepmc", "tidyverse", "ggplot2", "parallel",
  "litsearchr", "tm", "wordcloud", "wordcloud2", "patchwork",
  "gridExtra", "scales"
))
```

`parallel` is included with standard R installations on most platforms. The
scripts use `pacman::p_load()` to load packages at runtime, but installing the
packages explicitly makes setup reproducible.

## Running the analysis

Run the scripts from the repository root:

```r
source("00_fetch_data_SDMs.R")
source("01_figures.R")
```

The data-fetching script creates a 14-worker cluster and makes Europe PMC API
requests. Adjust the `makeCluster(14L)` value if the machine has fewer
available cores or if API request volume needs to be reduced.

The scripts currently expect the following directories to exist:

```text
Figures/
└── data/
```

Create them before running the pipeline if they are not already present:

```r
dir.create("Figures/data", recursive = TRUE, showWarnings = FALSE)
```

The fetch step writes two date-stamped RDS files to `Figures/data/`. The figure
step reads those files and writes date-stamped PNG and PDF figures to
`Figures/`.

To generate the exploratory proxy/predictor graph separately:

```r
source("02_graph.R")
```

This writes `Figures/proxies_vs_causal_predictors.svg`.

## Query interpretation and limitations

The results are publication *hit counts*, not a manually screened systematic
review. A publication can match multiple habitat or method queries, so counts
across categories should not be interpreted as mutually exclusive. Search
results also depend on Europe PMC indexing, query wording, and the date on
which the API is queried.

The method proportions in Figure 2 use the annual number of terrestrial
SDM/niche-model query hits as their denominator. Review the query definitions
in `00_fetch_data_SDMs.R` before comparing results across runs or extending the
analysis.