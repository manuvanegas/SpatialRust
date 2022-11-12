library(dplyr)
library(ggplot2)
library(wesanderson)

# Write processed data files?
writefiles <- FALSE

#Rust data
RustDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoRoya.csv", h=T)
#Plant data
PlantDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/DatosPlantas.csv", h=T)
# Weather data
WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)

# dir paths
input_data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/input"
compare_data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/compare"
fuller_data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/fuller"

# Two options: "Sun" or "Shade" (both in Turrialba)
# SunOrShade <- "Sun"
maxnl <- 25

source("Functions.R")
source("ProcessWeather.R") # firstday is calculated here

# find start date of each survey cycle
cycle_dates <- filter(PlantDB, Plant %in% c(1:36, 76:111)) %>%
  transmute(dates = case_when(
    DateLabel == "5/11/17" |
      DateLabel == "5/15/17" ~ as.Date("2017-05-12"),
    TRUE ~ as.Date(DateLabel, format = "%m/%d/%y")
  )) %>%
  unique() %>%
  transmute(dates = as.numeric(dates - firstday + 1)) %>%
  pull(dates)


# subset for approp treatment, correct var format, add branch.cycle, lesion.age info
# Only first maxnl lesions considered / leaf
sun_treatm <- filter.format.correct.add(RustDB, "Sun", firstday, maxnl)
shade_treatm <- filter.format.correct.add(RustDB, "Shade", firstday, maxnl)

###########################################################
# Lesion-level metrics
# Metrics 1 & 2: Latent and Spore area per age
areasperage <- summ.areas(sun_treatm, shade_treatm)

# some illustrative plots
# ggplot(areasperage, aes(fdate, n_sun, group = age, color = as.factor(age), fill = as.factor(age))) +
#   geom_col() +
#   coord_cartesian(ylim = c(0,1400)) +
#   labs(x = "Date", y = "Number of Lesions", color = "Age", fill = "Age")
# 
# ggplot(areasperage, aes(fdate, n_sh, group = age, color = as.factor(age), fill = as.factor(age))) +
#   geom_col() +
#   coord_cartesian(ylim = c(0,1400)) +
#   labs(x = "Date", y = "Number of Lesions", color = "Age", fill = "Age")

###########################################################
# Leaf-level metrics
# Metric 3: No of lesions (nl) by day and max age in each leaf
nlperage <- summ.count.nl(sun_treatm, shade_treatm)

# Join Metric 3 with 1 & 2 (all are by date and age)
perdateage <- full_join(nlperage, areasperage, by = c("fdate","dayn","age", "firstfound"))

# Metric 4: Proportion of infection site occupancy by age at last week of cycle
occupied <- summ.sites(sun_treatm, shade_treatm) 

# Join all data
# This is prob not the most "optimal" way to do it, but I prefer having separate data frames for each metric
rustdata <- full_join(perdateage, occupied, by = c("fdate","dayn","age"))


########################################################################################
# Write data 

if (writefiles) {
  # Model Inputs
  ## Weather data
  write.csv(wSelected, file.path(fuller_data_path, "fuller_weather.csv"), row.names = F)
  write.csv(wInput, file.path(input_data_path, "input_weather.csv"), row.names = F)
  ## Data collection dates
  rDays <- unique(rustdata$dayn)
  write.csv(rDays, file.path(input_data_path, "whentocollect_rust.csv"), row.names = F)
  
  # Compare model outputs with:
  ## Latent and Spore Area
  write.csv(select(areasperage, dayn, age, area_med_sun, spore_med_sun, area_med_sh, spore_med_sh),
            file.path(compare_data_path, "areas_age.csv"),
            row.names = F)
  ## Number of Lesions
  write.csv(select(nlperage, dayn, age, nl_med_sun, nl_med_sh),
            file.path(compare_data_path, "nlesions_age.csv"),
            row.names = F)
  # Joined data frame
  write.csv(rustdata,
            file.path(fuller_data_path, "fuller_perdate_age.csv"),
            row.names = F)
  write.csv(select(rustdata, dayn, age, nl_med_sun, area_med_sun, spore_med_sun, occupancy_sun, nl_med_sh, area_med_sh, spore_med_sh, occupancy_sh),
            file.path(compare_data_path, "perdateage_age.csv"),
            row.names = F)
  ## Cycle dates (for future reference)
  write.csv(cycle_dates, file.path(fuller_data_path, "cycle_dates.csv"), row.names = F)
}
