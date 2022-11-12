library(ggplot2)
library(wesanderson)
library(cowplot)

# save plot pngs?
saveplots <- FALSE
savetodis <- FALSE

# dir paths
data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/fuller"
plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data"
dis_path <- "~/Documents/ASU/Dissertation/Chapters/Document"

# Palettes

# palchev <- wes_palette("Chevalier1")
# palcav <- wes_palette("Cavalcanti1")
palry1 <- wes_palette("Royal1")
# palry2 <- wes_palette("Royal2")
palzissou8 <- wes_palette(name = "Zissou1", n=8, type = "continuous")


######################################
# Plot Weather data
######################################

wdata <- read.csv(file.path(data_path, "fuller_weather.csv"))
wdata$fDate <- as.Date(wdata$fDate)

rains_plot <- ggplot(wdata, aes(x = fDate)) +
  geom_col(aes(y = as.numeric(Rainy)), width = 0.5, color = palry1[1]) +
  geom_col(aes(y = as.numeric(!Rainy)), width = 0.5, color = palry1[3], alpha = 0.8) +
  coord_cartesian(ylim = c(0.25, 0.75)) +
  labs(x = NULL, y = "Rain Events") +
  scale_x_date(labels = NULL, expand = c(0.01,0.01)) +
  scale_y_continuous(breaks = NULL) +
  theme_bw() 
# rains_plot

winds_plot <- ggplot(wdata, aes(x = fDate)) +
  geom_col(aes(y = as.numeric(Windy)), width = 0.5, color = palry1[1]) +
  geom_col(aes(y = as.numeric(!Windy)), width = 0.5, color = palry1[3], alpha = 0.8) +
  coord_cartesian(ylim = c(0.25, 0.75)) +
  labs(x = NULL, y = "Wind Events") +
  scale_x_date(labels = NULL, expand = c(0.01,0.01)) +
  scale_y_continuous(breaks = NULL) +
  theme_bw() 
# winds_plot

temps_plot <- ggplot(wdata, aes(x = fDate, y = MeanTa)) +
  geom_line(size = 0.6, color = palry1[1]) +
  coord_cartesian(ylim = c(16, 28)) +
  scale_x_date(expand = c(0.01,0.01)) +
  xlab("Date") + ylab("Mean Air Temperature (ºC)") +
  theme_bw()
# temps_plot

w_plot <- cowplot::plot_grid(rains_plot, winds_plot, temps_plot, ncol = 1, align = "v", rel_heights = c(1, 1, 2))
w_plot


######################################
# Plot Rust data
######################################


#########
# Areas per age
perdatenage <- read.csv(file.path(data_path, "fuller_perdate_age.csv"))
perdatenage$fdate <- as.Date(perdatenage$fdate)

plot_areas <- function(thevar){
  treatm <- enquo(thevar)
  filter(perdatenage, !is.na(!!treatm)) %>%
    ggplot(aes(x = fdate,
               y = !!treatm,
               color = as.factor(age))) +
    geom_line(aes(group = as.factor(firstfound))) +
    geom_point(size = 0.5) +
    coord_cartesian(ylim = c(0, 0.6)) +
    scale_y_continuous(expand = c(0.01,0.01)) +
    # labs(x = "Date", y = "Median Lesion Area", color = "Lesion Age\n(weeks)") +
    scale_color_manual(values = palzissou8) +
    theme_bw()
}

sun_latent_p <- plot_areas(area_med_sun) +
  labs(x = NULL, y = "Median Total Lesion Area") +
  scale_x_date(labels = NULL) +
  theme(plot.margin = margin(8, 2, 10, 10))
# sun_latent_p

shade_latent_p <- plot_areas(area_med_sh) +
  labs(x = NULL, y = NULL) +
  scale_y_continuous(labels = NULL, expand = c(0.01,0.01)) +
  scale_x_date(labels = NULL) +
  theme(plot.margin = margin(8, 4, 10, 24))
# shade_latent_p

sun_spore_p <- plot_areas(spore_med_sun) +
  labs(x = "Date", y = "Median Sporulated Area") +
  theme(plot.margin = margin(6, 2, 6, 10))
# sun_spore_p

shade_spore_p <- plot_areas(spore_med_sh) +
  labs(x = "Date", y = NULL) +
  scale_y_continuous(labels = NULL, expand = c(0.01,0.01)) +
  theme(plot.margin = margin(6, 4, 6, 24))
# shade_spore_p

areaslegend <- cowplot::get_legend(
  sun_latent_p +
    labs(color = "Lesion Age\n(weeks)") +
    theme(
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 9),
      legend.key.height = unit(0.55, "cm")
    )  +
    theme(legend.justification = "top")
  )

areasage_p <- cowplot::plot_grid(
  sun_latent_p + theme(legend.position="none"),
  shade_latent_p + theme(legend.position="none"),
  sun_spore_p + theme(legend.position="none"),
  shade_spore_p + theme(legend.position="none"),
  nrow = 2,
  ncol = 2,
  labels = "AUTO",
  label_size = 12,
  hjust = c(-0.6,-1.2,-0.6,-1.2),
  vjust = c(1.5,1.5,1.2,1.2),
  rel_heights = c(1,1.1),
  rel_widths = c(1.04,1)
  )

areasage_p_l <- cowplot::plot_grid(areasage_p,
                                    areaslegend,
                                    nrow = 1,
                                    rel_widths = c(11,1))
areasage_p_l



#########
# n_lesions per max age + Occupancy % per age at week 8


plot_nls <- function(treatm) {
  treatm <- enquo(treatm)
  filter(perdatenage, !is.na(!!treatm)) %>%
    ggplot(aes(fdate, !!treatm, color=as.factor(age))) +
    geom_line(aes(group = as.factor(firstfound))) +
    geom_point(size = 0.5) +
    scale_color_manual(values = palzissou8) +
    coord_cartesian(ylim = c(0, 25)) +
    # scale_y_continuous(expand = c(0.01,0.5)) +
    scale_x_date(labels = NULL) +
    # labs(x = NULL, y = "Lesion Number per Leaf") +
    theme_bw()
}

plot_occup <- function(treatm) {
  treatm <- enquo(treatm)
  filter(perdatenage, !is.na(!!treatm)) %>%
    ggplot(aes(fdate, !!treatm,
               group = as.factor(age),
               fill = as.factor(age))) +
    geom_col(
      color = "white",
      size = 0.1,
      width = 14) +
    scale_color_manual(values = palzissou8) +
    scale_fill_manual(values = palzissou8) +
    coord_cartesian(ylim = c(0,35), xlim = as.Date(c("2017-05-18", "2018-07-24"))) +
    labs(x = "Date", y = "Occupied Sites (%)") +
    theme_bw()
}

nlage_sun_p <- plot_nls(nl_med_sun) +
  theme(plot.margin = margin(10, 6, 2, 6)) +
  labs(x = NULL, y = "Lesion Count")
# # nlage_sun_p

nlage_sh_p <- plot_nls(nl_med_sh) +
  theme(plot.margin = margin(10, 6, 2, 16)) +
  labs(x = NULL, y = NULL) +
  scale_y_continuous(labels = NULL)
# nlage_sh_p

nl_legend <- cowplot::get_legend(
  nlage_sun_p +
    labs(color = "Maximum\nLesion Age\n(weeks)") +
    theme(
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 8),
      legend.key.height = unit(0.38, "cm")
    ) 
  )
  # +
  # theme(legend.justification = "top"))

occup_sun_p <- plot_occup(occupancy_sun) +
theme(plot.margin = margin(6, 6, 2, 6))
# occup_sun_p

occup_sh_p <- plot_occup(occupancy_sh) +
  theme(plot.margin = margin(6, 6, 2, 16)) +
  labs(y = NULL) +
  scale_y_continuous(labels = NULL)
# occup_sh_p

occup_legend <- cowplot::get_legend(
  occup_sun_p +
    labs(fill = "Lesion Age\n(weeks)") +
    theme(
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 8),
      legend.key.height = unit(0.4, "cm"))
    )
    #   +
    # theme(legend.justification = "top"))


occnlage_p <- cowplot::plot_grid(
  nlage_sun_p + theme(legend.position="none"),
  nlage_sh_p + theme(legend.position="none"),
  NULL,
  occup_sun_p + theme(legend.position="none"),
  occup_sh_p + theme(legend.position="none"),
  NULL,
  # align = "h",
  # axis = "b",
  # rel_heights = c(1,1.2),
  labels = c("A","B","","C","D",""), #"AUTO", #
  label_size = 12,
  ncol = 3,
  nrow = 2,
  rel_heights = c(1, 1.1),
  rel_widths = c(1.03, 1, 0.2)
)

nlage_p_l <- occnlage_p +
  draw_grob(
    nl_legend,
    x = 2.08/2.2,
    y = 0.745,
    width = 0.1/2.38,
    height = 0.2/2.1,
    scale = 0.2,
    halign = 0,
    valign = 0,
  ) +
  draw_grob(
    occup_legend,
    x = 2.08/2.2,
    y = 0.3,
    width = 0.1/2.38,
    height = 0.2/2.1,
    scale = 0.2,
    halign = 0,
    valign = 0,
  )

# nlage_p_l <- cowplot::plot_grid(nlage_p, nl_legend, nrow = 1, rel_widths = c(8,1))
# nlage_p_l



######################################
# Save Plots
######################################

if (saveplots){
  ggsave(file.path(plots_path, "weather.png"), w_plot, width = 8, height = 5)
  ggsave(file.path(plots_path, "areas_age.png"), areasage_p_l, width = 10, height = 5)
  ggsave(file.path(plots_path, "nlesions_age.png"), nlage_p_l, width = 10, height = 5)
  
}

if (savetodis){
  ggsave(file.path(dis_path, "Appendix", "Figs", "weather.png"), w_plot, width = 8, height = 5)
  ggsave(file.path(dis_path, "Appendix", "Figs", "areas_age.png"), areasage_p_l, width = 10, height = 5)
  ggsave(file.path(dis_path, "Appendix", "Figs", "nlesions_age.png"), nlage_p_l, width = 10, height = 5)
}
