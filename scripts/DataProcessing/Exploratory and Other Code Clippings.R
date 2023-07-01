# Commented out blocks were older things

#file paths
# data_path <- "~/Doc uments/ASU/Coffee Rust/SpatialRust/data/exp_pro/"
# plots_path <- "~/Documents/ASU/Coffee Rust/SpatialRust/plots/Exp_Data/"

# WeatherDB <- read.csv("~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_raw/MonitoreoClima.csv", h=T)
# WeatherDB$fDate <- as.Date(WeatherDB$Date, format="%m/%d/%y")
# p.treatment <- ifelse(SunOrShade == "Sun", "TFS", "TMS") 
# wSelected <- select(WeatherDB, fDate, QuantRain = "RainTFS", MeanTa = paste0("meanTa", p.treatment))
# first day of experiment (to determine day # for the rest)
# firstday <- min(wSelected$fDate)


# Figuring out if any cycle should be dropped
# 5th sampling cycle has very few observations (see final section about sampling patterns)
# sun_treatm_less <- remove.cycle(sun_treatm, 5) # really necessary?
# shade_treatm_less <- remove.cycle(shade_treatm, 5)
srustspercycle <- sun_treatm %>%
  group_by(branch.cycle) %>%
  summarise(nr = n_distinct(rust.id),
            nleaf = n_distinct(leaf.id),
            np = n_distinct(Plant))
hrustspercycle <- shade_treatm %>%
  group_by(branch.cycle) %>%
  summarise(nr = n_distinct(rust.id),
            nleaf = n_distinct(leaf.id),
            np = n_distinct(Plant))

sleavesall <- RustDB %>%
  filter(Treatment == "TFSSF") %>%
  mutate(
    fdate = as.Date(Date, format = "%m/%d/%y"),
    branch.id = as.factor(paste(Plant, Branch, sep = ".")),
    leaf.id = as.factor(paste(Plant, Branch, RightLeftLeaf, sep = ".")),
    dayn = fdate - firstday + 1) %>%
  # branch.cycle(cycle_dates) %>%
  group_by(branch.id) %>%
  mutate(first.samp = min(dayn),
         last.samp = max(dayn))

splantspercycle <- sleavesall %>% group_by(first.samp, Plant) %>% summarise()
spGroup1 <- splantspercycle %>% filter(first.samp == cycle_dates[1]) %>% pull(Plant)
spGroup2 <- splantspercycle %>% filter(first.samp == cycle_dates[5]) %>% pull(Plant)
spGroup3 <- splantspercycle %>% filter(first.samp == cycle_dates[6]) %>% pull(Plant)

sun_treatm %>% group_by(first.samp, Plant) %>% summarise(n = n()) %>% plot()
sleavesall %>% group_by(first.samp, Plant) %>% summarise() %>% plot()

sleavespercycle <- sleavesall %>%
  group_by(branch.cycle) %>%
  summarise(nleaf = n_distinct(leaf.id),
            np = n_distinct(Plant))
sleavesperdate <- sleavesall %>%
  group_by(dayn,fdate) %>%
  summarise(nleaf = n_distinct(leaf.id),
            np = n_distinct(Plant))

hleavesall <- RustDB %>%
  filter(Treatment == "TMSSF") %>%
  mutate(
    fdate = as.Date(Date, format = "%m/%d/%y"),
    branch.id = as.factor(paste(Plant, Branch, sep = ".")),
    leaf.id = as.factor(paste(Plant, Branch, RightLeftLeaf, sep = ".")),
    dayn = fdate - firstday + 1) %>%
  # branch.cycle(cycle_dates,firstday) %>%
  group_by(branch.id) %>%
  mutate(first.samp = min(dayn),
         last.samp = max(dayn),
         cyclelength = last.samp - first.samp)
hplantspercycle <- hleavesall %>% group_by(first.samp, Plant) %>% summarise(cyclelength = max(cyclelength))
hpGroup1 <- hplantspercycle %>% filter(first.samp == cycle_dates[1]) %>% pull(Plant)
hpGroup2 <- hplantspercycle %>% filter(first.samp == cycle_dates[5]) %>% pull(Plant)
hpGroup3 <- hplantspercycle %>% filter(first.samp == cycle_dates[6]) %>% pull(Plant)
cyclelengths <- hplantspercycle %>%
  filter(cyclelength > 50, cyclelength < 60) %>%
  group_by(first.samp) %>%
  summarise(clength = mean(cyclelength))

hleavespercycle <- hleavesall %>%
  group_by(branch.cycle) %>%
  summarise(n = n_distinct(leaf.id),
            np = n_distinct(Plant))
hleavesperdate <- hleavesall %>%
  group_by(dayn,fdate) %>%
  summarise(nleaf = n_distinct(leaf.id),
            np = n_distinct(Plant))

clean_starts <- cycle_dates
clean_ends <- c(cycle_dates[-1],455)
messy_starts <- c(18,78,141,204,259,288)
messy_ends <- c(77,140,203,220, 286,)
cycstarts <- function(v){
  findInterval(v, cycle_dates)
}
cycends <- function(v){
  findInterval(v, cycle_dates, left.open = T)
}

snotorphans <- sun_treatm %>%
  group_by(branch.id) %>%
  mutate(last.samp = max(dayn),
         cycstarts = findInterval(last.samp, cycle_dates),
         cycends = findInterval(last.samp, cycle_dates, left.open = T)
  ) %>%
  filter(cycstarts > 4, cycends > 4, cycstarts != cycends) %>%
  summarise(cycends,
            cycstarts,
            n = n()) %>%
  pull(cycstarts) %>% unique()


###################


sunoccuperage2 <- sun_treatm %>%
  filter(sampling.week == 8) %>% 
  group_by(fdate,dayn) %>%
  mutate(
    surv.leaves = n_distinct(leaf.id)) %>% 
  group_by(fdate, dayn, age) %>% 
  summarise(
    surv.leaves = mean(surv.leaves),
    totlesions = mean(n()),
    totleaves = mean(leaves.samp),
    occupancy = totlesions / (totleaves * 25),
    effocc = totlesions / (surv.leaves * 25))

ggplot(occuperage, aes(fdate, occupancy, group = age, color = as.factor(age), fill = as.factor(age))) +
  geom_col()

ggplot(sunoccuperage2, aes(fdate, occupancy, group = age, color = as.factor(age), fill = as.factor(age))) +
  geom_col() +
  coord_cartesian(ylim = c(0,0.35))

occuperage <- shade_treatm %>%
  filter(sampling.week == 8) %>% 
  group_by(fdate, dayn, age) %>% 
  summarise(occupancy = mean(n() / (leaves.samp*25)))

ggplot(occuperage, aes(fdate, occupancy, group = age, color = as.factor(age), fill = as.factor(age))) +
  geom_col()

shoccuperage2 <- shade_treatm %>%
  filter(sampling.week == 8) %>% 
  group_by(fdate,dayn) %>%
  mutate(
    surv.leaves = n_distinct(leaf.id)) %>% 
  group_by(fdate, dayn, age) %>%
  summarise(
    surv.leaves = mean(surv.leaves),
    totlesions = mean(n()),
    totleaves = mean(leaves.samp),
    occupancy = totlesions / (totleaves * 25),
    effocc = totlesions / (surv.leaves * 25))

ggplot(shoccuperage2, aes(fdate, occupancy, group = age, color = as.factor(age), fill = as.factor(age))) +
  geom_col() +
  coord_cartesian(ylim = c(0,0.35))

occuperage <- sun_treatm %>%
  filter(dayn %in% cycle_dates) %>% #,
  # dayn == last.samp) %>%
  group_by(fdate, dayn, age) %>%
  summarise(count = n())



hist(n_lesions$nl[n_lesions$dayn == n_lesions %>% group_by(branch.cycle) %>% summarise(d1cycle = min(dayn)) %>% pull(d1cycle)])

###################

areas_per_ageforplot <- sun_treatm %>% 
  group_by(dayn, fdate, firstfound, age) %>%
  summarise(median.area = median(num.area, na.rm = T),
            # q1.area = quantile(num.area, 1/4, na.rm = T),
            # q3.area = quantile(num.area, 3/4, na.rm = T),
            median.spores = median(spore.area, na.rm = T),
            # q1.spores = quantile(spore.area, 1/4, na.rm = T),
            # q3.spores = quantile(spore.area, 3/4, na.rm = T),
            count = n(),
            dist.area = n_distinct(num.area, na.rm = T),
            dist.spores = n_distinct(spore.area, na.rm = T),
            areanas = sum(is.na(num.area)),
            sporenas = sum(is.na(spore.area))) %>%
  filter(count > 2) # getting rid of medians over just one observation

lesion_per_age <- ungroup(areas_per_ageforplot) 

spore_per_age <- filter(areas_per_ageforplot, dist.spores > 1 | (sporenas / count) < 0.7) %>%
  ungroup() 




###############################################################
## Figuring out rust sampling patterns
###############################################################
shade_rsel <- subset(RustDB, Treatment == "TMSSF" & Lesion <= 25 & (Infected == 1 | Fallen == 1))
shade_rsel$num.area <- as.numeric(as.character(shade_rsel$TotalAreaLesion))
shade_rsel$fdate <- as.Date(shade_rsel$Date, format="%m/%d/%y")
shade_rsel$fdate <- case_when(shade_rsel$fdate == "2017-05-11" ~ as.Date("2017-05-12"),
                              TRUE ~ as.Date(shade_rsel$fdate))
shade_rsel$day.n <- shade_rsel$fdate - firstday + 1

ggplot(data = shade_rsel, aes(x = fdate, y = num.area, group = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant)))
plot(shade_rsel$fdate, shade_rsel$Plant)

plant_ids_shade <-distinct_at(shade_rsel, c("day.n", "Plant"))
plant_ids_shade_plot <- ggplot(plant_ids_shade, aes(x = day.n, y = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant))) +
  geom_vline(aes(xintercept = cycle_dates[1])) +
  geom_vline(aes(xintercept = cycle_dates[2])) +
  geom_vline(aes(xintercept = cycle_dates[3])) +
  geom_vline(aes(xintercept = cycle_dates[4])) +
  geom_vline(aes(xintercept = cycle_dates[5])) +
  geom_vline(aes(xintercept = cycle_dates[6])) +
  geom_vline(aes(xintercept = cycle_dates[7])) +
  geom_vline(aes(xintercept = cycle_dates[8])) +
  geom_vline(aes(xintercept = cycle_dates[9])) +
  geom_vline(aes(xintercept = cycle_dates[10])) +
  geom_vline(aes(xintercept = cycle_dates[11])) +
  labs(x = "Day #", y = "Plant ID", color= "Plant ID")
# ggsave(paste0(plots_path, "Exploratory/Shade Plants in Rust Sampling", ".png"), plant_ids_shade_plot, height = 6, width = 12)

plant_ids_sun <-distinct_at(rSelected, c("day.n", "Plant"))
plant_ids_sun_plot <- ggplot(plant_ids_sun, aes(x = day.n, y = as.factor(Plant))) +
  geom_point(aes(color = as.factor(Plant))) +
  geom_vline(aes(xintercept = cycle_dates[1])) +
  geom_vline(aes(xintercept = cycle_dates[2])) +
  geom_vline(aes(xintercept = cycle_dates[3])) +
  geom_vline(aes(xintercept = cycle_dates[4])) +
  geom_vline(aes(xintercept = cycle_dates[5])) +
  geom_vline(aes(xintercept = cycle_dates[6])) +
  geom_vline(aes(xintercept = cycle_dates[7])) +
  geom_vline(aes(xintercept = cycle_dates[8])) +
  geom_vline(aes(xintercept = cycle_dates[9])) +
  geom_vline(aes(xintercept = cycle_dates[10])) +
  geom_vline(aes(xintercept = cycle_dates[11])) +
  labs(x = "Day #", y = "Plant ID", color= "Plant ID")
# ggsave(paste0(plots_path, "Exploratory/Sun Plants in Rust Sampling", ".png"), plant_ids_sun_plot, height = 6, width = 12)


######################################################
### From Functions.R
######################################################


# filter.format.correct.add <-  function(d, SunOrShade, sampldays, firstday, maxnl){
#   d1 <- filter.format.correct(d, SunOrShade, firstday, maxnl) %>%
#     branch.cycle(sampldays) %>%
#     lesion.age()
#   # d1 <- branch.cycle(d1, sampldays, firstday) %>%
#   #   lesion.age() #%>%
#     # rename_with(.fn = ~ paste0(.x,"_sun"), .cols =  !c("fdate","dayn"))
#   # d2 <- filter.format.correct(d, "Shade", firstday, maxnl)
#   # d2 <- branch.cycle(d2, sampldays, firstday) %>%
#   #   lesion.age() %>%
#   #   rename_with(.fn = ~ paste0(.x,"_shade"), .cols =  !c("fdate","dayn"))
#   # 
#   # df <- full_join(d1, d2, by = c("fdate", "dayn"))
# }
# 
# filter.format.correct <- function(d, SunOrShade, firstday, maxnl) {
#   t.plot <- ifelse(SunOrShade == "Sun", "TFSSF", "TMSSF") 
#   #subset rust data for appr treatment, first maxnl lesions # no NAs unless Fallen
#   rSelected <- d %>%
#     filter(Treatment == t.plot, Lesion <= maxnl, Fallen == 0,
#            !(is.na(TotalAreaLesion) | is.na(AreaWithSpores))) %>%
#     #correct date and areas format, add day number, find missing Infected from num.area when avail
#     mutate(
#       fdate = as.Date(Date, format = "%m/%d/%y"),
#       num.area = as.numeric(as.character(TotalAreaLesion)),
#       spore.area = as.numeric(AreaWithSpores),
#       dayn = fdate - firstday + 1,
#       Infected = case_when(
#         is.na(Infected) & num.area == 0 ~ as.integer(0),
#         is.na(Infected) & num.area > 0 ~ as.integer(1),
#         TRUE ~ Infected
#       )
#     ) %>%
#     filter(!is.na(Infected), Infected == 1)
#   
#   # correct duplicated branch ids 
#   # for full sun:
#   # branch 27.T1 had duplicates. Changing to 27.T8.
#   # Maybe it was indeed the same branch surveyed before, but for every cycle a new, healthy, pair or leaves was chosen, so it couldn't be the same pair as before
#   # for shaded:
#   # branches 4.T4 and 17.T6 had duplicates. Changing to 4.T7 and 17.T8
#   # confirmed with plots (second set of dates later on):
#   # plot(rSelected[rSelected$branch.id == "17.T6", "fdate"], rSelected[rSelected$branch.id == "17.T6", "num.area"])
#   if (SunOrShade == "Sun"){
#     rSelected <- mutate(rSelected, Branch = case_when(
#       Plant == 27 & Branch == "T1" & dayn >= 203 ~ "T8",
#       TRUE ~ as.character(Branch)
#     ))
#   } else {
#     rSelected <- mutate(rSelected, Branch = case_when(
#       Plant == 4 & Branch == "T4" & dayn >= 203 ~ "T7",
#       Plant == 17 & Branch == "T6" & dayn >= 203 ~ "T8",
#       TRUE ~ as.character(Branch)
#     ))
#   }
#   
#   rSelected <- rSelected %>%
#     mutate(
#       branch.id = as.factor(paste(Plant, Branch, sep = ".")),
#       leaf.id = as.factor(paste(branch.id, RightLeftLeaf, sep = ".")),
#       rust.id = as.factor(paste(leaf.id, Lesion, sep = "."))
#       ) %>%
#     select(fdate,dayn,Plant:Sporulating,Fallen,Lesion,num.area,spore.area,branch.id:b.lastdate)
#   
#   return(rSelected)
# }
# 
# branch.cycle <- function(d, sampldays) {
#   # last day for each cycle
#   # because of the overlap of 2nd half, sampldays[6] is only start of cycle 6, not end of c 5
#   # (c 5 ends at start of c 7, c 6 at start of c 8, etc)
#   cyclesclose <- sampldays #[-6]
#   d %>%
#     group_by(branch.id) %>%
#     mutate(first.samp = min(dayn),
#            last.samp = max(dayn),
#            branch.cycle = findInterval(last.samp, cyclesclose, left.open = T) #, rightmost.closed = T)
#     ) %>%
#     ungroup()
# }

remove.cycle <- function(d, rmcycle) {
  d %>%
    filter(branch.cycle != rmcycle) %>%
    mutate(branch.cycle = ifelse(branch.cycle > rmcycle, branch.cycle - 1, branch.cycle))
}

#################


count.lesions <- function(d) {
  d %>%
    group_by(plot, fdate, cycle, dayn, leaf.id) %>%
    mutate(leaf_nl = max(Lesion),
           leaf_firstfound = min(firstfound),
           leaf_maxage = max(age),
           .groups = "drop")
}

summ.plot.date.cycle.age <- function(d){
  d %>%
    group_by(plot, fdate, dayn, age, firstfound, cycle) %>%
    summarise(area_dat = median(num.area),
              spore_dat = median(spore.area),
              totlesions = n(),
              leaves.sampled = mean(leaves.samp),
              avail.sites = leaves.sampled * 25,
              occup_dat = totlesions / avail.sites,
              .groups = "drop") %>% 
    filter(totlesions > 2)
}
