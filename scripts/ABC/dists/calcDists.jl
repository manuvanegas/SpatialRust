@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere begin
    using Arrow, DataFrames, Distributed, FileTrees, OnlineStats
    using CSV
    include("src/ABC/Variances.jl")
    include("src/ABC/Distances.jl")
    # include("src/ABC/Ranks.jl")
end
#ARGS: calculate variances?(Bool)

# load field data
ages = CSV.read("data/exp_pro/compare/Sun_Areas_Age.csv")
cycles = CSV.read("data/exp_pro/compare/Sun_Appr_Areas_Fallen.csv")
prod = CSV.read("data/exp_pro/compare/Sun_Plant_Production.csv")


# calculate variance from sim outputs
time_vars = @elapsed begin
    if !isfile("results/ABC/variances/v_ages.csv") && parse(Bool, ARGS[1])
        folders = [:ages, :cycles, :prod]
        σ2s_ages = σ2(:ages)
        σ2s_cycles = σ2(:cycles)
        σ2s_prod = σ2(:prod)
        # write csvs
        CSV.write("results/ABC/variances/v_ages.csv", σ2_ages)
        CSV.write("results/ABC/variances/v_cycles.csv", σ2_cycles)
        CSV.write("results/ABC/variances/v_prod.csv", σ2_prod)
    else
        σ2s_ages = CSV.read("results/ABC/variances/v_ages.csv")
        σ2s_cycles = CSV.read("results/ABC/variances/v_cycles.csv")
        σ2s_prod = CSV.read("results/ABC/variances/v_prod.csv")
    end
end
println("Variance: $time_vars")

time_joins = @elapsed begin
    # join variances into field data
    leftjoin!(ages, σ2_ages)
    leftjoin!(cycles, σ2_cycles)
    leftjoin!(prod, σ2_prod)

    # make sure that every empirical data point has its variance
    missings = [any(ismissing(ages)), any(ismissing(cycles)), any(ismissing(prod))]
    if any(missings)
        missings[1] && CSV.write("missing_ages.csv", ages)
        missings[2] && CSV.write("missing_cycles.csv", cycles)
        missings[3] && CSV.write("missing_prod.csv", prod)
        error("something's missing")
    end
end
println("Joins: $time_joins")

time_dists = @elapsed begin
    # pass joined data to calculate distances
    dists = calc_dists(ages, cycles, prod)

    CSV.write("ABCdists.csv", dists)
end
println("Distances: $time_dists")
