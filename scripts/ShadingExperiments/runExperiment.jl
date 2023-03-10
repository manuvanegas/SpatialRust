# @everywhere using DrWatson
# @everywhere @quickactivate "SpatialRust"
# @everywhere begin
# using Agents, CSV, DataFrames, Distributed
# using SpatialRust
# include("../../src/ShadingExperiments/Shading.jl")
# end

@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using Agents, CSV, DataFrames, SpatialRust
    using Statistics: std, mean
    include("../../src/ShadingExperiments/Shading.jl")
end

reps = parse(Int, ARGS[1])
mean_temp = parse(Float64, ARGS[2])
rain_prob = parse(Float64, ARGS[3])
shade_placemnt = parse(Int, ARGS[4])

mkpath("results/Shading/ABCests/exp-$mean_temp-$rain_prob")
filename = "results/Shading/ABCests/exp-$mean_temp-$rain_prob/r-$reps-$shade_placemnt.csv"

abcpars = CSV.read("results/ABC/params/sents/novar/byaroccincid_pointestimate.csv", DataFrame)


# using Dates
# dayofyear(Date(2017,3,10))

steps = 1461

if shade_placemnt == 1
    barriers = (0,0)
    shade_d = 100
    conds = hcat(DataFrame(
        shade_d = shade_d,
        barriers = barriers,
        target_shade = 0.0,
        prune_sch = [[-1]],
        common_map = :none,
        inspect_period = steps,
        fungicide_sch = [[-1]],
        shade_g_rate = 0.008,
        steps = steps,
        mean_temp = mean_temp,
        rain_prob = rain_prob,
    ),
    abcpars
    )
    repeat!(conds, reps)
    conds[!, :rep] = collect(1:reps)
else
    shade_d = 3 * shade_placemnt

    singlevals = hcat(DataFrame(
        shade_d = shade_d,
        # barriers = barriers,
        common_map = :none,
        inspect_period = steps,
        fungicide_sch = [[-1]],
        shade_g_rate = 0.008,
        steps = steps,
        mean_temp = mean_temp,
        rain_prob = rain_prob,
    ),
    abcpars
    )

    crossed = crossjoin(
        DataFrame(target_shade = 0.15:0.15:0.75),
        DataFrame(prune_sch = [[-1], [15,196], [74, 196, 319]]),
        DataFrame(barriers = [(1,1), (0,0)]),
        DataFrame(rep = 1:reps)
    )

    conds = hcat(crossed, repeat(singlevals, nrow(crossed)))
end

# frag_distg = groupby(combsdf, [:barriers, :shade_d])
# describe(frag_distg[1])

printinfo = """
        Temp: $mean_temp,
        Rain: $rain_prob,
        Reps: $reps,
        Array #: $shade_placemnt,
        Shade d: $shade_d
    """
println(printinfo)
flush(stdout)

results = shading_experiment(conds)

println("Total sims: $(nrow(results))")

CSV.write(filename, results)
