using Pkg
Pkg.activate(".")
using Arrow, CSV, DataFrames, Random, Statistics
using CairoMakie

# violin(repeat([1,2], 10), 1:20)
# boxplot(repeat([1,2], 10), 1:20)
# scatter(1:10,2:2:20,1:10)
rainclouds(["a","b","a","b"], [1.0,1.0,2.0,2.0])

include("../../../src/ABC/AcceptRuns.jl")
include("../../../src/ABC/DistributionPlots.jl")
include("../../../src/ABC/CustomRainclouds.jl")

nmissings_max = 50
nanpenalty = 100.0

parameters = DataFrame(Arrow.Table(string("data/ABC/", "parameters_", 4, ".arrow")))
prior_medians = combine(parameters, All() .=> median)
scaledparams = scale_params(parameters, prior_medians)
# relev_mets = metric_combination(:both, :sum)
# relev_mets2 = metric_combination([9,10])
qual_mets = metric_combination([5:8;])
all_mets = metric_combination([1:8;])
notspore_mets = metric_combination([1; 3:8])
noareas_mets = metric_combination([3:8;])

dists = CSV.read("results/ABC/dists/squareddists.csv", DataFrame)
ndists = CSV.read("results/ABC/dists/nmissings.csv", DataFrame)
rmdists = rm_toomanymissings(dists, ndists, nmissings_max)
nonansdists = replacenans(rmdists, r"prod_clr", nanpenalty)

# trows = [641970,350963]
# filter(:p_row => p -> p in trows, nonansdists)
# filter(:RowN => p -> p in trows, parameters)

sel_rows = best_100(nonansdists, all_mets...)

selected = get_best_params(scaledparams, sel_rows)

write_accept_reject_runs(parameters, sel_rows, "all", nmissings_max)
# selparams = get_best_params(parameters, sel_rows)
# selhead = first(selparams, 10)
# append!(selhead, combine(selparams, :RowN => first, Not(:RowN) .=> median, renamecols = false))
# selhead[11, :RowN] = -1
# CSV.write("results/ABC/params/selected.csv", selhead)


randpars100 = rand(1:10^6, 100)
randpars1000 = rand(1:10^6, 1000)
randpars1e5 = rand(1:10^6, 1*10^5)

fig1 = dodged_rainclouds(scaledparams, selected, 2, randpars100, 10)
fig12 = dodged_rainclouds(scaledparams, selected, 2, 1000, height = 1200)
fig14 = dodged_rainclouds(scaledparams, selected, 2, 1000, height = 1400)

save("plots/ABC/all_stats1200.png", fig12)
save("plots/ABC/all_stats1400.png", fig14)
save("plots/ABC/all_stats1200half.pdf", fig12, pt_per_unit = 0.5)
save("plots/ABC/all_stats1400half.pdf", fig14, pt_per_unit = 0.5)
save("plots/ABC/all_stats1400.pdf", fig14, pt_per_unit = 1)

save("plots/ABC/all_stats1200.svg", fig12)
save("plots/ABC/all_stats1400.svg", fig14)

GC.gc()