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
years = parse(Int, ARGS[5])

mkpath("results/Shading/ABCests/exp2-$mean_temp-$rain_prob")
filename = "results/Shading/ABCests/exp2-$mean_temp-$rain_prob/r-$reps-$shade_placemnt-$(years)y.csv"

abcpars = CSV.read("results/ABC/params/sents/q8/byoccnl_pointestimate.csv", DataFrame)


# using Dates
# dayofyear(Date(2017,3,10))

steps = years * 365 + 1

singlevals = hcat(DataFrame(
        common_map = :none,
        inspect_period = steps,
        fungicide_sch = [Int[]],
        shade_g_rate = 0.008,
        steps = steps,
        mean_temp = mean_temp,
        rain_prob = rain_prob,
        wind_prob = 0.7
    ),
    abcpars
)

if shade_placemnt == 1
    shade_d = 100
    singlevals[!, :shade_d] .= shade_d
    
    crossed = crossjoin(
        DataFrame(target_shade = collect(fill(t, 3) for t in 0.15:0.15:0.75)),
        DataFrame(prune_sch = [[15,196], [74, 196, 319]]),
        DataFrame(rep = 1:reps)
    )
    crossed[!, :barriers] .= [(1,1)]
    append!(crossed, DataFrame(
        barriers = repeat([(1,1), (0,0)], inner = reps),
        target_shade = repeat([Int[], Int[]], inner = reps),
        prune_sch = repeat([Int[]], reps * 2),
        rep = repeat(1:reps, 2)
    ))
else
    shade_d = 3 * shade_placemnt
    singlevals[!, :shade_d] .= shade_d
 
    crossed = crossjoin(
        DataFrame(target_shade = collect(fill(t, 3) for t in 0.15:0.15:0.75)),
        DataFrame(prune_sch = [[15,196], [74, 196, 319]]),
        DataFrame(barriers = [(1,1), (0,0)])
    )
    append!(crossed, DataFrame(
        target_shade = [Int[], Int[]],
        prune_sch = [Int[], Int[]],
        barriers = [(1,1), (0,0)]
        )
    )
    crossed = crossjoin(crossed, DataFrame(rep = 1:reps))
end

conds = hcat(crossed, repeat(singlevals, nrow(crossed)))

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
