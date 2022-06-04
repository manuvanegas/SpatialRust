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
fragments = parse(Int, ARGS[4]) ^ 2 # 1, 4, 9

# if barriers
#     b_arr = (1,1,0,0)
# else
#     b_arr = (0,0,0,0)
# end
mkpath("results/Shading/r2-$mean_temp-$rain_prob")
filename = "results/Shading/r2-$mean_temp-$rain_prob/r2-$reps-$fragments.csv"

printinfo = """
        Temp: $mean_temp,
        Rain: $rain_prob,
        Reps: $reps,
        Fragments: $fragments)
    """
println(printinfo)

conds = Dict(
    :shade_d => [0, 6, 9, 12],
    # :barrier_arr => b_arr,
    :fragments => fragments,
    :target_shade => vcat(
        @onlyif(:shade_d == 0 && :fragments == 1, 0.0),
        @onlyif(:shade_d != 0 || :fragments != 1,
            collect(0.2:0.1:0.8))),
        # @onlyif((:shade_d == 0 && :barrier_arr == (0,0,0,0)), 0.0),
        # @onlyif((:shade_d != 0 || :barrier_arr != (0,0,0,0)) && :prune_period == 1461, 0.95),
        # @onlyif((:shade_d != 0 || :barrier_arr != (0,0,0,0)) && :prune_period != 1461,
        #     collect(0.2:0.1:0.8))),
    :prune_period => vcat(
        @onlyif(:shade_d == 0 && :fragments == 1, 1461),
        @onlyif(:shade_d != 0 || :fragments != 1, [365, 182])),
        # @onlyif((:shade_d == 0 && :barrier_arr == (0,0,0,0)), 1461),
        # @onlyif((:shade_d != 0 || :barrier_arr != (0,0,0,0)), [365, 182])),
    :fungicide_period => 365,
    :barrier_rows => 2,
    :shade_g_rate => 0.05,
    :steps => 1460,
    :mean_temp => mean_temp,
    :rain_prob => rain_prob,
    # from ABC
    :rust_gr => 1.63738,
    :cof_gr => 0.393961,
    :spore_pct => 0.821479,
    :fruit_load => 0.597133,
    :uv_inact => 0.166768,
    :rain_washoff => 0.23116,
    :rain_distance => 0.80621,
    :wind_distance => 3.29275,
    :exhaustion => 0.17458,
    :reps => collect(1:reps)
)

# combs2 = dict_list(conds2)

# combsdf = DataFrame(combs2)

# frag_distg = groupby(combsdf, [:barrier_arr, :shade_d])
# describe(frag_distg[1])

results = shading_experiment(conds)

CSV.write(projectdir(filename), results)
