library(dplyr)
library(purrr)
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

correct.na <- function(total, spore) {
  if(is.na(total) & !is.na(spore) & spore != 0) {
    # equation from LinearRegressions.R
    total = spore * 1.5 + 0.014
  }
  return(total)
}
Correct.NA <- Vectorize(correct.na, vectorize.args = c("total", "spore"))

#Plots (treatments): TFSSF, TMSSF, AMSSF, HMSSF
#t.plot = "TFSSF"
plot_rust_data <- function(t.plot = "TFSSF") {
  #file names and paths
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

  
  ### Plotting incidence at plant-branch level (because branches change every 8 weeks)
  infs <- filter(treatment, WasInfected == 1) %>% select(fDate, Plant) %>% distinct()
  notinfs <- filter(treatment, WasInfected == 0) %>% select(fDate, Plant) %>% distinct()
  
  remNotInfs <- setdiff(notinfs, infs)
  
  infsAndNotInfs <- bind_rows(infs, remNotInfs, .id = "inf") %>% mutate(WasInfected = if_else(inf == "1", 1, 0))
  
  countingPlants <- group_by(infsAndNotInfs, fDate, WasInfected) %>%
    count(fDate, WasInfected) 
  
  incidencePlants <- ggplot(data = countingPlants,
                      aes(x = fDate, y = n, color = as.factor(WasInfected), fill = as.factor(WasInfected))) +
    geom_col(position = "stack") +
    labs(x = "Date", y = "Plant Number", color = "Infected", fill = "Infected")
  incidencePlants
  ggsave(paste0(plots_path, "Plant Incidence",".png"), incidencePlants, width = 6, height = 3)
  
  
  # Get first 25 recorded lesions
  first.25 <- subset(treatment, Lesion <= 25)
  #%>%
  #slice_max(NumArea, n=25) #select only the 25 rusts with the largest areas
  #######
  ## !! PROBLEM !! (Solved)
  ## By selecting the 25 largest each date, we may be losing consistency. Better to pick the first 25
  ## that were id'd and follow them
  ## slice_min(leaf.id, n=25) ??
  #######
  
  ## To get av. areas:
  # filter for infected leaves
  inf.treat <- subset(first.25, Infected==1)
  # checking that there are no duplicate rust.ids
  # ttt <- aggregate(inf.treat$fDate, list(inf.treat$rust.id), function(x) {max(x) - min(x)})
  # plot(ttt)
  
  
  
  # calculate age of each lesion
  ages.treat <- lesion.age(inf.treat)
  
  # sum and then average areas for each leaf
  sum.by.leaf <- group_by(ages.treat, fDate, first.found, n.week, leaf.id) %>%
    summarise(count.n=n(),
              sumArea = sum(CorrectedArea, na.rm = TRUE),
              .groups = "drop_last")
  av.through.leaves <- summarise(sum.by.leaf,
                                 total.rust.n = sum(count.n),
                                 av.sum.leaf = mean(sumArea),
                                 max.sum.leaf = max(sumArea))
  
  # sum and then average areas for each branch
  av.areas.by.branch <- group_by(ages.treat, fDate, first.found, n.week, branch.id) %>%
    summarise(count.n=n(),
              #av.area.branch.int = mean(CorrectedArea, na.rm = T),
              sum.area.branch.int = sum(CorrectedArea, na.rm = T),
              .groups = "drop_last")
  av.through.branches <- summarise(av.areas.by.branch.int,
                                   total.rust.n = sum(count.n),
                                   #av.area.branch = mean(av.area.branch.int),
                                   av.sum.branch = mean(sum.area.branch.int),
                                   max.sum.branch = max(sum.area.branch.int))
  
  # just average areas
  av.areas <- group_by(ages.treat, fDate, first.found) %>%
    summarise(total.rust.n = n(),
              av.area = mean(CorrectedArea, na.rm = T),
              max.area = max(CorrectedArea, na.rm = T),
              dayN = mean(dayN),
              n.week = mean(n.week))
  
  # join dataframes
  rust.areas <- full_join(av.areas, av.through.leaves) %>%
    full_join(av.through.branches) %>%
    select(fDate, first.found, n.week, dayN, total.rust.n, av.area, av.sum.leaf, av.sum.branch, max.area, max.sum.leaf, max.sum.branch)
  
  # looking at plots, some problematic values were found when # rusts was 1
  rust.areas <- filter(rust.areas, !total.rust.n == 1 | !(is.na(av.area) | av.area < 0.005))
  
  # save csv
  write.csv(rust.areas, paste0(data_path, "compare/", areas.name, "_Corrected",".csv"))
  
   # plot them
  plot1 <- ggplot(av.areas,
                  aes(fDate, av.area, color=first.found, group=first.found)) +
    geom_point() + geom_line() +
    xlab("Date") + ylab("Average Latent Area (cm)") + labs(colour = "First Observed") +
    theme_bw()
  plot1
  ggsave(paste0(plots_path,areas.name,".png"), plot1,
         width = 12, height = 6)
  
  plot1.bis <- ggplot(rust.areas,
                      aes(fDate, av.area, color=as.factor(n.week), group=first.found)) +
    geom_point() + geom_line() +
    xlab("Date") + ylab("Average Latent Area (cm)") + labs(colour = "Age (weeks)") +
    theme_bw()
  plot1.bis
  ggsave(paste0(plots_path,areas.name,"bis.png"), plot1.bis,
         width = 12, height = 6)
  
  plot1.tris <- ggplot(rust.areas,
                       aes(fDate, av.sum.leaf, color = n.week, group = first.found)) +
    geom_point() + geom_line() +
    xlab("Date") + ylab("Average Latent Area (cm)") + labs(colour = "Age") +
    theme_bw()
  plot1.tris
  ggsave(paste0(plots_path,areas.name,"tris.png"), plot1.bis,
         width = 12, height = 6)
  
  ggplot(inf.treat[inf.treat$fDate < "2017-07-10",],
         aes(fDate, NumArea)) +
    geom_line(aes(color = rust.id), show.legend = FALSE)
  
  ggplot(ages.treat[ages.treat$first.found == "2018-04-10",],
         aes(fDate, NumArea)) +
    geom_line(aes(color = rust.id), show.legend = FALSE)
  
  #######
  # investigating the effect of having taken only Infected == 1
  # SOLVED: can ignore all this section, leaving for future reference
  alt.ages.treat <- lesion.age(first.25) 
  
  whattheheck <- subset(alt.ages.treat, Infected == 0 & !is.na(NumArea) & NumArea > 0) # 0
  whattheheck2 <- subset(alt.ages.treat, Infected == 1 & !is.na(NumArea) & NumArea == 0) # 0
  # take away: whenever area is 0 (how can you see the lesion when its area is 0?), infected is left as 0
  whattheheck3 <- subset(alt.ages.treat, Infected == 0 & n.week > 7)
  # lesions with area = 0 are recorded even for n.weeks = 8. Leads to assume these may be other types of lesions/their absence of growth means their contribution to prod decline is negligible => OK to ignore Infected = 0
  # however, it is necessary to add this subset because age estimations may be shifted for some rust.ids
  
  non.infected <- subset(alt.ages.treat, Infected == 0 & rust.id %in% ages.treat$rust.id & !is.na(CorrectedArea) & n.week == 0 & Lesion <= 25)
  infected <- subset(alt.ages.treat, Infected == 1 & Lesion <= 25)
  
  growing.rusts <- bind_rows(non.infected, infected)
  
  # sum and then average areas for each leaf
  sum.by.leaf2 <- group_by(growing.rusts, fDate, first.found, n.week, leaf.id) %>%
    summarise(count.n=n(),
              sumArea = sum(CorrectedArea, na.rm = TRUE),
              .groups = "drop_last")
  av.through.leaves2 <- summarise(sum.by.leaf,
                                 total.rust.n = sum(count.n),
                                 av.sum.leaf = mean(sumArea),
                                 max.sum.leaf = max(sumArea))
  
  # sum and then average areas for each branch
  av.areas.by.branch2 <- group_by(growing.rusts, fDate, first.found, n.week, branch.id) %>%
    summarise(count.n=n(),
              #av.area.branch.int = mean(CorrectedArea, na.rm = T),
              sum.area.branch.int = sum(CorrectedArea, na.rm = T),
              .groups = "drop_last")
  av.through.branches2 <- summarise(av.areas.by.branch.int,
                                   total.rust.n = sum(count.n),
                                   #av.area.branch = mean(av.area.branch.int),
                                   av.sum.branch = mean(sum.area.branch.int),
                                   max.sum.branch = max(sum.area.branch.int))
  
  # just average areas
  av.areas2 <- group_by(growing.rusts, fDate, first.found) %>%
    summarise(total.rust.n = n(),
              av.area = mean(CorrectedArea, na.rm = T),
              max.area = max(CorrectedArea, na.rm = T),
              dayN = mean(dayN),
              n.week = mean(n.week))
  
  # join dataframes
  rust.areas2 <- full_join(av.areas2, av.through.leaves2) %>%
    full_join(av.through.branches2) %>%
    select(fDate, first.found, n.week, dayN, total.rust.n, av.area, av.sum.leaf, av.sum.branch, max.area, max.sum.leaf, max.sum.branch)
  
  # And... this actually creates a mess.
  # eg rust.id 42867.19.B1.D.1. At day 1, infected = 0, area = 0, n.week = 0. Then nothing comes up until n.week = 4, where area is 0.025
  # New hypothesis: the lesions listed at each day 1, out of which none have infected == 1 or area != 0, are there for another use. The total final count (at the end of the 8 weeks) of the lesions is reported in day 1 for some reason, but for my purposes I can ignore all this
  ##
  ##################
  
  
  
  ## To get n. lesions:
  
  # pre.n.lesions <- group_by(by.leaf, fDate, leaf.id) %>% 
  #   summarise(count = n()) 
  alt.n.lesions <- group_by(alt.ages.treat, fDate, leaf.id) %>% 
    summarise(count = n(), dayN = mean(dayN), nlesion = max(Lesion))
  %>% #count lesions per leaf
    # mutate(occ.sites = count / 25) %>%
    summarise(dayN = mean(dayN), total.n = sum(count), mean.n = mean(count), sumNLesion = sum(nlesion), meanNLesion = mean(nlesion))
    
  n.lesions <- group_by(ages.treat, fDate, leaf.id) %>% 
    summarise(count = n(), dayN = mean(dayN)) %>% #count lesions per leaf
    # mutate(occ.sites = count / 25) %>%
    summarise(dayN = mean(dayN), total.n = sum(count), mean.n = mean(count))
  saveRDS(n.lesions, paste0(data_path, lesions.name,".rds"))
  write.csv(n.lesions, paste0(data_path, "compare/", lesions.name,".csv"))
  
  
  
  

  
  plot2 <- ggplot(n.lesions,
                  aes(fDate, mean.occ)) + geom_point() + geom_line() +
    xlab("Date") + ylab("Number of Lesions per Leaf") + theme_bw()
  plot2
  ggsave(paste0(plots_path,lesions.name,".png"), plot2,
         width = 6, height = 3)
}






plot_weather_data <- function(t.plot) {
  #t.plot options: "Sun" or "Shade". Both are plots in Turrialba 
  
  data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
  plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"
  treat.name <- ifelse(t.plot == "Sun", "Tur_Sun", "Tur_Shade")
  w.name <- paste0(treat.name,"_Weather")
  temp.name <- as.name(paste0("meanTa", ifelse(t.plot=="Sun", "TFS", "TMS")))
  
  # Turrialba full sun
  w.treat <- select(WeatherDB, fDate, RainTFS, Rainy, !!temp.name)
  w.treat$dayN <- w.treat$fDate - firstday
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
    geom_line(aes(y = !!temp.name)) +
    geom_col(aes(y = as.numeric(Rainy) * 30), alpha=0.3) +
    coord_cartesian(ylim = c(15, 30)) +
    xlab("Date") + ylab("Mean Air Temperature (ºC)") +
    theme_bw()
  
  plot.w1
  
  ggsave(paste0(plots_path, w.name, ".png"), plot.w1,
         width = 6, height = 3)
}

rds_to_csv <- function(filename) {
  data_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
  file_path <- paste0(data_path, filename)
  rds <- readRDS(file_path)
  write.csv(rds, file = gsub('rds$','csv', file_path))
}

convert_rds_files <- function() {
  listoffiles <- list.files("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/", pattern = ".rds")
  for(efile in listoffiles) {
    rds_to_csv(efile)
  }
}


###############################################################
# Figuring out which days were data taken
###

chosenTreatment <- "TFSSF"

PlantDB$fDate <- as.Date(PlantDB$DateLabel, format="%m/%d/%y")
wDates <- as.Date(WeatherDB$Date, format="%m/%d/%y")

rSelected <- subset(RustDB, Treatment == chosenTreatment)
rDates <- as.Date(rSelected$Date, format="%m/%d/%y")
inspPlants <- rSelected$Plant
pSelected <- subset(PlantDB, Plant %in% inspPlants)
pDates <- as.Date(pSelected$DateLabel, format="%m/%d/%y")

firstday <- min (wDates)

rDays <- rDates - firstday
pDays <- pDates - firstday

whenToCollect <- sort(unique(c(rDays,pDays)))[2:62] # leaving out 2017-05-11 because only partial data was collected. See line # 387
write.csv(whenToCollect, paste0(data_path, "inputs/whentocollect.csv"))

## Plotting data collection dates
inspDates <- data.frame("date" = unique(rDates), "who" = "Rust", "val" = 1)
addthis <- data.frame( "date" = unique(pDates), "who" = "Plant", "val" = -1)

inspDates <- bind_rows(inspDates, addthis)

graphicDates <- ggplot(data = inspDates,
                     aes(x = date, y = val, group = who)) +
  geom_col(aes(fill = who, color = who)) + ylim(-4, 4) +
  labs(x = "Data Collection Date", y = "", fill = "Where", color = "Where") +
  geom_text(aes(label = date, angle = 90), check_overlap = F, nudge_x = -1.6, nudge_y = 0.6)
graphicDates
ggsave(paste0(plots_path, "Data Collection Dates2", ".png"), graphicDates, width = 12, height = 6)

####
## Producing csv of plant productivity.
## Prob should find max productivity and use it to normalize. Hopefully max productivity is found in min rust infection?

rSelected$fDate <- as.Date(rSelected$Date, format="%m/%d/%y")
rSelected$numArea <- as.numeric(as.character(rSelected$TotalAreaLesion))

pSelected$fDate <- as.Date(pSelected$DateLabel, format="%m/%d/%y")
pSelected$fDate <- case_when(pSelected$fDate == "2017-05-11" ~ as.Date("2017-05-12"),
                             TRUE ~ as.Date(pSelected$fDate)) # correction is necessary because branch values are pooled
pSelected$BranchID <- as.factor(paste(pSelected$Plant, pSelected$Branch, sep = "."))
pSelected <- mutate(pSelected, SampleGroup = if_else(Plant <= 36, "A", "B"))

# checking that all the plants assessed for rust are present in the list of plants assessed for coffee prod
unique(pSelected$Plant) %in% unique(rSelected$Plant)
unique(rSelected$Plant) %in% unique(pSelected$Plant)

sumNodes <- group_by(pSelected, fDate, Plant) %>%
  summarise(sumPlantNodes = sum(BranchFruitNodes), sumPlantFruits = sum(BranchFruits), sumNodesNodes = sum(Node, na.rm = T))

plantNodes <- ggplot(sumNodes, aes(x = fDate,
                                   y = sumPlantNodes,
                                   group = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant))) + 
  geom_line(aes(color = as.factor(Plant))) +
  labs(x = "Date", y = "Plant Nodes", color = "Plant ID")

ggsave(paste0(plots_path, "Sum Nodes", ".png"), plantNodes, height = 6, width = 12)

plantFruits <- ggplot(sumNodes, aes(x = fDate,
                                    y = sumPlantFruits,
                                    group = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant))) + 
  geom_line(aes(color = as.factor(Plant))) +
  labs(x = "Date", y = "Plant Fruits", color = "Plant ID")

ggsave(paste0(plots_path, "Sum Fruits", ".png"), plantFruits, height = 6, width = 12)

plantFolNodes <- ggplot(sumNodes,
                        aes(x = fDate, y = sumNodesNodes, group = as.factor(Plant))) +
  geom_point(aes(color= as.factor(Plant))) +
  geom_line(aes(color= as.factor(Plant))) +
  labs(x = "Date", y = "Sum Foliar Nodes", color = "Plant ID")

ggsave(paste0(plots_path, "Sum Foliar Nodes", ".png"), plantFolNodes, height = 6, width = 12)

meanNodesandFruits <- summarise(sumNodes,
                       meanPlantNodes = mean(sumPlantNodes),
                       meanPlantFruits = mean(sumPlantFruits),
                       meanFoliarNodes = mean(sumNodesNodes), # assuming this. What other type of node can there be?
                       n = n())
meanNodesandFruits$dayN <- meanNodesandFruits$fDate - firstday

write.csv(meanNodesandFruits, paste0(data_path, "compare/", treat.name, "_CoffeProd.csv"))



## Relate productivity to rust
summBranch <- group_by(rSelected, fDate, Plant, Branch) %>%
  summarize(sumArea = sum(CorrectedArea, na.rm = T), meanArea = mean(CorrectedArea, na.rm = T))

summBranch <- group_by(inf.treat, fDate, Plant, Branch) %>%
  summarise(count.n=n(),
            sum.branch = sum(CorrectedArea, na.rm = T),
            .groups = "drop_last") %>%
  summarise(total.rust.n = sum(count.n),
            av.sum.branch = mean(sum.branch),
            max.sum.branch = max(sum.branch))

earlyStages <- mutate(summBranch,
                      stage = "Early",
                      branchCycle = if_else(fDate < "2017-07-06", 1,
                                            if_else(fDate < "2017-09-06", 2,
                                                    if_else(fDate < "2017-11-08", 3, 4)))) %>%
  filter(fDate == "2017-05-18" | fDate == "2017-07-18" |  fDate == "2017-09-19" | fDate == "2017-11-21")


lateStages <- mutate(summBranch,
                     stage = "Late",
                     branchCycle = if_else(fDate < "2017-07-06", 1,
                                           if_else(fDate < "2017-09-06", 2,
                                                   if_else(fDate < "2017-11-08", 3, 4)))) %>%
  filter(fDate == "2017-07-05" | fDate == "2017-09-05" | fDate == "2017-11-07" | fDate == "2017-12-12")

earlyAndLate <- bind_rows(earlyStages,lateStages)

firstSet <- subset(sumNodes, fDate < "2018-01-01")

sumNodes2 <- mutate(firstSet,
                    branchCycle = if_else(fDate < "2017-07-06", 1,
                                                    if_else(fDate < "2017-09-06", 2,
                                                            if_else(fDate < "2017-11-08", 3, 4))))

prodAndRust <- left_join(sumNodes2, earlyAndLate, by = c("Plant", "branchCycle"))

ggplot(prodAndRust, aes(x = sumPlantNodes,
                        y = av.sum.branch,
                        group = stage)) +
  geom_point(aes(color = stage))
ggplot(prodAndRust, aes(x = sumPlantFruits,
                        y = av.sum.branch,
                        group = stage)) +
  geom_point(aes(color = stage))
ggplot(prodAndRust, aes(x = sumNodesNodes,
                        y = av.sum.branch,
                        group = stage)) +
  geom_point(aes(color = stage))
ggplot(prodAndRust, aes(x = sumPlantNodes,
                        y = max.sum.branch,
                        group = stage)) +
  geom_point(aes(color = stage))
ggplot(prodAndRust, aes(x = sumPlantFruits,
                        y = max.sum.branch,
                        group = stage)) +
  geom_point(aes(color = stage))
ggplot(prodAndRust, aes(x = sumNodesNodes,
                        y = max.sum.branch,
                        group = stage)) +
  geom_point(aes(color = stage))


summLeaf <- group_by(rSelected, fDate, Plant, Branch, RightLeftLeaf) %>%
  summarize(NLesions = max(Lesion), Infected = mean(Infected), countLesions = n())

allByBranch <- left_join(pSelected, summBranch)



plantnodes.time <- ggplot(pSelected, aes(x = fDate, y = PlantFruitNodes, group = Plant)) +
  geom_line(aes(color = Plant))
plantnodes.time

branchnodes.time <- ggplot(pSelected, aes(x = fDate, y = BranchFruitNodes, group = Branch)) +
  geom_line(aes(color = Branch)) + geom_point()
branchnodes.time

branchfruits.branchnodes <- ggplot(pSelected, aes(x = BranchFruitNodes, y = BranchFruits, group = Plant)) +
  geom_line(aes(color = Plant)) + geom_point(aes(color = Plant))
branchfruits.branchnodes


plot(pSelected$Plant, )

range(pSelected$fDate)




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






