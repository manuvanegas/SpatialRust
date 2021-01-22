library(dplyr)
library(ggplot2)

RustDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoRoya.csv", h=T)

# Weather input. Getting rainy days and daily mean temp
WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)
WeatherDB$fDate <- as.Date(WeatherDB$Date, format="%m/%d/%y")
WeatherDB$Rainy <- WeatherDB$RainTFS!=0

#Plots (treatments): TFSSF, TMSSF, AMSSF, HMSSF

plot_rust_data <- function(t.plot) {
  #file names and paths
  data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
  plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"
  treat.name <- ifelse(t.plot == "TFSSF", "Tur_Sun", ifelse(t.plot == "TMSSF", "Tur_Shade", "Non_Tur"))
  areas.name <- paste0(treat.name,"_AvAreas")
  lesions.name <- paste0(treat.name,"_NLesions")
  
  
  #subset treatment data
  treatment <- subset(RustDB, Treatment == t.plot)
  treatment$NumArea <- as.numeric(as.character(treatment$TotalAreaLesion))
  treatment$fDate <- as.Date(treatment$Date, format="%m/%d/%y")
  #add ids
  treatment$branch.id <- as.factor(paste(treatment$Plant, treatment$Branch, sep = "."))
  treatment$leaf.id <- as.factor(paste(treatment$Plant, treatment$Branch, treatment$RightLeftLeaf, sep = "."))
  treatment$rust.id <- as.factor(paste(treatment$Plant, treatment$Branch, treatment$RightLeftLeaf, treatment$Lesion, sep = "."))
  # filter for infected leaves
  inf.treat <- subset(treatment, Infected==1)
  # check that there are no duplicate rust.ids
  ttt <- aggregate(inf.treat$fDate, list(inf.treat$rust.id), function(x) {max(x) - min(x)})
  plot(ttt)
  
  
  
  #treatment data with lesion a.ges
  ages.treat <- lesion.age(inf.treat)
  
  #aaa <- aggregate(a.tu.sun$NumArea, list(a.tu.sun$n.week, a.tu.sun$first.found), function(x) {mean(x, na.rm = T)})
  #ggplot(aaa, aes(Group.1, x, color=Group.2, group=Group.2)) + geom_point() + geom_line() 
  
  by.leaf <- group_by(ages.treat, fDate, leaf.id) %>%
    slice_max(NumArea, n=25) #select only the 25 rusts with the largest areas
  
  av.areas <- group_by(by.leaf, fDate, first.found) %>%
    summarise(count=n(), m.NumArea = mean(NumArea, na.rm = T)) %>%
    mutate(n.weeks = round(difftime(fDate, first.found, units = "weeks")))
  saveRDS(av.areas, paste0(data_path, areas.name,".rds"))
  
  
  n.lesions <- group_by(by.leaf, fDate, leaf.id) %>% 
    summarise(count = n()) %>% #count lesions per leaf
    # mutate(occ.sites = count / 25) %>%
    summarise(mean.occ = mean(count))
  saveRDS(n.lesions, paste0(data_path, lesions.name,".rds"))
  
  plot1 <- ggplot(av.areas,
                  aes(fDate, m.NumArea, color=first.found, group=first.found)) +
    geom_point() + geom_line() +
    xlab("Date") + ylab("Average Latent Area (cm)") + labs(colour = "First Observed") +
    theme_bw()
  plot1
  ggsave(paste0(plots_path,areas.name,".png"), plot1,
         width = 6, height = 3)
  
  plot1.bis <- ggplot(av.areas,
                  aes(fDate, m.NumArea, color=as.numeric(n.weeks), group=first.found)) +
    geom_point() + geom_line() +
    xlab("Date") + ylab("Average Latent Area (cm)") + labs(colour = "First Observed") +
    theme_bw()
  plot1.bis
  ggsave(paste0(plots_path,areas.name,"bis.png"), plot1.bis,
         width = 6, height = 3)
  
  plot2 <- ggplot(n.lesions,
                  aes(fDate, mean.occ)) + geom_point() + geom_line() +
    xlab("Date") + ylab("Number of Lesions per Leaf") + theme_bw()
  plot2
  ggsave(paste0(plots_path,lesions.name,".png"), plot2,
         width = 6, height = 3)
}



lesion.age <- function(d) {
  d$l.age <- rep_len(0, length.out = length(d$rust.id))
  d$n.week <- rep_len(0, length.out = length(d$rust.id))
  d$first.found <- as.Date(rep_len(0,length(d$rust.id)), origin = "2000-01-01")
  r <- unique(d$rust.id)
  for(rr in r) {
    chunk <- subset(d, rust.id == rr)
    start.d <- min(chunk$fDate)
    d$first.found[d$rust.id == rr] <- start.d
    for(dd in 1:length(chunk$fDate)) {
      d$l.age[d$rust.id == rr & d$fDate == chunk$fDate[dd]] = chunk$fDate[dd] - start.d + 3
      d$n.week[d$rust.id == rr & d$fDate == chunk$fDate[dd]] = round(difftime(chunk$fDate[dd], start.d, units = "weeks"))
    }
  }
  return(d)
}



plot_weather_data <- function(t.plot) {
  
  data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
  plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"
  treat.name <- ifelse(t.plot == "TFSSF", "Tur_Sun", ifelse(t.plot == "TMSSF", "Tur_Shade", "Non_Tur"))
  w.name <- paste0(treat.name,"_Weather")
  
  # Turrialba full sun
  w.treat <- select(WeatherDB, fDate, RainTFS, Rainy, meanTaTFS)
  saveRDS(w.treat, paste0(data_path, w.name, ".rds"))
  
  # w.tu.sun2 <- select(WeatherDB, fDate, RainTFS, Rainy, meanTfmiddleTFS, meanTfmiddleTMS)
  # 
  # plot.w12<- ggplot(w.tu.sun2, aes(x = fDate)) +
  #   geom_line(aes(y = meanTfmiddleTFS), color = "red") +
  #   geom_line(aes(y = meanTfmiddleTMS), color= "blue") +
  #   geom_col(aes(y = as.numeric(Rainy) * 30), alpha=0.3) +
  #   coord_cartesian(ylim = c(15, 30)) +
  #   xlab("Date") + ylab("Mean Air Temperature (ºC)") +
  #   theme_bw()
  # 
  # plot.w12
  
  plot.w1<- ggplot(w.treat, aes(x = fDate)) +
    geom_line(aes(y = meanTaTFS)) +
    geom_col(aes(y = as.numeric(Rainy) * 30), alpha=0.3) +
    coord_cartesian(ylim = c(15, 30)) +
    xlab("Date") + ylab("Mean Air Temperature (ºC)") +
    theme_bw()
  
  plot.w1
  
  ggsave(paste0(plots_path, w.name, ".png"), plot.w1,
         width = 6, height = 3)
}





#########################################
# Code Clippings
#########################################
# 
# # average areas by age, date first found, keeping measurement date.
# av.areas <- group_by(a.tu.sun, n.week, first.found, fDate) %>%
#   filter(!is.na(NumArea)) %>%
#   summarise(m.NumArea = mean(NumArea, na.rm=T), n = n())
# saveRDS(av.areas, "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/Tu_Sun_AvAreas.R")
# 
# 
#   
#   
#   slice_max(NumArea, n=25) %>% select(leaf.id,fDate,first.found,NumArea)
# %>% summarise(count=n())
#   
#   ungroup() %>% group_by(fDate, first.found) %>%
#   
#   
#   
#   summarise(m.NumArea = mean(NumArea, na.rm = T), count = n())
#   
#   summarise(count = n())%>% group_by(fDate, leaf.id)
#   
#   
#   
#   group_by(n.week, first.found) %>%
#   summarise(f.25 = if_else(n<=25,
#                           mean(NumArea, na.rm = T),
#                           mean(sort(NumArea, decreasing = T)[1:25], na.rm = T)))
#   
#   group_by(a.tu.sun, n.week, fDate, leaf.id) %>%
#   filter(!is.na(NumArea)) %>%
#   summarise(m.NumArea = mean(NumArea, na.rm=T), first.found=unique(first.found), n = n(), ff = first.25(NumArea)) %>%
#   summarise(m.NumArea = mean(ff), n=sum(n), fdate=unique(fDate), first.found=unique(first.found))
# 
# 
# first.25 <- function(x) {
#   if(length(x) > 25 ) {
#     return(mean(sort(x, decreasing = T)[1:25], na.rm = T))
#   } else {
#     return(mean(x, na.rm = T))
#   }
# }
# 
# 
# 
# 
# 
# 
# n.lesions <- group_by(a.tu.sun, fDate, leaf.id) %>%
#   summarise(n = n()) %>% #count lesions/leaf each date
#   mutate(max.n.lesions = ifelse(n < 25, n, 25)) %>% #cap to maximum of 25/leaf
#   ungroup() %>%
#   group_by(fDate) %>%
#   summarise(counts = sum(max.n.lesions))
# 
# tryy<-count(a.tu.sun, fDate)
# 
# barplot(table(a.tu.sun$fDate))
# 
# 
# 
# 
# 
# # plot(aaa)
# # barplot(table(a.tu.sun$n.week))
# 
# 
# # jul11<- subset(tsu, fDate=="2017-07-11")
# # 
# # sum(aa$Fallen)
# # 
# # tt<-table(tu.sun$rust.id)
# # 
# # agg <- aggregate(tu.sun$NumArea, list(tu.sun$fDate), function(x) {mean(x, na.rm = T)})
# # plot(agg)
# # lines(agg)
# # 
# # n.agg <- aggregate(n.tu.sun$NumArea, list(n.tu.sun$fDate), function(x) {mean(x, na.rm=T)})
# # 
# # #27.T1.D.1
# # #has 9 samples at the beggining and then 5 more starting mid-Dec
# # plot(tu.sun$branch.id[grepl("27",tu.sun$branch.id)],tu.sun$fDate[grepl("27",tu.sun$branch.id)])
# # plot(tu.sun$fDate[tu.sun$rust.id=="27.T1.D.1"],tu.sun$NumArea[tu.sun$rust.id=="27.T1.D.1"])
# # 
# # barplot(table(tu.sun$fDate))






