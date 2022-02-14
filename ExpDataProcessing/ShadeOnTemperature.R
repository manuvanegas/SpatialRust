WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)
WeatherDB$fDate <- as.Date(WeatherDB$Date, format="%m/%d/%y")
WeatherDB$Rainy <- WeatherDB$RainTFS != 0


tempDiff <- select(WeatherDB, c(88, 5, 25, 11, 31, 15, 35, 19, 39)) %>%
  mutate(dTa = meanTaTFS - meanTaTMS,
         dTbottom = meanTfbottomTFS - meanTfbottomTMS,
         dTmiddle = meanTfmiddleTFS - meanTfmiddleTMS,
         dTtop = meanTftopTFS - meanTftopTMS) 

allDiffs <- tibble("4" = WeatherDB[, 4] - WeatherDB[, (4 + 20)])
for (temp in 5:23) {
  diffs <- WeatherDB[, temp] - WeatherDB[, (temp + 20)]
  allDiffs[as.character(temp)] <- diffs
}

names(allDiffs) <- c("minTa", "meanTa", "maxTa", "amplTa",
                     "minHR", "amplHR",
                     "minTb", "meanTb", "maxTb", "amplTb",
                     "minTm", "meanTm", "maxTm", "amplTm",
                     "minTt", "meanTt", "maxTt", "amplTt",
                     "LW1", "LW2")

# leaf wetness and occurrence of rain
WeatherDB$LWtotTFS <- WeatherDB$FreqLWTFSwet6to12 + WeatherDB$FreqLWTFSwet12to18
WeatherDB$LWtotTMS <- WeatherDB$FreqLWTMSwet6to12 + WeatherDB$FreqLWTMSwet12to18
mean(WeatherDB$LWtotTFS - WeatherDB$LWtotTMS)

LW_rain <- group_by(WeatherDB, Rainy) %>%
  summarise(TFS = mean(LWtotTFS), TMS = mean(LWtotTMS))

