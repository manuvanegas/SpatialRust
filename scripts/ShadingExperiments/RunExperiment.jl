@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere begin
using Agents, CSV, DataFrames, Distributed
using SpatialRust
include("../../src/ShadingExperiments/Shading.jl")
end

reps = parse(Int, ARGS[1])

conds = Dict(
    :shade_d => [0, 6, 10],
    :barrier_arr => [(0,0,0,0), (1,1,0,0), (1,1,2,2)],
    :shade_target => @onlyif((:shade_d != 0 || :barrier_arr != (0,0,0,0)),
        collect(0.2:0.1:0.8)),
    :pruning_period => [1461, 365, 182],
    :fungicide_period => 365,
    :barrier_rows => 2,
    :steps => 1460,
    :reps => collect(1:reps)
)

results = shading_experiment(conds)

CSV.write(projectdir("results/Shading/results-$reps.csv"), results)
