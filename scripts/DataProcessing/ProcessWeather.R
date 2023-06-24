library(dplyr)

# Weather data input
WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)

# dir paths
input_data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/input"
fuller_data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/fuller"


# select relevant weather data for "TFS" treatment
wSelected <- select(WeatherDB, Date, QuantRain = RainTFS, MeanTa = meanTaTFS, LW1 = FreqLWTFSwet6to12, LW2 = FreqLWTFSwet12to18) %>%
  mutate(fDate = as.Date(Date, format="%m/%d/%y"),
         LWH = LW1 + LW2,
         Rainy = QuantRain >= 0.1,
         Windy = LWH < 8)
wSelected <- wSelected[-456,] # last temp is not available
firstday <- min(wSelected$fDate)
wSelected$dayN <- wSelected$fDate - firstday + 1
wSelected <- select(wSelected, fDate, QuantRain, LWH, dayN, MeanTa, Rainy, Windy) # "fuller" data
wInput <- select(wSelected, dayN, MeanTa, Rainy, Windy) # input data

extrarows <- filter(wSelected, fDate > as.Date("2017-07-24"), fDate < as.Date("2018-01-04"))
extrarows$fDate <- extrarows$fDate + difftime("2018-01-01", "2017-01-01", units = "days")
longerwSelected <- bind_rows(wSelected, extrarows)
longerwSelected$dayN <- longerwSelected$fDate - firstday + 1
longerwInput <- select(longerwSelected, dayN, MeanTa, Rainy, Windy)

# write data files
if (writefiles) {
  write.csv(wSelected, file.path(fuller_data_path, "fuller_weather.csv"), row.names = F)
  write.csv(wInput, file.path(input_data_path, "weather.csv"), row.names = F)
  write.csv(longerwSelected, file.path(fuller_data_path, "rep_fuller_weather.csv"), row.names = F)
  write.csv(longerwInput, file.path(input_data_path, "rep_weather.csv"), row.names = F)
}
