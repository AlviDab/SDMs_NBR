###### Script to create Figure 1 (trends at the head of the figure) and Figure 3 ######

pacman::p_load(
  europepmc, tidyverse,
  ggplot2, parallel, tm,
  wordcloud, wordcloud2, # ggstream,
  patchwork, gridExtra
)

date_data <- Sys.Date()

# Select time interval for the analysis
start_year <- 1980
end_year <- 2026

# Check what of those packages are not installed
packages <- c(
  "europepmc", "tidyverse", "ggplot2", "parallel",
  "tm", "wordcloud", "wordcloud2", # "ggstream",
  "patchwork", "gridExtra"
)
not_installed <- packages[!(packages %in% installed.packages()[, "Package"])]

print(paste(
  "The following packages are not installed:",
  paste(not_installed, collapse = ", ")
))

search_names <- c(
  "Terrestrial", "Marine", "Intertidal", "Freshwater",
  "Niche", "ML", "DL", "Stats", "Process", "Hybrid"
)

results <- readRDS(paste0("Figures/data/all_niche_realms_", date_data, ".RDS"))
results_sdm <- readRDS(paste0("Figures/data/all_niche_realms_sdm_methods_", date_data, ".RDS"))

# Filter years to the range of interest
results <- lapply(results, function(x) {
  x[x$year >= start_year & x$year <= end_year, ]
})
results_sdm <- lapply(results_sdm, function(x) {
  x[x$year >= start_year & x$year <= end_year, ]
})

names(results) <- c("Terrestrial", "Marine", "Intertidal", "Freshwater")
names(results_sdm) <- c("ZERO", search_names)

# Calculating proportion of paper in a year that are about SDMs for each habitat type
data_sdm_realms_prop_year <-
  data.frame(
    Year = results$Terrestrial$year,
    Terrestrial = results_sdm$Terrestrial$query_hits / results_sdm$Terrestrial$all_hits,
    Marine = results_sdm$Marine$query_hits / results_sdm$Marine$all_hits,
    Intertidal = results_sdm$Intertidal$query_hits / results_sdm$Intertidal$all_hits,
    Freshwater = results_sdm$Freshwater$query_hits / results_sdm$Freshwater$all_hits
  )

data_sdm_realms_tot <-
  data.frame(
    Year = results$Terrestrial$year,
    Terrestrial = results_sdm$Terrestrial$query_hits,
    Marine = results_sdm$Marine$query_hits,
    Intertidal = results_sdm$Intertidal$query_hits,
    Freshwater = results_sdm$Freshwater$query_hits
  )

# Calculating tot paper in a year that are about SDMs for each SDMs method
data_sdm_methods_tot_year <-
  data.frame(
    Year = results_sdm$Terrestrial$year,
    Niche = results_sdm$Niche$query_hits,
    ML = results_sdm$ML$query_hits,
    DL = results_sdm$DL$query_hits,
    Stats = results_sdm$Stats$query_hits,
    Process = results_sdm$Process$query_hits,
    Hybrid = results_sdm$Hybrid$query_hits
  )

# Calculation of the proportion of total paper in a year that are about SDMs for each SDMs method

data_sdm_methods_prop_year <-
  data.frame(
    Year = results_sdm$Terrestrial$year,
    Niche = results_sdm$Niche$query_hits / results_sdm$Terrestrial$all_hits,
    ML = results_sdm$ML$query_hits / results_sdm$Terrestrial$all_hits,
    DL = results_sdm$DL$query_hits / results_sdm$Terrestrial$all_hits,
    Stats = results_sdm$Stats$query_hits / results_sdm$Terrestrial$all_hits,
    Process = results_sdm$Process$query_hits / results_sdm$Terrestrial$all_hits,
    Hybrid = results_sdm$Hybrid$query_hits / results_sdm$Terrestrial$all_hits
  )

#### Figure 1 ####

plots_theme <- theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(colour = "black"),
    legend.position = c(0.8, 0.7),
    legend.title = element_blank(),
    axis.text = element_text(size = 13),
    axis.title = element_text(size = 13),
    legend.text = element_text(size = 13)
  )

# Prepare the data
data_sdm_realms_prop_year <- data_sdm_realms_prop_year %>%
  pivot_longer(cols = c("Terrestrial", "Marine", "Intertidal", "Freshwater"), names_to = "Habitat", values_to = "Proportion")

# Set the colours for the habitats
habitat_cols <- c(
  "Terrestrial" = "#e07a5f",
  "Marine" = "#3d405b",
  "Intertidal" = "#f4f1de",
  "Freshwater" = "#81b29a"
)

# Aggregate the wide habitat counts before they are reshaped below.
data_sdm_realms_tot_year <- data_sdm_realms_tot %>%
  pivot_longer(
    cols = c("Terrestrial", "Marine", "Intertidal", "Freshwater"),
    names_to = "Habitat",
    values_to = "Count"
  ) %>%
  group_by(Year) %>%
  summarise(Count = sum(Count), .groups = "drop")

# Calculate the max count to use for axis scaling
max_count <- max(data_sdm_realms_tot_year$Count)

# Calculate the max proportion
max_prop <- data_sdm_realms_prop_year %>%
  group_by(Year) %>%
  summarise(Proportion = sum(Proportion), .groups = "drop") %>%
  pull(Proportion) %>%
  max()

# Create the plot
plot_sdm_prop_year <- ggplot(data_sdm_realms_prop_year, aes(x = Year)) +
  geom_col(aes(y = Proportion, fill = Habitat),
    colour = "black", stat = "identity", width = 0.7, linewidth = 0.2
  ) +
  scale_fill_manual(values = habitat_cols, name = "Habitat type") +
  geom_line(
    data = data_sdm_realms_tot_year %>%
      mutate(Proportion = Count / max_count * max_prop),
    aes(y = Proportion, colour = "Total count"),
    size = 1,
    alpha = 0.5
  ) +
  geom_point(
    data = data_sdm_realms_tot_year %>%
      mutate(Proportion = Count / max_count * max_prop),
    aes(y = Proportion, colour = "Total count"),
    size = 1,
    alpha = 0.6
  ) +
  scale_colour_manual(values = c("Total count" = "black"), name = "") +
  scale_y_continuous(
    name = "Proportion of SDM/niche publications",
    sec.axis = sec_axis(
      trans = function(x) x * max_count / max_prop,
      name = "Total publications (count)"
    )
  ) +
  labs(
    x = "Year"
  ) +
  theme_bw() +
  theme(
    axis.title.y = element_text(color = "black", size = 13),
    axis.title.y.right = element_text(color = "#d7191c", size = 13),
    axis.text.y.right = element_text(color = "#d7191c"),
    legend.position = "bottom",
    legend.box = "horizontal",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  plots_theme +
  theme(legend.position = c(0.1, 0.7))
# geom_smooth(aes(y = Terrestrial, color = "Terrestrial"), method = "loess", span = 0.35, se = FALSE, size = 1.5) +
# geom_smooth(aes(y = Marine, color = "Marine"), method = "loess", span = 0.35, se = FALSE, size = 1.5) +
# geom_smooth(aes(y = Intertidal, color = "Intertidal"), method = "loess", span = 0.35, se = FALSE, size = 1.5) +
# geom_smooth(aes(y = Freshwater, color = "Freshwater"), method = "loess", span = 0.35, se = FALSE, size = 1.5) +
# scale_color_manual(values = cols) +
# labs(x = "Year", y = "Proportion of SDM publications in the year") +
# plots_theme

# Save the ggplot version
ggsave(paste0("Figures/Fig_1_prop_year_sdms_or_niche_biodiversity_", date_data, ".pdf"), plot = plot_sdm_prop_year, width = 10, height = 4)
ggsave(paste0("Figures/Fig_1_prop_year_sdms_or_niche_biodiversity_", date_data, ".png"), plot = plot_sdm_prop_year, width = 10, height = 4, dpi = 300)

# Plot the same with splines
plot_sdm_prop_year_splines <- ggplot(data_sdm_realms_prop_year, aes(x = Year)) +
  geom_smooth(aes(y = Proportion, color = Habitat), se = FALSE, size = 1.5) +
  scale_color_manual(values = habitat_cols) +
  labs(x = "Year", y = "Proportion of SDM or niche publications in the year") +
  plots_theme

# Save the ggplot version
ggsave(paste0("Figures/Fig_1_prop_year_sdms_or_niche_biodiversity_splines_", date_data, ".pdf"), plot = plot_sdm_prop_year_splines, width = 10, height = 4)
ggsave(paste0("Figures/Fig_1_prop_year_sdms_or_niche_biodiversity_splines_", date_data, ".png"), plot = plot_sdm_prop_year_splines, width = 10, height = 4, dpi = 300)

# Prepare the data
data_sdm_realms_tot <- data_sdm_realms_tot %>%
  pivot_longer(cols = c("Terrestrial", "Marine", "Intertidal", "Freshwater"), names_to = "Habitat", values_to = "Count")

# Plot it with ggplot not log-transformed
plot_sdm_realms_tot <- ggplot(data_sdm_realms_tot, aes(x = Year)) +
  # Add cumulative colourbars
  geom_bar(aes(y = Count, fill = Habitat), colour = "black", stat = "identity", width = 1, linewidth = 0.2) +
  scale_fill_manual(values = habitat_cols) +
  labs(x = "Year", y = "Number of SDM or niche publications") +
  plots_theme
# geom_smooth(aes(y = Terrestrial, color = "Terrestrial"), method = "loess", span = 0.35, se = FALSE, size = 0.5) +
# geom_smooth(aes(y = Marine, color = "Marine"), method = "loess", span = 0.35, se = FALSE, size = 0.5) +
# geom_smooth(aes(y = Intertidal, color = "Intertidal"), method = "loess", span = 0.35, se = FALSE, size = 0.5) +
# geom_smooth(aes(y = Freshwater, color = "Freshwater"), method = "loess", span = 0.35, se = FALSE, size = 0.5) +
# scale_color_manual(values = cols) +
# labs(x = "Year", y = "log10(Number of SDM publications in the year)") +
# plots_theme

# Save the ggplot version
ggsave(paste0("Figures/Fig_1_prop_tot_sdms_or_niche_biodiversity_", date_data, ".pdf"), plot = plot_sdm_realms_tot, width = 10, height = 5)
ggsave(paste0("Figures/Fig_1_prop_tot_sdms_or_niche_biodiversity_", date_data, ".png"), plot = plot_sdm_realms_tot, width = 10, height = 5, dpi = 300)

#### Figure 2 ####

method_order <- c("Niche", "ML", "DL", "Stats", "Hybrid", "Process")

plot_data_sdm_methods_tot_year <- data_sdm_methods_tot_year %>%
  pivot_longer(cols = method_order, names_to = "Method", values_to = "Count") %>%
  mutate(Method = factor(Method, levels = method_order))

# Method colours: blue shades for correlative methods, purple for hybrid,
# and orange for process-explicit.
method_cols <- c(
  "Niche" = "#caf0f8",
  "ML" = "#8ecae6",
  "DL" = "#219ebc",
  "Stats" = "#023047",
  "Hybrid" = "#ffd166",
  "Process" = "#fb8500"
)

# Make a vocabulary of the methods
method_vocab <- c(
  "Niche" = "Correlative - Niche/Envelope",
  "ML" = "Correlative - Machine Learning",
  "DL" = "Correlative - Deep Learning",
  "Stats" = "Correlative - Statistical",
  "Hybrid" = "Hybrid",
  "Process" = "Process-Explicit"
)

plot_sdm_methods_tot_year <- plot_data_sdm_methods_tot_year %>%
  mutate(Method = factor(Method, levels = method_order))

plot_sdm_methods_tot_year <- ggplot(plot_data_sdm_methods_tot_year, aes(x = Year)) +
  geom_bar(aes(y = Count, fill = Method),
    colour = "black", stat = "identity",
    width = 0.7, linewidth = 0.2
  ) +
  scale_fill_manual(
    values = method_cols,
    breaks = (method_order),
    name = "Method",
    labels = unname(method_vocab[(method_order)])
  ) +
  labs(x = "Year", y = "Number of SDM publications") +
  plots_theme +
  theme(legend.position = c(0.2, 0.7))

# Save the ggplot version
ggsave(paste0("Figures/Fig_2_tot_sdms_methods_", date_data, ".pdf"), plot = plot_sdm_methods_tot_year, width = 10, height = 5)
ggsave(paste0("Figures/Fig_2_tot_sdms_methods_", date_data, ".png"), plot = plot_sdm_methods_tot_year, width = 10, height = 5, dpi = 300)

plot_sdm_methods_prop_year <- data_sdm_methods_prop_year %>%
  pivot_longer(cols = method_order, names_to = "Method", values_to = "Proportion") %>%
  mutate(Method = factor(Method, levels = method_order))

plot_sdm_methods_prop_year <- ggplot(plot_sdm_methods_prop_year, aes(x = Year)) +
  geom_bar(aes(y = Proportion, fill = Method), colour = "black", stat = "identity", width = 0.7, linewidth = 0.2) +
  scale_fill_manual(
    values = method_cols,
    breaks = method_order,
    name = "Method",
    labels = unname(method_vocab[method_order])
  ) +
  labs(x = "Year", y = "Proportion of SDM publications") +
  plots_theme +
  theme(legend.position = c(0.2, 0.75))

# Save the ggplot version
ggsave(paste0("Figures/Fig_2_prop_sdms_methods_", date_data, ".pdf"), plot = plot_sdm_methods_prop_year, width = 10, height = 5)
ggsave(paste0("Figures/Fig_2_prop_sdms_methods_", date_data, ".png"), plot = plot_sdm_methods_prop_year, width = 10, height = 5, dpi = 300)
