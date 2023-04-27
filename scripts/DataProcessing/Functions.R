#################################################################
# RustDB Subsetting, Preparation, and Correction
#################################################################

preprocess_info <- function(d, firstday, maxnl){
  sun <- filter.format.correct.add(d, "Sun", firstday, maxnl)
  shade <- filter.format.correct.add(d, "Shade", firstday, maxnl)
  return(bind_rows("sun" = sun, "shade" = shade, .id = "plot"))
}

filter.format.correct.add <-  function(d, SunOrShade, firstday, maxnl){
  t.plot <- ifelse(SunOrShade == "Sun", "TFSSF", "TMSSF")
  
  d %>%
    filter(Treatment == t.plot, Lesion <= maxnl,
           Fallen == 0,
           (!is.na(TotalAreaLesion) & !is.na(AreaWithSpores))
           ) %>% 
    drop.vars() %>%
    date.formats() %>% 
    correct.ids() %>%
    sampling.dates() %>%
    numeric.format() %>%
    filter(dayn < 203 | dayn > 258) %>% # drop cycle 4
    count.leaves() %>%
    keep.infected() %>%
    lesion.age() %>%
    per.leaf.aggs() %>% 
    select(fdate,dayn,Plant:Infected,Lesion:leaf.nl)
}

drop.vars <- function(d) {
  d %>% 
    select(!c(DateLabel,Altitud,NoCount,PictureName,Exam,NecroticArea,LecanicilliumArea))
}

date.formats <- function(d) {
  d %>%
    mutate(
      Date = as.Date(Date, format = "%m/%d/%y"),
      dayn = Date - firstday + 1
    )
}

correct.ids <- function(d) {
  # correct duplicated branch ids 
  # for full sun:
  # branch 27.T1 had duplicates. Changing to 27.T8.
  # Maybe it was indeed the same branch surveyed before, but for every cycle a new, healthy, pair or leaves was chosen, so it couldn't be the same pair as before
  # for shaded:
  # branches 4.T4, 8.B2 and 17.T6 had duplicates. Changing to 4.T7, 8.B8 and 17.T8
  # found with eg: 
  # unique(shade_treatm[shade_treatm$last.samp - shade_treatm$first.samp > 71,"rust.id"])
  # confirmed visually with plots, eg:
  # plot(rSelected[rSelected$branch.id == "17.T6", "fdate"], rSelected[rSelected$branch.id == "17.T6", "num.area"])
  d <- mutate(d, Branch = case_when(
    Treatment == "TFSSF" & Plant == 27 & Branch == "T1" & dayn >= 203 ~ "T8",
    Treatment == "TMSSF" & Plant == 4 & Branch == "T4" & dayn >= 203 ~ "T7",
    Treatment == "TMSSF" & Plant == 8 & Branch == "B2" & dayn >= 203 ~ "B8",
    Treatment == "TMSSF" & Plant == 17 & Branch == "T6" & dayn >= 203 ~ "T8",
    TRUE ~ as.character(Branch)
  ))
  
  d %>%
    mutate(
      branch.id = as.factor(paste(Plant, Branch, sep = ".")),
      leaf.id = as.factor(paste(branch.id, RightLeftLeaf, sep = ".")),
      rust.id = as.factor(paste(leaf.id, Lesion, sep = "."))
    )
}

sampling.dates <- function(d) {
  d %>%
    rename(fdate = Date) %>%
    group_by(branch.id) %>%
    mutate(first.samp = min(dayn),
           first.datsamp = min(fdate),
           last.samp = max(dayn),
           sampling.week = round(difftime(fdate, first.datsamp, units = "weeks"))
    ) %>%
    ungroup()
}

count.leaves <- function(d) {
  d %>% 
    group_by(dayn, sampling.week) %>% 
    mutate(leaves.samp = n_distinct(leaf.id)) %>% 
    ungroup()
}

numeric.format <- function(d) {
  d %>%
    mutate(
      num.area = as.numeric(as.character(TotalAreaLesion)),
      spore.area = as.numeric(AreaWithSpores)
    ) %>%
    select(!c(TotalAreaLesion, AreaWithSpores))
}

keep.infected <- function(d) {
  d %>% 
    mutate(
      Infected = case_when(
        is.na(Infected) & num.area == 0 ~ as.integer(0),
        is.na(Infected) & num.area > 0 ~ as.integer(1),
        TRUE ~ Infected
      )
    ) %>%
    filter(!is.na(Infected), Infected == 1)
}

lesion.age <- function(d) {
  d <- d %>%
    group_by(rust.id) %>%
    mutate(firstfound = min(fdate),
           ffday = min (dayn),
           age = round(difftime(fdate, firstfound, units = "weeks"))) %>%
    ungroup()
  cycledates <- unique(d$first.samp)
  mutate(d,
         cycle = findInterval(first.samp, cycledates))
}

per.leaf.aggs <- function(d) {
  d %>% 
    group_by(dayn, leaf.id) %>% 
    mutate(leaf.area = sum(num.area),
           leaf.spored = sum(spore.area),
           leaf.nl = max(Lesion),
           .groups = "drop")
}

#################################################################
# Extracting Metrics from Treatment Data
#################################################################

############################
# Metrics 1 & 2
# summ.areas <- function(sun, shade) {
#   if (any(sun$Plant == 1)) {
#     stop("Sun data should not include Plant # 1. Double-check argument order.")
#   }
#   d1 <- areas(sun)
#   d2 <- areas(shade)
#   # putting sd2 first because it has more observations than sd1
#   df <- full_join(d2, d1, by = c("fdate","dayn","age", "firstfound"), suffix = c("_sh","_sun"))
# }

areas <- function(d) {
  d %>%
    group_by(plot, fdate, dayn, age, firstfound, cycle) %>%
    summarise(area_dat = median(num.area),
              spore_dat = median(spore.area),
              n = n(),
              .groups = "drop") %>% 
    filter(n > 2)
}

############################
# Metric 3
# summ.count.nl <- function(sun, shade) {
#   if (any(sun$Plant == 1)) {
#     stop("Sun data should not include Plant # 1. Double-check argument order.")
#   }
#   sd1 <- count.lesions(sun) %>% summ.nl()
#   sd2 <- count.lesions(shade) %>% summ.nl()
#   # putting sd2 first because it has more observations than sd1
#   df <- full_join(sd2, sd1, by = c("fdate","dayn","age", "firstfound"), suffix = c("_sh","_sun"))
# }

count.lesions <- function(d) {
  d %>%
    group_by(plot, fdate, cycle, dayn, leaf.id) %>%
    summarise(nl = max(Lesion),
              firstfound = min(firstfound),
              age = max(age),
              .groups = "drop_last") %>% 
    mutate(n = n()) %>% 
    ungroup() %>% 
    filter(n > 2)
}

summ.nl <- function(d){
  d %>%
    group_by(plot, fdate, dayn, age, firstfound, cycle) %>%
    summarise(nl_dat = median(nl),
              nl_n = n(),
              .groups = "drop")
}

############################
# Metric 4

# summ.sites <- function(sun, shade) {
#   if (any(sun$Plant == 1)) {
#     stop("Sun data should not include Plant # 1. Double-check argument order.")
#   }
#   sd1 <- site.occupancy(sun)
#   sd2 <- site.occupancy(shade)
#   # putting sd2 first because it has more observations than sd1
#   df <- full_join(sd2, sd1, by = c("fdate","dayn","age"), suffix = c("_sh","_sun")) %>%
#     select(fdate:age, contains("occupancy"))
# }

site.occupancy <- function(d) {
  d %>% 
    filter(sampling.week == 8) %>%
    group_by(plot, fdate, dayn, age, cycle) %>% 
    summarise(
      totlesions = n(),
      leaves.sampled = mean(leaves.samp),
      avail.sites = leaves.sampled * 25,
      occup_dat = totlesions / avail.sites,
      .groups = "drop") %>% 
    select(plot:cycle, leaves.sampled, occup_dat)
}
