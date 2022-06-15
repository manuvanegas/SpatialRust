library(dplyr)
library(ggplot2)
library(wesanderson)

# Two options: "Sun" or "Shade" (both in Turrialba)
SunOrShade <- "Heredia"

#file paths
data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"

# Weather input
WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)
WeatherDB$fDate <- as.Date(WeatherDB$Date, format="%m/%d/%y")

# subset weather data for "TFS" treatment. Change to "TMS" for shaded plot
p.treatment <- ifelse(SunOrShade == "Sun", "TFS", ifelse(SunOrShade == "Shade", "TMS", "HMS")) 
p.rain <- ifelse(SunOrShade == "Sun" || SunOrShade == "Shade", "RainTFS", "RainHMS")
wSelected <- select(WeatherDB, fDate, QuantRain = paste0(p.rain), MeanTa = paste0("meanTa", p.treatment))
# CATIE-provided historical data reports number of days with 0.1 mm rain or more. Hence the use of 0.1 as threshold
# Datos de CATIE reportan como días de lluvia cuando hubo 0.1 mm o más, pero el mínimo de lectura es 0.1. O sea, da igual poner != 0 que >= 0.1
wSelected$Rainy <- wSelected$QuantRain >= 0.1
firstday <- min(wSelected$fDate)
wSelected$dayN <- wSelected$fDate - firstday + 1
wSelected <- wSelected[-456,] # last temp is not available

# write relevant weather variables
wfilename <- ifelse(p.treatment == "TFS", "sun_weather", "shade_weather")
write.csv(wSelected, paste0(data_path, "inputs/", wfilename,".csv"))

# plot variables
w_plot<- ggplot(wSelected, aes(x = fDate)) +
  geom_line(aes(y = MeanTa), alpha = 1, size = 0.4) +
  geom_col(aes(y = as.numeric(Rainy) * 40), alpha=0.6, size = 0.05, color = "dodgerblue") +
  geom_col(aes(y = as.numeric(!Rainy) * 40), alpha=0.6, size = 0.05, color = wes_palette("Zissou1",5)[3]) +
  coord_cartesian(ylim = c(10, 35)) +
  xlab("Date") + ylab("Mean Air Temperature (ºC)") +
  #scale_color_manual(values = wes_palette(name = "Zissou1", n=8, type = "continuous")) +
  theme_bw()
w_plot

ggsave(paste0(plots_path, wfilename, ".png"), w_plot, width = 8, height = 4)
ggsave(paste0(plots_path, wfilename, "2.png"), w_plot, width = 12, height = 6)
