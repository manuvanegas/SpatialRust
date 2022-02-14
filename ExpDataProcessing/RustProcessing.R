library(dplyr)
library(ggplot2)
library(wesanderson)

"TODO:
1) Remove data corresponding to entire cycle 5.
Current status: filtering done from start of cycle 5 till start of cycle 6, but that is not the end of cycle 5.
This has implications on `v.assign.cycle` because it is based on even/odd cycle numbers. Cycle 6 will turn into cycle 5, so it needs to be reversed

2) Calculate 1st and 3rd quartiles so they can be plotted"

#Rust input
RustDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoRoya.csv", h=T)
#Plant data
PlantDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/DatosPlantas.csv", h=T)

# Two options: "Sun" or "Shade" (both in Turrialba)
SunOrShade <- "Sun"

#file names and paths
data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"
treat.name <- ifelse(t.plot == "TFSSF", "Tur_Sun", ifelse(t.plot == "TMSSF", "Tur_Shade", "Non_Tur"))
areas.name <- paste0(treat.name,"_AvAreas")
lesions.name <- paste0(treat.name,"_NLesions")

#subset, add id, date, age variables
rSelected <- prepare.subset(SunOrShade)

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
# Metric #1
# Lesion areas per age
areas_per_age <- filter(rSelected, Fallen == 0) %>%
  filter(plant.group == 1 | age.week < 7) %>% # remove overlaps between groups 2 and 3
  group_by(day.n, f.date, first.found, plant.group, sample.cycle, age.week) %>%
  summarise(median.area = median(num.area, na.rm = TRUE),
            iqr.area = IQR(num.area, na.rm = TRUE),
            count = n()) %>%
  filter(count > 1) # getting rid of medians over just one observation

# quick plot to verify
# ggplot(areas_per_age, aes(x=day.n, y=median.area, group=as.factor(age.week))) +
#   geom_point(aes(color = as.factor(age.week)))

#########################################
# Metric #2
# Approximate lesion areas
df_leading_rust <- group_by(rSelected, leaf.id) %>%
  mutate(max.area = max(num.area, na.rm = TRUE)) %>%
  filter(max.area != -Inf, num.area == max.area)
leading_rusts <- unique(df_leading_rust$rust.id)

app_areas <- filter(rSelected, Fallen == 0) %>%
  group_by(day.n, leaf.id) %>%
  mutate(n.lesions = n()) %>%
  filter(rust.id %in% leading_rusts) %>%
  mutate(appr.area = n.lesions * num.area) %>%
  group_by(day.n, f.date, plant.group, sample.cycle) %>%
  summarise(med.app.area = median(appr.area, na.rm = T),
            iqr.app.area = IQR(appr.area, na.rm = T),
            count.areas = n())

#########################################
# Metric #3
# Fallen leaves %
fallen_leaves <- group_by(rSelected, day.n, f.date, plant.group, sample.cycle, leaf.id) %>%
  summarise(fallen = mean(Fallen)) %>% #not a real mean. The Fallen value is the same for leaf.id*date
  group_by(day.n, f.date, plant.group) %>%
  summarise(fallen.pct = sum(fallen) / n(),
            count.fallen = n()) %>%
  filter(count.fallen > 1)
  
areas_and_fallen <- left_join(app_areas, fallen_leaves)

#########################################
# Write rust data 
rDays <- unique(union(union(areas_per_age$day.n, app_areas$day.n), fallen_leaves$day.n))
write.csv(rDays, paste0(data_path, "inputs/sun_whentocollect_rust.csv"))
write.csv(areas_per_age, paste0(data_path, ifelse(SunOrShade == "Sun", "compare/Sun_Areas_Age.csv", "compare/Shade_Areas_Age.csv")))
write.csv(areas_and_fallen, paste0(data_path, ifelse(SunOrShade == "Sun", "compare/Sun_Appr_Areas_Fallen.csv", "compare/Shade_Appr_Areas_Fallen.csv")))

##############################################################
# Plots
##############################################################
rfilename <- ifelse(SunOrShade == "Sun", "sun_rust", "shade_rust")

areas_age_plot <- ggplot(areas_per_age) +
  geom_line(aes(x = f.date, y = median.area,
                group = as.factor(first.found),
                color = as.factor(age.week))) +
  geom_point(aes(x = f.date, y = median.area,
                 group = as.factor(age.week),
                 color = as.factor(age.week))) +
  labs(x = "Date", y = "Median Rust Area", color = "Rust Age (Weeks)") +
  scale_color_manual(values = wes_palette(name = "Zissou1", n=8, type = "continuous")) +
  theme_bw()
#areas_age_plot
ggsave(paste0(plots_path, rfilename, "_areas_age.png"), areas_age_plot, width = 8, height = 4)
ggsave(paste0(plots_path, rfilename, "_areas_age2.png"), areas_age_plot, width = 12, height = 6)


appr_area_plot <- ggplot(areas_and_fallen,
                         aes(x = f.date,y = med.app.area,
                             group = as.factor(sample.cycle),
                             color = as.factor(sample.cycle))) +
  geom_line() +
  geom_point() +
  labs(x = "Date", y = "Median Approximate Total Area", color = "Sampling Group") +
  scale_color_manual(values = wes_palette("Zissou1", n = 10, type = "continuous")) +
  theme_bw()
#appr_area_plot
ggsave(paste0(plots_path, rfilename, "_appr_areas.png"), appr_area_plot, width = 8, height = 4)
ggsave(paste0(plots_path, rfilename, "_appr_areas2.png"), appr_area_plot, width = 12, height = 6)


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
  scale_color_manual(values = wes_palette("Zissou1", n = 10, type = "continuous")) +
  theme_bw()
#fallen_plot
ggsave(paste0(plots_path, rfilename, "_fallen_pct.png"), fallen_plot, width = 8, height = 4)
ggsave(paste0(plots_path, rfilename, "_fallen_pct2.png"), fallen_plot, width = 12, height = 6)


##############################################################
# Functions
##############################################################

prepare.subset <- function(SunOrShade) {
  t.plot <- ifelse(SunOrShade == "Sun", "TFSSF", "TMSSF") 
  #subset rust data for "TFSSF" treatment, first 25 lesions, infected or fallen leaves
  #(all Fallen are Infected = NA and TotalArea = 0 and viceversa)
  rSelected <- subset(RustDB, Treatment == t.plot & Lesion <= 25 & (Infected == 1 | Fallen == 1))
  rSelected$num.area <- as.numeric(as.character(rSelected$TotalAreaLesion))
  # rSelected <- mutate(rSelected, CorrectedArea = Correct.NA(num.area, AreaWithSpores))
  rSelected$f.date <- as.Date(rSelected$Date, format="%m/%d/%y")
  # correction is necessary because branch values are pooled
  rSelected$f.date <- case_when(rSelected$f.date == "2017-05-11" ~ as.Date("2017-05-12"),
                                TRUE ~ as.Date(rSelected$f.date)) 
  rSelected$day.n <- rSelected$f.date - firstday + 1
  
  #add ids
  rSelected$branch.id <- as.factor(paste(rSelected$Plant, rSelected$Branch, 
                                         sep = "."))
  rSelected$leaf.id <- as.factor(paste(rSelected$Plant, rSelected$Branch,
                                       rSelected$RightLeftLeaf, sep = "."))
  rSelected$rust.id <- as.factor(paste(rSelected$Plant, rSelected$Branch, 
                                       rSelected$RightLeftLeaf, rSelected$Lesion, sep = "."))
  
  return(rSelected)
}

extract.add.info <- function(rSelected) {
  # add lesion age in weeks
  rSelected <- calc.lesion.weeks(rSelected)
  
  #add sampling group: 1 is first half, 2 is group A of 2nd half, 3 is group B
  if (SunOrShade == "Sun") {
    sampling_plants <- c(19:36, 76,79,81,82,83,85,87,90,91,77,78,80,84,86,88,89,92,93)
    # correct duplicated rust (rust.id = "27.T1.D.1")
    rSelected <- rSelected[!(rSelected$rust.id == "27.T1.D.1" & rSelected$day.n < 220),]
  } else {
    sampling_plants <- c(1:18,94,95,99,100,102,104,105,109,110,96,97,98,101,103,106,107,108,111)
    # correct duplicated rusts
    print("WARNING! Shade dataset has not been corrected")
    print("List of duplicate rusts:")
    dup_r <- unique(rSelected[rSelected$age.week > 7,"rust.id"])
    print(dup_r)
    print("Days with dups:")
    print(unique(rSelected[rSelected$age.week > 7, "day.n"]))
    
    change_4T4 <- rSelected$day.n < 232 & rSelected$day.n > 216 & rSelected$branch.id == "4.T4"
    change_17T6 <- rSelected$day.n < 232 & rSelected$day.n > 216 & rSelected$branch.id =="17.T6"
    last_b_4 <- max(as.character(rSelected[rSelected$Plant == 4, "branch.id"])) # "4.T6"
    last_b_17 <- max(as.character(rSelected[rSelected$Plant == 17, "branch.id"])) # "17.T7"
    
    # need to add new branch.id's and rust.id's as factor levels
    # example:
    rSelected$rust.id <- factor(rSelected$rust.id, levels = c(levels(rSelected$rust.id), "4.T7.D.1"))
    
    #then replace ids (the following will error)
    rSelected[change_4T4, c("branch.id", "rust.id")] <- c("4.T7", paste("4.T7", rSelected$RightLeftLeaf[change_4T4], rSelected$Lesion[change_4T4], sep = "."))
  }
  rSelected$plant.group <- assign.group(rSelected$Plant, sampling_plants)
  rSelected$sample.cycle <- v.assign.cycle(rSelected$day.n, rSelected$plant.group)
  
  return(rSelected)
}

calc.lesion.weeks <- function(d) {
  d$first.found <- as.Date(rep_len(0,length(d$rust.id)), origin = "2000-01-01")
  rusts <- unique(d$rust.id)
  for(rr in rusts) {
    #r_id <- subset(d, rust.id == rr)
    #start.d <- min(rSelected[rSelected$rust.id == rr, "f.date"])
    d$first.found[d$rust.id == rr] <- min(rSelected[rSelected$rust.id == rr, "f.date"])
    #for(dd in 1:length(r_id$f.date)) {
    #  d$l.age[d$rust.id == rr & d$f.date == r_id$f.date[dd]] = r_id$f.date[dd] - start.d + 3
    #  d$age.week[d$rust.id == rr & d$f.date == r_id$f.date[dd]] = round(difftime(r_id$f.date[dd], start.d, units = "weeks"))
    #}
  }
  d$age.week <- round(difftime(d$f.date, d$first.found, units = "weeks"))
  return(d)
}

assign.group <- function(id, sampled_plants){
  p.group <- ifelse(id %in% sampled_plants[1:18], 1, ifelse(id %in% sampled_plants[19:27], 2, ifelse(id %in% sampled_plants[28:36],3, NA)))
  return(p.group)
}

assign.cycle <- function(day.n, plant.group){
  s.cycle <- which.max(day.n <= plant_sampling_days) - 1
  if (s.cycle == 0) {
    s.cycle <- 11
  }
  if (plant.group == 2 & s.cycle %% 2 == 0) {
    s.cycle <- s.cycle - 1
  } else if (plant.group == 3 & s.cycle %% 2 != 0){
    s.cycle <- s.cycle - 1
  }
  return(s.cycle)
}

v.assign.cycle <- Vectorize(assign.cycle)

remove.cycle.5 <- function(df) {
  df <- subset(df, sample.cycle != 5)
  
  df$sample.cycle <- ifelse(df$sample.cycle > 5, df$sample.cycle - 1, df$sample.cycle)
  #case_when(sample.cycle > 5 ~ sample.cycle - 1, TRUE ~ sample.cycle)
  return(df)
}


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
