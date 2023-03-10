library(dplyr)
library(tidyr)
library(ggplot2)
library(wesanderson)

datadir <- "~/Documents/ASU/Coffee Rust/SpatialRust/results/ABC/posteriors/sents/novar/"

# see other color options at the end
rejcol <- wes_palette("Royal1")[1]
acccol <- wes_palette("Royal1")[4]
poicol <- wes_palette("Chevalier1")[1]

## "Quantitative"
empdata <- read.csv("../../data/exp_pro/compare/perdate_age_long.csv")%>% 
  mutate(Date = as.Date(dayn + 114, origin = "2017-01-01"),
         age = factor(age))
occdays <- filter(empdata, !is.na(occup_dat)) %>% 
  pull(dayn) %>% unique

met <- "byaroccincid"

quantspath <- paste(datadir, "quant_", met, ".csv", sep ="")
qualspath <- paste(datadir, "qual_", met, ".csv", sep ="")
nts <- read.csv(quantspath, h=T) %>% 
  filter(age > -1) %>% 
  mutate(Date = as.Date(dayn + 114, origin = "2017-01-01"),
         age = factor(age),
         row = factor(p_row),
         runtype = factor(source, levels = c("rej", "acc", "point")),
         rowyear = factor(paste(row, ifelse(dayn<200,1,2), sep="_")))

#v for variable
varea <- select(nts, Date, age, runtype, row, plot, rowyear, value = area)
vspor <- select(nts, Date, age, runtype, row, plot, rowyear, value = spore)
vnl <- select(nts, Date, age, runtype, row, plot, rowyear, value = nl)
vocc <- select(nts, Date, age, runtype, row, plot, rowyear, value = occup) %>% filter(!is.na(value))


# %>% unite(row, cycle, col = "linegroup", sep = "_")

# areants <- select(nts, Date, age, runtype, row, plot, area, spore)
# lesnts <- select(nts, Date, age, runtype, row, plot, nl, occup)
# 
# area_long <- pivot_longer(areants, cols = 6:7, names_to = "measurement", values_to = "Value") %>%
#   unite(measurement, plot, col = "variable", sep = "_")
# lesion_long <- pivot_longer(lesnts, cols = 6:7, names_to = "measurement", values_to = "Value") %>%
#   unite(measurement, plot, col = "variable", sep = "_")

plotvar_age <- function(d, v) {
  var <- enquo(v)
  ggplot(d, aes(Date, value)) +
    geom_line(data = filter(d, runtype == "rej"),
              aes(color = runtype, group = rowyear),
              color = acccol, alpha = 0.2) +
    # geom_line(data = filter(d, runtype == "acc"),
    #           aes(color = runtype, group = row),
    #           color = acccol, alpha = 0.2) +
    geom_line(data = filter(d, runtype == "point"),
              aes(color = runtype, group = rowyear),
              color = poicol, alpha = 0.4) +
    geom_point(data = empdata, aes(Date, !!var),
               shape = 21, fill = "white", size = 1) +
    facet_grid(rows = vars(age), cols = vars(plot), scales = "free_y") +
    theme_bw()
}

#p for plot
parea <- plotvar_age(varea, area_dat)
pspor <- plotvar_age(vspor, spore_dat)
pnl <- plotvar_age(vnl, nl_dat)
pocc <- plotvar_age(vocc, occup_dat)

parea
pspor
pnl
pocc

# area pct
areapct <- select(nts, Date, age, runtype, row, rowyear, plot, ar_sum, ar_mn, nl_mn) %>% 
  mutate(plot = factor(plot, levels = c("sun", "shade"))) %>% 
  group_by(Date, row, rowyear, plot, runtype) %>% 
  summarise(areasum = first(ar_sum), areamn = first(ar_mn), nl = first(nl_mn), .groups = "drop")

postcheck3 <- ggplot(areapct, aes(Date, nl, group = rowyear)) +
  geom_line(data = filter(areapct, runtype == "rej"),
            aes(color = runtype), alpha = 0.4) +
  geom_line(data = filter(areapct, runtype == "acc"),
            aes(color = runtype), alpha = 0.6) +
  geom_line(data = filter(areapct, runtype == "point"),
            aes(color = runtype), alpha = 0.6) +
  facet_grid(cols = vars(plot), scales = "free_y") +
  theme_bw()
postcheck3


 ## Qualitative
ls <- read.csv(qualspath, h=T) %>% 
  mutate(runtype = factor(source, levels = c("rej", "acc", "point")))
# exh <- select(ls, runtype, exh, plot)
# prodcor <- select(ls, runtype, prod_clr, plot)

postcheck4 <- ggplot(ls, aes(runtype, exh, fill = plot))+
  geom_boxplot() +
  theme_bw()
postcheck4
postcheck5 <- ggplot(ls, aes(runtype, prod_clr, fill = plot))+
  geom_boxplot() +
  theme_bw()
postcheck5
postcheck6 <- ggplot(ls, aes(runtype, incid, fill = plot))+
  geom_boxplot() +
  theme_bw()
postcheck6



library(arrow)
lsacc <- read_feather("../../results/ABC/posteriors/a/accepted_qual_all_5.arrow")
lsrej <- read_feather("../../results/ABC/posteriors/a/rejected_qual_all_5.arrow")
lspoi <- read_feather("../../results/ABC/posteriors/a/pointest_qual_all_5.arrow")
bls <- bind_rows("acc" = lsacc, "rej" = lsrej, "point" = lspoi, .id = "runtype") %>% 
  mutate(runtype = factor(runtype, levels = c("rej", "acc", "point")))
exh <- select(bls, runtype, exh_sun, exh_shade) %>% 
  pivot_longer(cols = 2:3, names_to = "plot", names_prefix = "exh_", values_to = "value")
prodcor <- select(bls, runtype, prod_clr_sun, prod_clr_shade) %>% 
  pivot_longer(cols = 2:3, names_to = "plot", names_prefix = "prod_clr_", values_to = "value")

bpostcheck4 <- ggplot(exh, aes(runtype, value, fill = plot))+
  geom_boxplot() +
  theme_bw()
postcheck4
bpostcheck5 <- ggplot(prodcor, aes(runtype, value, fill = plot))+
  geom_boxplot() +
  theme_bw()
postcheck5

postcheck4
bpostcheck4
postcheck5
bpostcheck5

# rejcol <- wes_palette("Royal1")[1]
# acccol <- wes_palette("Royal1")[4]
# poicol <- wes_palette("Royal1")[2]
# 
# rejcol <- wes_palette("Chevalier1")[3]
# acccol <- wes_palette("Chevalier1")[2]
# poicol <- wes_palette("Chevalier1")[1]
# 
# rejcol <- wes_palette("Cavalcanti1")[3]
# acccol <- wes_palette("Cavalcanti1")[4]
# poicol <- wes_palette("Cavalcanti1")[2]
# 
# rejcol <- wes_palette("Royal1")[1]
# acccol <- wes_palette("Chevalier1")[2]
# poicol <- wes_palette("Chevalier1")[1]
# 
# rejcol <- wes_palette("IsleofDogs1")[3]
# acccol <- wes_palette("IsleofDogs1")[2]
# poicol <- wes_palette("IsleofDogs1")[4]


ta <- sort(runif(75, 0, 10))
tb <- runif(75, 0, 10)
tb <- c(runif(40, 10, 20), sort(runif(35,10,20)))
cor.test(ta,tb, method = "spearman", alternative = "g")


area0 <- filter(varea, age == 1)

meanempdata <- group_by(empdata, age, plot) %>% 
  summarise(marea = mean(area_dat, na.rm = T),
            mspore = mean(spore_dat, na.rm = T),
            mnl = mean(nl_dat, na.rm = T),
            mocc = mean(occup_dat, na.rm = T), .groups = "drop")
sumempdata <- group_by(empdata, Date, plot) %>% 
  summarise(sarea = sum(area_dat, na.rm = T),
            sspore = sum(spore_dat, na.rm = T),
            snl = sum(nl_dat, na.rm = T),
            socc = sum(occup_dat, na.rm = T), .groups = "drop")
meanquants <- group_by(nts, age, plot, runtype) %>% 
  summarise(marea = mean(area, na.rm = T),
            mspore = mean(spore, na.rm = T),
            mnl = mean(nl, na.rm = T),
            mocc = mean(occup, na.rm = T), .groups = "drop")
# get bls but for nts of all
ntsacc <- read_feather("../../results/ABC/posteriors/a/accepted_quant_all_5.arrow")
ntsrej <- read_feather("../../results/ABC/posteriors/a/rejected_quant_all_5.arrow")
ntspoi <- read_feather("../../results/ABC/posteriors/a/pointest_quant_all_5.arrow")
bnts <- bind_rows("acc" = ntsacc, "rej" = ntsrej, "point" = ntspoi, .id = "runtype") %>% 
  mutate(runtype = factor(runtype, levels = c("rej", "acc", "point")))
meanquantsall <- group_by(bnts, age, plot, runtype) %>% 
  summarise(marea = mean(area, na.rm = T),
            mspore = mean(spore, na.rm = T),
            mnl = mean(nl, na.rm = T),
            mocc = mean(occup, na.rm = T), .groups = "drop")


exhprodsh <- ggplot(bls, aes(exh_shade, prod_clr_shade)) +
  geom_point(aes(color = runtype))
exhprodsh
exhprodsun <- ggplot(bls, aes(exh_sun, prod_clr_sun)) +
  geom_point(aes(color = runtype))
exhprodsun
ggplot(ls, aes(exh, prod_clr)) +
  geom_point(aes(color = runtype))


###
# data age 7 distrib, does it match mcain and he... sayin r is 1-1.5 after 2-3 months?
dataage7sun <- filter(sun_treatm, age == 7)
hist(dataage7sun$num.area)
plot(as.factor(sun_treatm$age), sun_treatm$num.area)
plot(as.factor(shade_treatm$age), shade_treatm$num.area)

# distribution of sumareas
sumareasun <- group_by(sun_treatm, fdate, leaf.id) %>% 
  summarise(tot = sum(num.area), mean = mean(num.area), med = median(num.area))
# meantot = 0.08162707, mean2 = 0.01771462
sumareash <- group_by(shade_treatm, fdate, leaf.id) %>% 
  summarise(tot = sum(num.area), mean = mean(num.area), med = median(num.area))
# meantot = 0.1113958, mean2 = 0.01954268
h1 <- hist(sumareasun$tot, plot=F)
h2 <- hist(sumareash$tot,plot=F)
plot(h2, col = "green4", ylim =c(0,500))
plot(h1, col = c1, add = T, ylim =c(0,500))

