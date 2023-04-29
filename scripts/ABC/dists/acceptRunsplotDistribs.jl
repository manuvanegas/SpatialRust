using Arrow, CSV, DataFrames, Random, Statistics
# using StatsBase: denserank
using GLMakie #CairoMakie

# Time-to-first-plot still too long...
rainclouds(["a","b","a","b"], [1.0,1.0,2.0,2.0])

include("../../../src/ABC/AcceptRuns.jl")
include("../../../src/ABC/DistributionPlots.jl")
include("../../../src/ABC/CustomRainclouds.jl")

v = 15
vv = string("q", v)

parameterpriors = DataFrame(Arrow.Table(string("data/ABC/parameters_", v, ".arrow")))
prior_medians = combine(parameterpriors, All() .=> median)
scaledparams = scale_params(parameterpriors, prior_medians)

dists = CSV.read(string("results/ABC/dists/sents/", vv, "/squareddists.csv"), DataFrame)

sortedrows = best_100(dists, true,
    [:P12loss, :LP, :incid, :rusts, :exh, :depsdiff, :cor],
    Symbol[]
)

selectedscaled = get_params_rows(scaledparams, sortedrows.p_row)

# 1000 random params instead of the 10^6-100 rejected, for faster plotting
randpars1000 = sample_rejected_n(sortedrows.p_row, nrow(parameterpriors), 1000);
fig1 = dodged_rainclouds(scaledparams, selectedscaled, 2, randpars1000, 100)

# now the real one
fig12 = dodged_rainclouds(scaledparams, selectedscaled, 2, 1000, height = 1200)
fig14 = dodged_rainclouds(scaledparams, selectedscaled, 2, 1000, height = 1400)

# still have to figure out this
save("plots/ABC/all_stats1200.png", fig12)
save("plots/ABC/all_stats1400.png", fig14)
save("plots/ABC/all_stats1200half.pdf", fig12, pt_per_unit = 0.5)
save("plots/ABC/all_stats1400half.pdf", fig14, pt_per_unit = 0.5)
save("plots/ABC/all_stats1400.pdf", fig14, pt_per_unit = 1)

save("plots/ABC/all_stats1200.svg", fig12)
save("plots/ABC/all_stats1400.svg", fig14)

# get real param values (not scaled) of best 3 rows, preserving sorted order, rounding to 6 digits
# re-run ABC simulations 
# test behavior over 8 years (plotting eg lines(df.dayn, df.sumarea))
toprows = top_n_rows(parameterpriors, sortedrows.p_row, 3)
tcycdf, tglobdf = reduce(cat_dfs, map(sim_abc, Tables.namedtupleiterator(toprows)))
testruns = test_params(toprows, 3)

# get and write real param values (not scaled): best point estimate, median of accepted, all accepted, 100 sample of rejected
dfs = get_best_accept_reject(parameterpriors, sortedrows.p_row, 1)
mkpath(string("results/ABC/params/sents/", vv))
write_dfs(dfs, "cor", vv)
