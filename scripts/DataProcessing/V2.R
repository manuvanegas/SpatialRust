# Will format it properly later


latentintervals <- c(0.0, 0.05, 0.15, 0.25, 0.35)
sporedintervals <- c(0.0, 0.05, 0.15, 0.25, 0.35)
nlintervals <- c(3, 6, 9, 12, 15)

leafw8 <- filter(lesions_data, sampling.week == 8) %>% 
  select(plot, fdate, dayn, leaf.id, leaf.area, leaf.spored, leaf.nl) %>% 
  group_by(plot, fdate, dayn, leaf.id) %>% 
  summarise(leaf.latent = first(leaf.area),
            leaf.spored = first(leaf.spored),
            leaf.nl = first(leaf.nl)) %>% 
  mutate(latentc = findInterval(leaf.latent, latentintervals, left.open = T),
         sporec = findInterval(leaf.spored, sporedintervals, left.open = T),
         nlc = findInterval(leaf.nl, nlintervals))

latentpcts <- group_by(leafw8, plot, fdate, dayn, latentc) %>% 
  summarise(n = n()) %>% 
  group_by(plot, fdate, dayn) %>% 
  mutate(ntot = sum(n),
         latentpct = round(n / ntot, digits = 6)) %>% 
  ungroup() %>% 
  select(!c(n, ntot)) %>% 
  rename(category = latentc)
latentpcts <- complete(latentpcts, plot, nesting(fdate, dayn), category, fill = list(latentpct = 0))

sporepcts <- group_by(leafw8, plot, fdate, dayn, sporec) %>% 
  summarise(n = n()) %>% 
  group_by(plot, fdate, dayn) %>% 
  mutate(ntot = sum(n),
         sporepct = round(n / ntot, digits = 6)) %>% 
  ungroup() %>% 
  select(!c(n, ntot)) %>% 
  rename(category = sporec)
sporepcts <- complete(sporepcts, plot, nesting(fdate, dayn), category, fill = list(sporepct = 0))

nlpcts <- group_by(leafw8, plot, fdate, dayn, nlc) %>% 
  summarise(n = n()) %>% 
  group_by(plot, fdate, dayn) %>% 
  mutate(ntot = sum(n),
         nlpct = round(n / ntot, digits = 6)) %>% 
  ungroup() %>% 
  select(!c(n, ntot)) %>% 
  rename(category = nlc)
nlpcts <- complete(nlpcts, plot, nesting(fdate, dayn), category, fill = list(nlpct = 0))

ggplot(leafw8, aes(fdate, leaf.nl)) +
  # geom_violin(aes(group = interaction(fdate, plot), color = plot),scale = "count") 
  geom_boxplot(aes(group = interaction(fdate, plot), color = plot)) +
  geom_jitter(aes(color = plot), alpha = 0.3)

# nls <- group_by(leafw8, plot, fdate, dayn) %>% 
#   summarise(means = mean(leaf.nl),
#             meds = median(leaf.nl),
#             sds = sd(leaf.nl),
#             n = n(),
#             q75 = quantile(leaf.nl, 0.75))
# ggplot(nls, aes(fdate, means, color = plot)) +
#   geom_line()
# ggplot(nls, aes(fdate, meds, color = plot)) +
#   geom_line()
# ggplot(nls, aes(fdate, sds, color = plot)) +
#   geom_line()
# ggplot(nls, aes(fdate, q75, color = plot)) +
#   geom_line()
# # means is better. Captures some of the variance and we know values cant go over 25, so outliers cant be too extreme

alldat <- full_join(sporenl, latentpcts, nlpcts, by = c("plot", "fdate", "dayn", "category")) %>% 
  filter(plot == "shade") %>% 
  replace_na(list(category = 0, latentpct = 0.0)) %>% 
  select(!plot)


palzissou7 <- wes_palette(name = "Zissou1", n=7, type = "continuous")


# filter(latentpcts, plot == "sun") %>%
alldat %>% 
  ggplot(aes(fdate, 100 * latentpct,
             group = factor(category),
             fill = factor(category))) +
  geom_line(aes(color = factor(category)),
            position = position_stack(reverse = T),
            linetype = "12") +
  geom_col(
    color = "white",
    linewidth = 0.1,
    width = 14,
    position = position_stack(reverse = T)) +
  scale_color_manual(values = palzissou7,
                     labels = c("0.0", "0.0-0.05", "0.05-0.15", "0.15-0.25", "0.25-0.35", "> 0.35")) +
  scale_fill_manual(values = palzissou7,
                    labels = c("0.0", "0.0-0.05", "0.05-0.15", "0.15-0.25", "0.25-0.35", "> 0.35")) +
  # scale_fill_gradient(low = "green4", high = "orange",
  #                   labels = c("0.0", "0.0-0.05", "0.05-0.15", "0.15-0.25", "0.25-0.35", "> 0.35")) +
  # scale_color_brewer(palette = "RdYlGn",
  #                   labels = c("0.0", "0.0-0.05", "0.05-0.15", "0.15-0.25", "0.25-0.35", "> 0.35")) +
  # # coord_cartesian(xlim = as.Date(c("2017-06-18", "2018-07-24"))) +
  scale_y_continuous(limits = c(0,100.01), expand = c(0,0.01)) +
  labs(x = "Date",
       y = "Latent Area Category Pecentage",
       fill = "Area Range",
       color = "Area Range") +
  theme_bw()

alldat %>% 
  ggplot(aes(fdate, 100 * sporepct,
             group = factor(category),
             fill = factor(category))) +
  geom_line(aes(color = factor(category)),
            position = position_stack(reverse = T),
            linetype = "12") +
  geom_col(
    color = "white",
    linewidth = 0.1,
    width = 14,
    position = position_stack(reverse = T)) +
  scale_color_manual(values = palzissou7,
                     labels = c("0.0", "0.0-0.05", "0.05-0.15", "0.15-0.25", "0.25-0.35", "> 0.35")) +
  scale_fill_manual(values = palzissou7,
                    labels = c("0.0", "0.0-0.05", "0.05-0.15", "0.15-0.25", "0.25-0.35", "> 0.35")) +
  # coord_cartesian(xlim = as.Date(c("2017-06-18", "2018-07-24"))) +
  scale_y_continuous(limits = c(0,100.01), expand = c(0,0.01)) +
  labs(x = "Date",
       y = "Sporulated Area Category Pecentage",
       fill = "Area Range",
       color = "Area Range") +
  theme_bw()

alldat %>% 
  ggplot(aes(fdate, 100 * nlpct,
             group = factor(category),
             fill = factor(category))) +
  geom_line(aes(color = factor(category)),
            position = position_stack(reverse = T),
            linetype = "12") +
  geom_col(
    color = "white",
    linewidth = 0.1,
    width = 12,
    position = position_stack(reverse = T)) +
  scale_color_manual(values = palzissou7,
                     labels = c("0-3", "4-6", "7-9", "10-12", "13-15", "> 15")) +
  scale_fill_manual(values = palzissou7,
                    labels = c("0-3", "4-6", "7-9", "10-12", "13-15", "> 15")) +
  # coord_cartesian(xlim = as.Date(c("2017-06-18", "2018-07-24"))) +
  scale_y_continuous(limits = c(0,100.01), expand = c(0,0.01)) +
  labs(x = "Date",
       y = "Lesion Count Category Pecentage",
       fill = "Count Range",
       color = "Count Range") +
  theme_bw()

write.csv(alldat,
          "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/v2/fuller.csv",
          row.names = F)
write.csv(select(alldat, !fdate),
          "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/v2/compare.csv",
          row.names = F)
write.csv(pull(alldat, dayn) %>% unique,
          "~/Documents/ASU/Coffee Rust/SpatialRust/data/exp_pro/v2/collectdates.csv",
          row.names = F)