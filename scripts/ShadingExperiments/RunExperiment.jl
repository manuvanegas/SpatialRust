@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere begin
using Agents, CSV, DataFrames, Distributed
using SpatialRust
include("../../src/ShadingExperiments/Shading.jl")
end

reps = parse(Int, ARGS[1])
mean_temp = parse(Float64, ARGS[2])
rain_prob = parse(Float64, ARGS[3])
barriers = parse(Bool, ARGS[4])

if barriers
    b_arr = (1,1,0,0)
else
    b_arr = (0,0,0,0)
end
mkpath("results/Shading/r-$mean_temp-$rain_prob")
filename = "results/Shading/r-$mean_temp-$rain_prob/r-$reps-$barriers.csv"

conds = Dict(
    :shade_d => [0, 6, 10],
    :barrier_arr => b_arr,
    :target_shade => vcat(
        @onlyif((:shade_d == 0 && :barrier_arr == (0,0,0,0)), 0.0),
        @onlyif((:shade_d != 0 || :barrier_arr != (0,0,0,0)) && :prune_period == 1461, 1.0),
        @onlyif((:shade_d != 0 || :barrier_arr != (0,0,0,0)) && :prune_period != 1461,
            collect(0.2:0.1:0.9))),
    :prune_period => vcat(
        @onlyif((:shade_d == 0 && :barrier_arr == (0,0,0,0)), 1461),
        @onlyif((:shade_d != 0 || :barrier_arr != (0,0,0,0)), [1461, 365, 182])),
    :fungicide_period => 365,
    :barrier_rows => 2,
    :shade_g_rate => 0.05,
    :steps => 1460,
    :mean_temp => mean_temp,
    :rain_prob => rain_prob,
    :reps => collect(1:reps)
)

# combs2 = dict_list(conds2)

# combsdf = DataFrame(combs2)

# frag_distg = groupby(combsdf, [:barrier_arr, :shade_d])
# describe(frag_distg[1])

results = shading_experiment(conds)

CSV.write(projectdir(filename), results)
