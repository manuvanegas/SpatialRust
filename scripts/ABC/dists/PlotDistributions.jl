Pkg.activate(".")
using Arrow, CairoMakie, CSV, DataFrames

violin(repeat([1,2], 10), 1:20)
boxplot(repeat([1,2], 10), 1:20)

include("../../../src/ABC/RanksPlots.jl")

parameters = DataFrame(Arrow.Table(string("data/ABC/", "parameters_", 10^6, ".arrow")))
dists = CSV.read("results/ABC/dists/hand_dists.csv", DataFrame)
selected = subset(parameters, :RowN => x -> x .∈ Ref(best_n(dists, metrics(4), 100)))
# selected2 = subset(parameters, :RowN => x -> x .∈ Ref(best_n(dists, metrics(2), 100)))
# selected3 = subset(parameters, :RowN => x -> x .∈ Ref(best_n(dists, metrics(3), 100)))
# selected4 = subset(parameters, :RowN => x -> x .∈ Ref(best_n(dists, metrics(4), 100)))
# selected = subset(parameters, :RowN => x -> x .∈ Ref(best_100(dists, [:area_cycle, :spore_cycle, :fallen])))
medians = combine(selected, names(selected) .=> median)

longpars = long_and_separate(parameters)
longsel = long_and_separate(selected)
# longsel2 = long_and_separate(selected2)
# longsel3 = long_and_separate(selected3)
# longsel4 = long_and_separate(selected4)


fig1 = three_boxplots(longpars, longsel)
Label(fig1[0,:], "With areas per age", textsize = 18)
fig1
fig2 = three_boxplots(longpars, longsel2)
Label(fig2[0,:], "With areas per age", textsize = 18)
fig2
fig3 = three_boxplots(longpars, longsel3)
Label(fig3[0,:], "With sum of areas", textsize = 18)
fig3
fig4 = three_boxplots(longpars, longsel4)
Label(fig4[0,:], "With sum of areas", textsize = 18)
fig4

save("plots/ABC/areas_age.png", fig2)
save("plots/ABC/sum_areas.png", fig4)
