library(dplyr)
library(ggplot2)

#Rust input
RustDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoRoya.csv", h=T)

#Plant data
PlantDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/DatosPlantas.csv")

# Weather input. Getting rainy days and daily mean temp
WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)
WeatherDB$fDate <- as.Date(WeatherDB$Date, format="%m/%d/%y")
WeatherDB$Rainy <- WeatherDB$RainTFS != 0
# Datos de CATIE reportan como días de lluvia cuando hubo 0.1 mm o más, pero el mínimo de lectura es 0.1
# O sea, da igual poner != 0 que >= 0.1


#file names and paths
t.plot <- "TFSSF"
data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"
treat.name <- ifelse(t.plot == "TFSSF", "Tur_Sun", ifelse(t.plot == "TMSSF", "Tur_Shade", "Non_Tur"))
areas.name <- paste0(treat.name,"_AvAreas")
lesions.name <- paste0(treat.name,"_NLesions")
firstday <- min(WeatherDB$fDate)


#subset treatment data
treatment <- subset(RustDB, Treatment == t.plot)
treatment$NumArea <- as.numeric(as.character(treatment$TotalAreaLesion))
treatment <- mutate(treatment, CorrectedArea = Correct.NA(NumArea, AreaWithSpores))
treatment$fDate <- as.Date(treatment$Date, format="%m/%d/%y")
#add ids
treatment$branch.id <- as.factor(paste(treatment$DateLabel, treatment$Plant, treatment$Branch, 
                                       sep = "."))
treatment$leaf.id <- as.factor(paste(treatment$DateLabel, treatment$Plant, treatment$Branch,
                                     treatment$RightLeftLeaf, sep = "."))
treatment$rust.id <- as.factor(paste(treatment$DateLabel, treatment$Plant, treatment$Branch, 
                                     treatment$RightLeftLeaf, treatment$Lesion, sep = "."))
treatment$dayN <- treatment$fDate - firstday

treatment$WasInfected <- if_else(is.na(treatment$Infected), 1, if_else(treatment$Infected == 0, 0, 1))

