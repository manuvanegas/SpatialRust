library(dplyr)
library(ggplot2)

# Two options: "Sun" or "Shade" (both in Turrialba)
SunOrShade <- "Sun"

#Rust input
RustDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoRoya.csv", h=T)

#Plant data
PlantDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/DatosPlantas.csv", h=T)

# Weather input
WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)
WeatherDB$fDate <- as.Date(WeatherDB$Date, format="%m/%d/%y")

#file names and paths
t.plot <- ifelse(SunOrShade == "Sun", "TFSSF", "TMSSF") 
data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"
treat.name <- ifelse(t.plot == "TFSSF", "Tur_Sun", ifelse(t.plot == "TMSSF", "Tur_Shade", "Non_Tur"))
areas.name <- paste0(treat.name,"_AvAreas")
lesions.name <- paste0(treat.name,"_NLesions")



# subset weather data for "TFS" treatment. Change to "TMS" for shaded plot
p.treatment <- ifelse(SunOrShade == "Sun", "TFS", "TMS") 
wSelected <- select(WeatherDB, fDate, QuantRain = paste0("Rain", p.treatment), MeanTa = paste0("meanTa", p.treatment))
# CATIE-provided historical data reports number of days with 0.1 mm rain or more. Hence the use of 0.1 as threshold
# Datos de CATIE reportan como días de lluvia cuando hubo 0.1 mm o más, pero el mínimo de lectura es 0.1. O sea, da igual poner != 0 que >= 0.1
wSelected$Rainy <- wSelected$QuantRain >= 0.1
firstday <- min(wSelected$fDate)
wSelected$dayN <- wSelected$fDate - firstday + 1


#subset rust data for "TFSSF" treatment
rSelected <- subset(RustDB, Treatment == t.plot)
rSelected$NumArea <- as.numeric(as.character(rSelected$TotalAreaLesion))
rSelected <- mutate(rSelected, CorrectedArea = Correct.NA(NumArea, AreaWithSpores))
rSelected$fDate <- as.Date(rSelected$Date, format="%m/%d/%y")
#add ids
rSelected$branch.id <- as.factor(paste(rSelected$Plant, rSelected$Branch, 
                                       sep = "."))
rSelected$leaf.id <- as.factor(paste(rSelected$Plant, rSelected$Branch,
                                     rSelected$RightLeftLeaf, sep = "."))
rSelected$rust.id <- as.factor(paste(rSelected$Plant, rSelected$Branch, 
                                     rSelected$RightLeftLeaf, rSelected$Lesion, sep = "."))
rSelected$dayN <- rSelected$fDate - firstday + 1

rSelected$WasInfected <- if_else(is.na(rSelected$Infected), 1, if_else(rSelected$Infected == 0, 0, 1))


# subset plant data according to plant ids present in rSelected
inspPlants <- rSelected$Plant
pSelected <- subset(PlantDB, Plant %in% inspPlants)

pSelected$fDate <- as.Date(pSelected$DateLabel, format="%m/%d/%y")
pSelected$fDate <- case_when(pSelected$fDate == "2017-05-11" ~ as.Date("2017-05-12"),
                             TRUE ~ as.Date(pSelected$fDate)) # correction is necessary because branch values are pooled
pSelected <- mutate(pSelected, SampleGroup = if_else(Plant <= 36, "A", "B"))


#### Extracting data (see Appendix B)
# write relevant weather variables
wfilename <- ifelse(p.treatment == "TFS", "Tur_Sun_Weather.csv", "Tur_Shade_Weather.csv")
write.csv(wSelected, paste0(data_path, "inputs/", wfilename))

# write rust and plant data collection dates
rDays <- rSelected$dayN
pDays <- pSelected$fDate - firstday + 1

write.csv(sort(unique(rDays)), paste0(data_path, "inputs/whentocollect_rust.csv"))
write.csv(sort(unique(pDays))[2:12], paste0(data_path, "inputs/whentocollect_plant.csv")) # leaving out 2017-05-11 because only partial data was collected that date. Data from that day and the next are pooled.

# extract and write lesion_area_per_age


#### Plots

