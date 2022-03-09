library(dplyr)
library(ggplot2)
library(wesanderson)

source("RustFunctions.R")

#Rust input
RustDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoRoya.csv", h=T)
#Plant data
PlantDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/DatosPlantas.csv", h=T)

# Two options: "Sun" or "Shade" (both in Turrialba)
SunOrShade <- "Sun"

#file paths
data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"

WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)
WeatherDB$fDate <- as.Date(WeatherDB$Date, format="%m/%d/%y")
p.treatment <- ifelse(SunOrShade == "Sun", "TFS", "TMS") 
wSelected <- select(WeatherDB, fDate, QuantRain = "RainTFS", MeanTa = paste0("meanTa", p.treatment))
firstday <- min(wSelected$fDate)

#subset, add id, date, age variables
rSelected <- subset.n.prepare(SunOrShade)

sampled_plants <- subset(PlantDB, Plant %in% rSelected$Plant, select = c("DateLabel", "Plant"))
sampled_plants$f.date <- as.Date(sampled_plants$DateLabel, format="%m/%d/%y")
sampled_plants$f.date <- case_when(sampled_plants$f.date == "2017-05-11" ~ as.Date("2017-05-12"),
                              TRUE ~ as.Date(sampled_plants$f.date)) # correction is necessary because branch values are pooled
sampled_plants$day.n <- sampled_plants$f.date - firstday + 1
plant_sampling_days <- unique(sampled_plants$day.n)
effective_sampling_days <- plant_sampling_days[-5]

rSelected <- extract.add.info(rSelected)
rSelected <- remove.cycle.5(rSelected)
# 5th sampling cycle has very few observations (see final section about sampling patterns)

#########################################
# AreaWithSpores or spore.area
# Metric #1
# Lesion  and spore areas per age
areas_per_age <- filter(rSelected, Fallen == 0) %>%
  filter(plant.group == 1 | age.week < 7) %>% # remove overlaps between groups 2 and 3
  group_by(day.n, f.date, first.found, plant.group, sample.cycle, age.week) %>%
  summarise(median.area = median(num.area, na.rm = T),
            q1.area = quantile(num.area, 1/4, na.rm = T),
            q3.area = quantile(num.area, 3/4, na.rm = T),
            median.spores = median(AreaWithSpores, na.rm = T),
            q1.spores = quantile(AreaWithSpores, 1/4, na.rm = T),
            q3.spores = quantile(AreaWithSpores, 3/4, na.rm = T),
            count = n(),
            dist.area = n_distinct(num.area, na.rm = T),
            dist.spores = n_distinct(AreaWithSpores, na.rm = T),
            areanas = sum(is.na(num.area)),
            sporenas = sum(is.na(AreaWithSpores))) %>%
  filter(count > 1) # getting rid of medians over just one observation

lesion_per_age <- ungroup(areas_per_age) 

spore_per_age <- filter(areas_per_age, dist.spores > 1 | (sporenas / count) < 0.7) %>%
  ungroup() 

# quick plots to verify
# ggplot(areas_per_age, aes(x=day.n, y=median.area, group=as.factor(age.week))) + 
#   geom_point(aes(color = as.factor(age.week)))
# 
# ggplot(areas_per_age, aes(x=day.n, y=median.spores, group=as.factor(age.week))) +
  # geom_point(aes(color = as.factor(age.week)))


#########################################
# Metric #2
# Approximate lesion areas
df_leading_rust <- group_by(rSelected, leaf.id) %>%
  mutate(max.area = max(num.area, na.rm = T),
         max.spores = max(AreaWithSpores, na.rm = T)) %>%
  filter(max.area != -Inf, num.area == max.area) %>%
  distinct(leaf.id, max.area, .keep_all = T)

leading_rusts <- unique(df_leading_rust$rust.id)

app_areas <- filter(rSelected, Fallen == 0) %>%
  group_by(day.n, leaf.id) %>%
  mutate(n.lesions = n()) %>%
  filter(rust.id %in% leading_rusts) %>%
  mutate(appr.area = n.lesions * num.area,
         appr.spores = n.lesions * spore.area) %>%
  group_by(day.n, f.date, plant.group, sample.cycle) %>%
  summarise(med.app.area = median(appr.area, na.rm = T),
            med.app.spores = median(appr.spores, na.rm = T),
            count.areas = n())


## The following section was not used, but I am leaving it here commented for future ref
# The idea was to repeat the steps above, but for spore areas
# However, using the max spore area was introducing disconnect between what happens with the total area vs the sporulated one
# (selected rust.ids were different)
# 
# df_leading_spore <- group_by(rSelected, leaf.id) %>%
#   mutate(max.area = max(AreaWithSpores, na.rm = T)) %>%
#   filter(max.area != -Inf, AreaWithSpores == max.area)%>%
#   distinct(leaf.id, max.area, .keep_all = T)
# 
# leading_spores <- unique(df_leading_spore$rust.id)
# 
# appr_spore <- filter(rSelected, Fallen == 0) %>%
#   group_by(day.n, leaf.id) %>%
#   mutate(n.lesions = n()) %>%
#   filter(rust.id %in% leading_spores) %>%
#   mutate(appr.area = n.lesions * num.area,
#          appr.spores = n.lesions * spore.area) %>%
#   group_by(day.n, f.date, plant.group, sample.cycle) %>%
#   summarise(med.app.area = median(appr.area, na.rm = T),
#             med.app.spores = median(appr.spores, na.rm = T),
#             count.areas = n())

#########################################
# Metric #3
# Fallen leaves %
fallen_leaves <- group_by(rSelected, day.n, f.date, plant.group, sample.cycle, leaf.id) %>%
  summarise(fallen = mean(Fallen)) %>% #not a real mean. The Fallen value is the same for leaf.id*date
  group_by(day.n, f.date, plant.group) %>%
  summarise(fallen.pct = sum(fallen) / n(),
            count.fallen = n()) %>%
  filter(count.fallen > 1)

# Join Ms 2 & 3  
areas_and_fallen <- left_join(app_areas, fallen_leaves) %>% ungroup()

#########################################
# Write rust data 
rDays <- unique(union(union(areas_per_age$day.n, app_areas$day.n), fallen_leaves$day.n))
write.csv(rDays, paste0(data_path, "inputs/sun_whentocollect_rust.csv"))

colnames(lesion_per_age) <- gsub("\\.", "_", colnames(lesion_per_age))
write.csv(select(lesion_per_age, c(1,5,6,7)),
          paste0(data_path, ifelse(SunOrShade == "Sun",
                                   "compare/Sun_Areas_Age.csv",
                                   "compare/Shade_Areas_Age.csv")))
colnames(spore_per_age) <- gsub("\\.", "_", colnames(spore_per_age))
write.csv(select(spore_per_age, c(1,5,6,10)),
          paste0(data_path, ifelse(SunOrShade == "Sun",
                                   "compare/Sun_Spore_Age.csv", 
                                   "compare/Shade_Spore_Age.csv")))

 colnames(areas_and_fallen) <- gsub("\\.", "_", colnames(areas_and_fallen))
write.csv(select(areas_and_fallen, c(1,4,5,6,8)),
          paste0(data_path, ifelse(SunOrShade == "Sun", 
                                   "compare/Sun_Appr_Areas_Fallen.csv",
                                   "compare/Shade_Appr_Areas_Fallen.csv")))

write.csv(lesion_per_age, paste0(data_path, ifelse(SunOrShade == "Sun", "plotdata/Sun_Areas_Age.csv", "plotdata/Shade_Areas_Age.csv")))
write.csv(spore_per_age, paste0(data_path, ifelse(SunOrShade == "Sun", "plotdata/Sun_Spore_Age.csv", "plotdata/Shade_Spore_Age.csv")))
write.csv(areas_and_fallen, paste0(data_path, ifelse(SunOrShade == "Sun", "plotdata/Sun_Appr_Areas_Fallen.csv", "plotdata/Shade_Appr_Areas_Fallen.csv")))

##############################################################
# Plots
##############################################################
rfilename <- ifelse(SunOrShade == "Sun", "sun_rust", "shade_rust")

areas_age_plot <- ggplot(lesion_per_age,
                         aes(x = f.date,
                             y = median.area,
                             color = as.factor(age.week))) +
  geom_errorbar(aes(ymax = q3.area,
                    ymin = q1.area),
                width = 4, alpha = 0.6) +
  geom_line(aes(group = as.factor(first.found))) +
  geom_point(aes(group = as.factor(age.week))) +
  coord_cartesian(ylim = c(0, 0.6)) +
  labs(x = "Date", y = "Median Lesion Area", color = "Rust Age (Weeks)") +
  scale_color_manual(values = wes_palette(name = "Zissou1", n=8, type = "continuous")) +
  theme_bw()
areas_age_plot
# ggsave(paste0(plots_path, rfilename, "_areas_age.png"), areas_age_plot, width = 8, height = 4)
# ggsave(paste0(plots_path, rfilename, "_areas_age2.png"), areas_age_plot, width = 12, height = 6)

spores_age_plot <- ggplot(spore_per_age,
                         aes(x = f.date,
                             y = median.spores,
                             color = as.factor(age.week))) +
  geom_errorbar(aes(ymax = q3.spores,
                    ymin = q1.spores),
                width = 4, alpha = 0.6) +
  geom_line(aes(group = as.factor(first.found))) +
  geom_point(aes(group = as.factor(age.week))) +
  coord_cartesian(ylim = c(0, 0.6)) +
  labs(x = "Date", y = "Median Sporulated Area", color = "Rust Age (Weeks)") +
  scale_color_manual(values = wes_palette(name = "Zissou1", n=8, type = "continuous")) +
  theme_bw()
spores_age_plot
# ggsave(paste0(plots_path, rfilename, "_spore_age.png"), spores_age_plot, width = 8, height = 4)
# ggsave(paste0(plots_path, rfilename, "_spore_age2.png"), spores_age_plot, width = 12, height = 6)


appr_area_plot <- ggplot(areas_and_fallen,
                         aes(x = f.date, y = med.app.area,
                             group = as.factor(sample.cycle),
                             color = as.factor(sample.cycle))) +
  geom_line() +
  geom_point() +
  coord_cartesian(ylim = c(0, 0.6)) +
  labs(x = "Date", y = "Median Approximate Total Area", color = "Sampling Group") +
  scale_color_manual(values = wes_palette("FantasticFox1", n = 10, type = "continuous")) +
  theme_bw()
appr_area_plot
# ggsave(paste0(plots_path, rfilename, "_appr_areas.png"), appr_area_plot, width = 8, height = 4)
# ggsave(paste0(plots_path, rfilename, "_appr_areas2.png"), appr_area_plot, width = 12, height = 6)

appr_spore_plot <- ggplot(areas_and_fallen,
                          aes(x = f.date,y = med.app.spores,
                              group = as.factor(sample.cycle),
                              color = as.factor(sample.cycle))) +
  geom_line() +
  geom_point() +
  coord_cartesian(ylim = c(0, 0.6)) +
  labs(x = "Date", y = "Median Approximate Spore Area", color = "Sampling Group") +
  scale_color_manual(values = wes_palette("FantasticFox1", n = 10, type = "continuous")) +
  theme_bw()
appr_spore_plot
# ggsave(paste0(plots_path, rfilename, "_appr_spore.png"), appr_spore_plot, width = 8, height = 4)
# ggsave(paste0(plots_path, rfilename, "_appr_spore2.png"), appr_spore_plot, width = 12, height = 6)


fallen_plot <- ggplot(areas_and_fallen,
                      aes(x = f.date, y = fallen.pct,
                          group = as.factor(sample.cycle),
                          color = as.factor(sample.cycle))) +
  geom_line() +
  geom_point() +
  # geom_vline(aes(xintercept = as.Date("2018-01-09"))) +
  # geom_vline(aes(xintercept = as.Date("2018-02-06"))) +
  # geom_vline(aes(xintercept = as.Date("2018-03-06"))) +
  # geom_vline(aes(xintercept = as.Date("2018-04-03"))) +
  # geom_vline(aes(xintercept = as.Date("2018-05-02"))) +
  # geom_vline(aes(xintercept = as.Date("2018-05-29"))) +
  # geom_vline(aes(xintercept = as.Date("2018-06-26"))) +
  labs(x = "Date", y = "Fallen Leaves (%)", color = "Sampling Group") +
  scale_color_manual(values = wes_palette("FantasticFox1", n = 10, type = "continuous")) +
  coord_cartesian(ylim = c(0, 1.0)) +
  theme_bw()
fallen_plot
# ggsave(paste0(plots_path, rfilename, "_fallen_pct.png"), fallen_plot, width = 8, height = 4)
# ggsave(paste0(plots_path, rfilename, "_fallen_pct2.png"), fallen_plot, width = 12, height = 6)





###############################################################
## Figuring out rust sampling patterns
###############################################################
shade_rsel <- subset(RustDB, Treatment == "TMSSF" & Lesion <= 25 & (Infected == 1 | Fallen == 1))
shade_rsel$num.area <- as.numeric(as.character(shade_rsel$TotalAreaLesion))
shade_rsel$f.date <- as.Date(shade_rsel$Date, format="%m/%d/%y")
shade_rsel$f.date <- case_when(pSelected$f.date == "2017-05-11" ~ as.Date("2017-05-12"),
                                TRUE ~ as.Date(pSelected$f.date))
shade_rsel$day.n <- shade_rsel$f.date - firstday + 1

ggplot(data = shade_rsel, aes(x = f.date, y = num.area, group = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant)))
plot(shade_rsel$f.date, shade_rsel$Plant)

plant_ids_shade <-distinct_at(shade_rsel, c("day.n", "Plant"))
plant_ids_shade_plot <- ggplot(plant_ids_shade, aes(x = day.n, y = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant))) +
  geom_vline(aes(xintercept = plant_sampling_days[5])) +
  geom_vline(aes(xintercept = plant_sampling_days[6])) +
  geom_vline(aes(xintercept = plant_sampling_days[7])) +
  geom_vline(aes(xintercept = plant_sampling_days[8])) +
  geom_vline(aes(xintercept = plant_sampling_days[9])) +
  geom_vline(aes(xintercept = plant_sampling_days[10])) +
  geom_vline(aes(xintercept = plant_sampling_days[11])) +
  labs(x = "Day #", y = "Plant ID", color= "Plant ID")
ggsave(paste0(plots_path, "Exploratory/Shade Plants in Rust Sampling", ".png"), plant_ids_shade_plot, height = 6, width = 12)

plant_ids_sun <-distinct_at(rSelected, c("day.n", "Plant"))
plant_ids_sun_plot <- ggplot(plant_ids_sun, aes(x = day.n, y = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant))) +
  geom_vline(aes(xintercept = plant_sampling_days[5])) +
  geom_vline(aes(xintercept = plant_sampling_days[6])) +
  geom_vline(aes(xintercept = plant_sampling_days[7])) +
  geom_vline(aes(xintercept = plant_sampling_days[8])) +
  geom_vline(aes(xintercept = plant_sampling_days[9])) +
  geom_vline(aes(xintercept = plant_sampling_days[10])) +
  geom_vline(aes(xintercept = plant_sampling_days[11])) +
  labs(x = "Day #", y = "Plant ID", color= "Plant ID")
ggsave(paste0(plots_path, "Exploratory/Sun Plants in Rust Sampling", ".png"), plant_ids_sun_plot, height = 6, width = 12)
