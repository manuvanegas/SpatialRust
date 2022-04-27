@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere begin
    using Arrow, CSV, DataFrames, Distributed, FileTrees
    include(srcdir("ABC/Distances.jl"))
end
#ARGS: calculate variances?(Bool)

# joining area by age and spore by age data
# ages = CSV.read("data/exp_pro/compare/Sun_Areas_Age.csv", DataFrame)[:, 2:5]
# spores = CSV.read("data/exp_pro/compare/Sun_Spore_Age.csv", DataFrame)[:, 2:5]
# agespores = leftjoin(ages, spores, on = [:day_n, :age_week, :sample_cycle])
# CSV.write("data/exp_pro/compare/Sun_AreaSpore_Age.csv", agespores)

time_joins = @elapsed begin
    # load field data
    ages = CSV.read("data/exp_pro/compare/Sun_AreaSpore_Age.csv", DataFrame)
    cycles = CSV.read("data/exp_pro/compare/Sun_Appr_Areas_Fallen.csv", DataFrame)[:, [2,3,4,5,7]]
    cprod = CSV.read("data/exp_pro/compare/Sun_Plant_Production.csv", DataFrame)[:, 2:4]

    # load variance files
    if isfile(projectdir("results/ABC/variances/v_ages_c.csv"))
        σ2_ages = CSV.read(projectdir("results/ABC/variances/v_ages_c.csv"), DataFrame)
        σ2_cycles = CSV.read(projectdir("results/ABC/variances/v_cycles_c.csv"), DataFrame)
    else
        σ2_ages = CSV.read(projectdir("results/ABC/variances/v_ages.csv"), DataFrame)
        σ2_cycles = CSV.read(projectdir("results/ABC/variances/v_cycles.csv"), DataFrame)
        correct_cycles!.((σ2_ages, σ2_cycles))
        CSV.write(projectdir("results/ABC/variances/v_ages_c.csv"), σ2_ages)
        CSV.write(projectdir("results/ABC/variances/v_cycles_c.csv"), σ2_cycles)
    end
    σ2_prod = CSV.read(projectdir("results/ABC/variances/v_prod.csv"), DataFrame)

    # join variances into field data
    leftjoin!(ages, σ2_ages, on = [:day_n => :tick, :sample_cycle => :cycle, :age_week => :age])
    # leftjoin!(ages, σ2_ages, on = [:day_n => :tick, :age_week => :age])
    leftjoin!(cycles, σ2_cycles, on = [:day_n => :tick, :sample_cycle => :cycle])
    leftjoin!(cprod, σ2_prod, on = [:day_n => :tick])
end
println("Joins: $time_joins")

# make sure that every empirical data point has its variance
anymissings = [find_missings(ages), find_missings(cycles), find_missings(cprod)]
if any(anymissings)
    anymissings[1] && CSV.write("missing_ages.csv", ages)
    anymissings[2] && CSV.write("missing_cycles.csv", cycles)
    anymissings[3] && CSV.write("missing_prod.csv", cprod)
    error("something's missing")
end

time_dists = @elapsed begin
    # pass joined data to calculate distances
    dists = calc_dists(ages, cycles, cprod)

    CSV.write(projectdir("results/ABC/dists.csv"), dists)
end
println("Distances: $time_dists")
