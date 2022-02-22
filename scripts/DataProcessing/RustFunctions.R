##############################################################
# RustDB Processing and Preparation Functions
##############################################################

subset.n.prepare <- function(SunOrShade) {
  t.plot <- ifelse(SunOrShade == "Sun", "TFSSF", "TMSSF") 
  #subset rust data for "TFSSF" treatment, first 25 lesions, infected or fallen leaves
  #(all Fallen are Infected = NA and TotalArea = 0 and viceversa)
  rSelected <- subset(RustDB, Treatment == t.plot & Lesion <= 25 & (Infected == 1 | Fallen == 1))
  rSelected$num.area <- as.numeric(as.character(rSelected$TotalAreaLesion))
  rSelected$spore.area <- case_when((!is.na(rSelected$num.area) & is.na(rSelected$AreaWithSpores)) ~ 0.0,
                                    (is.na(rSelected$num.area) & !is.na(rSelected$AreaWithSpores)) ~ as.numeric(NA),
                                    TRUE ~ rSelected$AreaWithSpores) 
  # rSelected <- mutate(rSelected, CorrectedArea = Correct.NA(num.area, AreaWithSpores))
  rSelected$f.date <- as.Date(rSelected$Date, format="%m/%d/%y")
  # correction is necessary because branch values are pooled
  rSelected$f.date <- case_when(rSelected$f.date == "2017-05-11" ~ as.Date("2017-05-12"),
                                TRUE ~ as.Date(rSelected$f.date)) 
  rSelected$day.n <- rSelected$f.date - firstday + 1
  
  #add ids
  rSelected$branch.id <- as.factor(paste(rSelected$Plant, rSelected$Branch, 
                                         sep = "."))
  rSelected$leaf.id <- as.factor(paste(rSelected$Plant, rSelected$Branch,
                                       rSelected$RightLeftLeaf, sep = "."))
  rSelected$rust.id <- as.factor(paste(rSelected$Plant, rSelected$Branch, 
                                       rSelected$RightLeftLeaf, rSelected$Lesion, sep = "."))
  
  return(rSelected)
}

extract.add.info <- function(rSelected) {
  # add lesion age in weeks
  rSelected <- calc.lesion.weeks(rSelected)
  
  #add sampling group: 1 is first half, 2 is group A of 2nd half, 3 is group B
  if (SunOrShade == "Sun") {
    sampling_plants <- c(19:36, 76,79,81,82,83,85,87,90,91,77,78,80,84,86,88,89,92,93)
    # correct duplicated rust (rust.id = "27.T1.D.1")
    rSelected <- rSelected[!(rSelected$rust.id == "27.T1.D.1" & rSelected$day.n > 220),] # duplicate rust.ids appear at days 224 and 231
  } else {
    sampling_plants <- c(1:18,94,95,99,100,102,104,105,109,110,96,97,98,101,103,106,107,108,111)
    # correct duplicated rusts
    print("WARNING! Shade dataset has not been corrected")
    print("List of duplicate rusts:")
    dup_r <- unique(rSelected[rSelected$age.week > 7,"rust.id"])
    print(dup_r)
    print("Days with dups:")
    print(unique(rSelected[rSelected$age.week > 7, "day.n"]))
    
    change_4T4 <- rSelected$day.n < 232 & rSelected$day.n > 216 & rSelected$branch.id == "4.T4"
    change_17T6 <- rSelected$day.n < 232 & rSelected$day.n > 216 & rSelected$branch.id =="17.T6"
    last_b_4 <- max(as.character(rSelected[rSelected$Plant == 4, "branch.id"])) # "4.T6"
    last_b_17 <- max(as.character(rSelected[rSelected$Plant == 17, "branch.id"])) # "17.T7"
    
    # need to add new branch.id's and rust.id's as factor levels
    # example:
    rSelected$rust.id <- factor(rSelected$rust.id, levels = c(levels(rSelected$rust.id), "4.T7.D.1"))
    
    #then replace ids (the following will error)
    rSelected[change_4T4, c("branch.id", "rust.id")] <- c("4.T7", paste("4.T7", rSelected$RightLeftLeaf[change_4T4], rSelected$Lesion[change_4T4], sep = "."))
  }
  rSelected$plant.group <- assign.group(rSelected$Plant, sampling_plants)
  rSelected$sample.cycle <- v.assign.cycle(rSelected$day.n, rSelected$plant.group)
  
  return(rSelected)
}

calc.lesion.weeks <- function(d) {
  d$first.found <- as.Date(rep_len(0,length(d$rust.id)), origin = "2000-01-01")
  rusts <- unique(d$rust.id)
  for(rr in rusts) {
    #r_id <- subset(d, rust.id == rr)
    #start.d <- min(rSelected[rSelected$rust.id == rr, "f.date"])
    d$first.found[d$rust.id == rr] <- min(rSelected[rSelected$rust.id == rr, "f.date"])
    #for(dd in 1:length(r_id$f.date)) {
    #  d$l.age[d$rust.id == rr & d$f.date == r_id$f.date[dd]] = r_id$f.date[dd] - start.d + 3
    #  d$age.week[d$rust.id == rr & d$f.date == r_id$f.date[dd]] = round(difftime(r_id$f.date[dd], start.d, units = "weeks"))
    #}
  }
  d$age.week <- round(difftime(d$f.date, d$first.found, units = "weeks"))
  return(d)
}

assign.group <- function(id, sampled_plants){
  p.group <- ifelse(id %in% sampled_plants[1:18], 1, ifelse(id %in% sampled_plants[19:27], 2, ifelse(id %in% sampled_plants[28:36],3, NA)))
  return(p.group)
}

assign.cycle <- function(day.n, plant.group){
  s.cycle <- which.max(day.n <= plant_sampling_days) - 1
  if (s.cycle == 0) {
    s.cycle <- 11
  }
  if (plant.group == 2 & s.cycle %% 2 == 0) {
    s.cycle <- s.cycle - 1
  } else if (plant.group == 3 & s.cycle %% 2 != 0){
    s.cycle <- s.cycle - 1
  }
  return(s.cycle)
}

v.assign.cycle <- Vectorize(assign.cycle)

remove.cycle.5 <- function(df) {
  df <- subset(df, sample.cycle != 5)
  
  df$sample.cycle <- ifelse(df$sample.cycle > 5, df$sample.cycle - 1, df$sample.cycle)
  #case_when(sample.cycle > 5 ~ sample.cycle - 1, TRUE ~ sample.cycle)
  return(df)
}