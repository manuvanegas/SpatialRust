# exploring how lesion area relates to spore, necrotic and lecanicillium areas

plot(RustDB$AreaWithSpores[RustDB$AreaWithSpores != 0 & !is.na(RustDB$AreaWithSpores)], 
     RustDB$NumArea[RustDB$AreaWithSpores != 0 & !is.na(RustDB$AreaWithSpores)],
     xlim=c(0,0.7),
     ylim=c(0,0.7))

plot(rSelected$AreaWithSpores[rSelected$AreaWithSpores != 0], 
     rSelected$NumArea[rSelected$AreaWithSpores != 0],
     xlim=c(0,0.7),
     ylim=c(0,0.7))

plot(rSelected$NecroticArea[rSelected$NecroticArea != 0 & is.na(rSelected$AreaWithSpores)], 
     rSelected$NumArea[rSelected$NecroticArea != 0 & is.na(rSelected$AreaWithSpores)],
     xlim=c(0,0.7),
     ylim=c(0,0.7))

plot(rSelected$LecanicilliumArea[rSelected$LecanicilliumArea != 0 & is.na(rSelected$AreaWithSpores)], 
     rSelected$NumArea[rSelected$LecanicilliumArea != 0 & is.na(rSelected$AreaWithSpores)],
     xlim=c(0,0.7),
     ylim=c(0,0.7))


# can we relate total lesion area to spore + necrotic + lecanicillium?
RustDB <- mutate(RustDB, SNL = if_else(is.na(AreaWithSpores), 0, AreaWithSpores) + 
                   if_else(is.na(NecroticArea), 0, NecroticArea) + 
                   if_else(is.na(LecanicilliumArea), 0, LecanicilliumArea))

RustDB <- mutate(RustDB, SL = if_else(is.na(AreaWithSpores), 0, AreaWithSpores) + 
                   if_else(is.na(LecanicilliumArea), 0, LecanicilliumArea))

RustDB <- mutate(RustDB, NL = if_else(is.na(NecroticArea), 0, NecroticArea) + 
                   if_else(is.na(LecanicilliumArea), 0, LecanicilliumArea))

rSelected <- subset(RustDB, Treatment == chosenTreatment & Lesion <= 25 & Infected == 1)

# overestimations by SNL, NL and SL
sum(RustDB$NumArea < RustDB$SNL, na.rm = T)
#279
sum(RustDB$NumArea < RustDB$NL, na.rm = T)
#49
sum(RustDB$NumArea < RustDB$SL, na.rm = T)
# 153, out of 256770 obs

# also, necrotic area introduces many small values for larger total lesion areas
plot(rSelected$SNL[rSelected$SNL > 0], rSelected$NumArea[rSelected$SNL > 0])
plot(rSelected$SL[rSelected$NL > 0], rSelected$NumArea[rSelected$NL > 0])
plot(rSelected$SL[rSelected$SL > 0], rSelected$NumArea[rSelected$SL > 0])

# Only spore area is better. Less error, no values are > total lesion area
plot(rSelected$AreaWithSpores[rSelected$AreaWithSpores > 0], rSelected$NumArea[rSelected$AreaWithSpores > 0])

# where NumArea is NA, no AreaWithSpores is > 0.26
sum(is.na(rSelected$NumArea) & !is.na(rSelected$AreaWithSpores) & rSelected$AreaWithSpores > 0 & rSelected$AreaWithSpores > 0.26)

# This is the region of interest
plot(RustDB$AreaWithSpores[RustDB$AreaWithSpores > 0],
     RustDB$NumArea[RustDB$AreaWithSpores > 0],
     xlim = c(0,0.26),
     ylim = c(0,0.26))

# linear regression
mod <- lm(RustDB$NumArea[RustDB$NumArea < 0.26 & RustDB$AreaWithSpores < 0.26 & RustDB$AreaWithSpores > 0] ~ RustDB$AreaWithSpores[RustDB$NumArea < 0.26 & RustDB$AreaWithSpores < 0.26 & RustDB$AreaWithSpores > 0])
summary(mod)
abline(mod, col = "blue")

####################################
## Code clippings


# lin.reg <- lm(NumArea[RustDB$SNL > 0 & RustDB$SNL < 0.5] ~ SNL[RustDB$SNL > 0 & RustDB$SNL < 0.5], data = RustDB)
# summary(lin.reg)
# 
# lin.reg2 <- lm(NumArea[rSelected$SNL > 0 & rSelected$SNL < 0.5] ~ SNL[rSelected$SNL > 0 & rSelected$SNL < 0.5], data = rSelected)
# summary(lin.reg2)
# 
# sum(!is.na(RustDB$NumArea) & !is.na(RustDB$NecroticArea) & RustDB$NumArea == RustDB$NecroticArea)
# 
# sum(rSelected$Fallen)
# 
# sum(is.na(RustDB$Infected) & RustDB$Fallen == 1)
# 
# sum(is.na(RustDB$Infected))
# 
# sum(rSelected$NecroticArea < rSelected$LecanicilliumArea, na.rm = T)
# 
# sum(is.na(rSelected$NumArea) & !is.na(rSelected$AreaWithSpores) & rSelected$AreaWithSpores > 0 & rSelected$AreaWithSpores < 0.2)
# sum(is.na(rSelected$NumArea) & is.na(rSelected$AreaWithSpores) & !is.na(rSelected$NecroticArea) & rSelected$NecroticArea != 0)
# sum(is.na(rSelected$NumArea) & is.na(rSelected$AreaWithSpores) & is.na(rSelected$NecroticArea) & !is.na(rSelected$LecanicilliumArea) & rSelected$LecanicilliumArea != 0)
# 
# 
# abline(mod, col="blue")
# abline(mod2, col="green")
# abline(mod3, col="yellow")
# 
# mod <- lm(NumArea ~ AreaWithSpores, data = rSelected)
# summary(mod)
# 
# mod2 <- lm(rSelected$NumArea[rSelected$NumArea < 0.3 & rSelected$AreaWithSpores < 0.2] ~ rSelected$AreaWithSpores[rSelected$NumArea < 0.3 & rSelected$AreaWithSpores < 0.2])
# summary(mod2)
# 
# mod3 <- lm(rSelected$NumArea[rSelected$NumArea < 0.3 & rSelected$AreaWithSpores < 0.2 & rSelected$AreaWithSpores > 0] ~ rSelected$AreaWithSpores[rSelected$NumArea < 0.3 & rSelected$AreaWithSpores < 0.2 & rSelected$AreaWithSpores > 0])
# summary(mod3)
# 
# plot(rSelected$AreaWithSpores[rSelected$NumArea < 0.3 & rSelected$AreaWithSpores < 0.2 & rSelected$AreaWithSpores > 0],
#      rSelected$NumArea[rSelected$NumArea < 0.3 & rSelected$AreaWithSpores < 0.2 & rSelected$AreaWithSpores > 0])
# abline(mod3)
# 
# qqnorm(residuals(mod))
# qqline(residuals(mod))
# 
# mod.all <- lm(NumArea ~ AreaWithSpores, data = RustDB)
# summary(mod.all)
# 
# plot(rSelected$NumArea[rSelected$AreaWithSpores > 0], rSelected$AreaWithSpores[rSelected$AreaWithSpores > 0] * 1.44 + 0.013, xlim = c(0, 0.4), ylim = c(0, 0.4))
# abline(0, 1)
# 
# plot(rSelected$AreaWithSpores[rSelected$AreaWithSpores > 0] * 1.44 + 0.013, rSelected$NumArea[rSelected$AreaWithSpores > 0], xlim = c(0, 0.4), ylim = c(0, 0.4))
# abline(0, 1)
# 
# points(rSelected$AreaWithSpores[is.na(rSelected$NumArea) & !is.na(rSelected$AreaWithSpores) & rSelected$AreaWithSpores > 0] * 1.56 + 0.007, rSelected$AreaWithSpores[is.na(rSelected$NumArea) & !is.na(rSelected$AreaWithSpores) & rSelected$AreaWithSpores > 0], col="red")
# 
# 
# plot(rSelected$AreaWithSpores, rSelected$NumArea, xlim = c(0, 0.4), ylim = c(0, 0.4))
# points(rSelected$AreaWithSpores[is.na(rSelected$NumArea) & !is.na(rSelected$AreaWithSpores) & rSelected$AreaWithSpores > 0],
#        rSelected$AreaWithSpores[is.na(rSelected$NumArea) & !is.na(rSelected$AreaWithSpores) & rSelected$AreaWithSpores > 0] * 1.56 + 0.007,
#        col="blue")
# abline(mod)
# 
