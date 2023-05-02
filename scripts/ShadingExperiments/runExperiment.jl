@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using Agents, CSV, DataFrames, Random, SpatialRust
    using Statistics: std, mean
    include("../../src/ShadingExperiments/Shading.jl")
end

reps = parse(Int, ARGS[1])
mean_temp = parse(Float64, ARGS[2])
rain_prob = parse(Float64, ARGS[3])
wind_prob = parse(Float64, ARGS[4])
shade_placemnt = parse(Int, ARGS[5])
years = parse(Int, ARGS[6])

p = mkpath("results/Shading/ABCests/exp-$mean_temp-$rain_prob-$wind_prob")
filepath = joinpath(p, "r-$reps-$shade_placemnt-$(years)y.csv")

# using Dates
# dayofyear(Date(2017,3,10))

steps = years * 365

singlevals = DataFrame(
    common_map = :none,
    inspect_period = steps,
    fungicide_sch = [Int[]],
    shade_g_rate = 0.008,
    steps = steps,
)

pruningopts = crossjoin(
    DataFrame(post_prune = collect(fill(t, 3) for t in 0.1:0.15:0.7)),
    DataFrame(prune_sch = [[74], [74, 227], [74, 196, 319]]),
)

noprunings = DataFrame(
    post_prune = [Int[], Int[]],
    prune_sch = [Int[], Int[]],
    barriers = [(1,1), (0,0)]
)

if shade_placemnt == 1
    shade_d = 100
    singlevals[!, :shade_d] .= shade_d
    
    pruningopts[!, :barriers] .= [(1,1)]
else
    shade_d = 3 * shade_placemnt
    singlevals[!, :shade_d] .= shade_d
 
    pruningopts = crossjoin(pruningopts, DataFrame(barriers = [(1,1), (0,0)]))
end

append!(pruningopts, noprunings)
repcombin = crossjoin(pruningopts, DataFrame(rep = 1:reps))
conds = hcat(repcombin, repeat(singlevals, nrow(repcombin)))

printinfo = """
        Temp: $mean_temp,
        Rain: $rain_prob,
        Reps: $reps,
        Array #: $shade_placemnt,
        Shade d: $shade_d
    """
println(printinfo)
flush(stdout)

results = shading_experiment(conds, rain_prob, wind_prob, mean_temp)

println("Total sims: $(nrow(results))")

CSV.write(filepath, results)
