@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere begin
    using Arrow, DataFrames, Distributed, OnlineStats
    using CSV
    include(srcdir("ABC/Variances.jl"))
end

# calculate variance from sim outputs
time_vars = @elapsed begin
    σ2_ages, σ2_cycles, σ2_prod = σ2("/scratch/mvanega1/ABC/sims/")
    # write csvs
    CSV.write(projectdir("results/ABC/variances/v_ages.csv"), σ2_ages)
    CSV.write(projectdir("results/ABC/variances/v_cycles.csv"), σ2_cycles)
    CSV.write(projectdir("results/ABC/variances/v_prod.csv"), σ2_prod)
end
println("Variance: $time_vars")
