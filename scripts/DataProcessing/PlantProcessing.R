library(dplyr)
library(ggplot2)
library(wesanderson)

# Two options: "Sun" or "Shade" (both in Turrialba)
SunOrShade <- "Sun"

#file names and paths
t.plot <- ifelse(SunOrShade == "Sun", "TFSSF", "TMSSF") 
data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"
treat.name <- ifelse(t.plot == "TFSSF", "Tur_Sun", ifelse(t.plot == "TMSSF", "Tur_Shade", "Non_Tur"))

#Plant data
PlantDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/DatosPlantas.csv", h=T)

#Rust input
RustDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoRoya.csv", h=T)#subset rust data for "TFSSF" treatment
rusts_in_treatment <- subset(RustDB, Treatment == t.plot)

# subset plant data according to plant ids present in rSelected
pSelected <- subset(PlantDB, Plant %in% rusts_in_treatment$Plant)

pSelected$f.date <- as.Date(pSelected$DateLabel, format="%m/%d/%y")
pSelected$f.date <- case_when(pSelected$f.date == "2017-05-11" ~ as.Date("2017-05-12"),
                             TRUE ~ as.Date(pSelected$f.date)) # correction is necessary because branch values are pooled
pSelected$day.n <- pSelected$f.date - firstday + 1

#get relative production metrics
#PlantNodes is ignored because it does not change with time
#for each plant, sum fruits and nodes
med_product <- group_by(pSelected, f.date, day.n, Plant) %>%
  summarise(sum.fruits = sum(BranchFruits, na.rm = T),
            sum.nodes = sum(BranchFruitNodes, na.rm = T))
#maximum production to find relative values
maxsumfruits <- max(med_product$sum.fruits)
maxsumnodes <- max(med_product$sum.nodes)
#find relative values and then median
med_prod <- mutate(med_product,
                   rel.fruits = sum.fruits / maxsumfruits,
                   rel.nodes = sum.nodes / maxsumnodes) %>%
  group_by(f.date, day.n) %>%
  summarise(median.relfruits = median(rel.fruits, na.rm = T),
            q1.relfruits = quantile(rel.fruits, 1/4, na.rm = T),
            q3.relfruits = quantile(rel.fruits, 3/4, na.rm = T),
            median.relnodes = median(rel.nodes, na.rm = T),
            q1.relnodes = quantile(rel.nodes, 1/4, na.rm = T),
            q3.relnodes = quantile(rel.nodes, 3/4, na.rm = T)
            #iqr.relfuits = IQR(rel.fruits, na.rm = T),
            #iqr.relnodes = IQR(rel.nodes, na.rm = T)
            ) %>%
  filter(day.n < unique(pSelected$day.n)[5] | day.n >= unique(pSelected$day.n)[6])
  #filter: see rust sampling patterns section. not enough observations in cycle 5

# write plant data collection dates
pDays <- unique(pSelected$day.n)[-5] # see rust sampling patterns section
write.csv(sort(pDays), paste0(data_path, "inputs/sun_whentocollect_plant.csv"))

# write production data
write.csv(med_prod, paste0(data_path, ifelse(SunOrShade == "Sun", "compare/Sun_Plant_Production.csv", "compare/Shade_Plant_Production.csv")))

##############################################################
# Plots
##############################################################
rfilename <- ifelse(SunOrShade == "Sun", "sun_plant", "shade_plant")

zissoublues <- wes_palette("Zissou1",2)
rocketblue <- wes_palette("BottleRocket2", 3)[3]

fruits_plot <- ggplot(med_prod, 
                      aes(x = f.date, y = median.relfruits)) +
  geom_point(size = 2.5, color = rocketblue, alpha = 0.9) +
  geom_errorbar(aes(ymax = q3.relfruits, ymin = q1.relfruits),
                    width = 5, color = rocketblue, alpha = 0.7) +
  labs(x = "Date", y = "Median Relative Production") +
  theme_bw()
fruits_plot

# ggsave(paste0(plots_path, rfilename, "_fruit_prod.png"), fruits_plot, width = 8, height = 4)
# ggsave(paste0(plots_path, rfilename, "_fruit_prod2.png"), fruits_plot, width = 12, height = 6)

nodes_plot <- ggplot(med_prod, 
                      aes(x = f.date, y = median.relnodes)) +
  geom_point(size = 2.5, color = rocketblue, alpha = 0.9) +
  geom_errorbar(aes(ymax = q3.relnodes, ymin = q1.relnodes),
                width = 5, color = rocketblue, alpha = 0.7) +
  labs(x = "Date", y = "Median Relative Production") +
  theme_bw()
nodes_plot

# ggsave(paste0(plots_path, rfilename, "_node_prod.png"), nodes_plot, width = 8, height = 4)
# ggsave(paste0(plots_path, rfilename, "_node_prod2.png"), nodes_plot, width = 12, height = 6)

##################
## Figuring out plant sampling patterns

rusts_in_sun <- subset(RustDB, Treatment == "TFSSF")
plants_in_sun <- subset(PlantDB, Plant %in% rusts_in_sun$Plant)

plants_in_sun$f.date <- as.Date(plants_in_sun$DateLabel, format="%m/%d/%y")
plants_in_sun$f.date <- case_when(plants_in_sun$f.date == "2017-05-11" ~ as.Date("2017-05-12"),
                             TRUE ~ as.Date(plants_in_sun$f.date))
plants_in_sun$day.n <- plants_in_sun$f.date - firstday + 1

plants_in_sun <-distinct_at(plants_in_sun, c("day.n", "Plant"))
plants_in_sun_plot <- ggplot(plants_in_sun, aes(x = day.n, y = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant))) +
  geom_vline(aes(xintercept = unique(pDays)[5])) +
  geom_vline(aes(xintercept = unique(pDays)[6])) +
  geom_vline(aes(xintercept = unique(pDays)[7])) +
  geom_vline(aes(xintercept = unique(pDays)[8])) +
  geom_vline(aes(xintercept = unique(pDays)[9])) +
  geom_vline(aes(xintercept = unique(pDays)[10])) +
  geom_vline(aes(xintercept = unique(pDays)[11])) +
  labs(x = "Day #", y = "Plant ID", color= "Plant ID")
ggsave(paste0(plots_path, "Exploratory/Sun Plants in Plant Sampling", ".png"), plants_in_sun_plot, height = 6, width = 12)

rusts_in_shade <- subset(RustDB, Treatment == "TMSSF")
plants_in_shade <- subset(PlantDB, Plant %in% rusts_in_shade$Plant)
plants_in_shade$f.date <- as.Date(plants_in_shade$DateLabel, format="%m/%d/%y")
plants_in_shade$f.date <- case_when(plants_in_shade$f.date == "2017-05-11" ~ as.Date("2017-05-12"),
                                  TRUE ~ as.Date(plants_in_shade$f.date))
plants_in_shade$day.n <- plants_in_shade$f.date - firstday + 1
plants_in_shade <-distinct_at(plants_in_shade, c("day.n", "Plant"))
plants_in_shade_plot <- ggplot(plants_in_shade, aes(x = day.n, y = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant))) +
  geom_vline(aes(xintercept = unique(pDays)[5])) +
  geom_vline(aes(xintercept = unique(pDays)[6])) +
  geom_vline(aes(xintercept = unique(pDays)[7])) +
  geom_vline(aes(xintercept = unique(pDays)[8])) +
  geom_vline(aes(xintercept = unique(pDays)[9])) +
  geom_vline(aes(xintercept = unique(pDays)[10])) +
  geom_vline(aes(xintercept = unique(pDays)[11])) +
  labs(x = "Day #", y = "Plant ID", color= "Plant ID")
ggsave(paste0(plots_path, "Exploratory/Shade Plants in Plant Sampling", ".png"), plants_in_shade_plot, height = 6, width = 12)

