@everywhere begin
    using Pkg
    Pkg.activate(".")
end
time_load = @elapsed begin
    @everywhere begin
        using Arrow, CSV, DataFrames, Distributed, OnlineStats, OnlineStatsBase
        include("../../../src/ABC/Variances.jl")
    end
end
println("Load: $time_load")

mkpath("results/ABC/variances")

# calculate variance from sim outputs
time_read = @elapsed begin
    quantdata = CSV.read("data/exp_pro/compare/perdateage_age.csv", DataFrame, missingstring = "NA")
end
println("Read: $time_read")
flush(stdout)

if length(ARGS) == 1
    time_vars = @elapsed σ2_quants, σ2_quals, n_quants, n_quals = σ2("/scratch/mvanega1/ABC/sims/", parse(Int, ARGS[1]))
else
    time_vars = @elapsed σ2_quants, σ2_quals, n_quants, n_quals = σ2("/scratch/mvanega1/ABC/sims/")
end

time_join = @elapsed begin
    n_quants = leftjoin(σ2_quants[:, [1,2]], n_quants, on = [:dayn, :age])
    sort!(n_quants, [:dayn, :age])
    σ2_quants = leftjoin(quantdata, σ2_quants, on = [:dayn, :age])
    select!(σ2_quants,
        [1,2,4,11,8,15,5,12,9,16,3,13,7,17,6,14,10,18] .=> 
        [
            :dayn, :age,
            :area_sun_dat, :area_sun_var, :area_sh_dat, :area_sh_var,
            :spore_sun_dat, :spore_sun_var, :spore_sh_dat, :spore_sh_var,
            :nl_sun_dat, :nl_sun_var, :nl_sh_dat, :nl_sh_var,
            :occup_sun_dat, :occup_sun_var, :occup_sh_dat, :occup_sh_var
        ]
    )
    sort!(σ2_quants, [:dayn, :age])
    # newer DataFrames versions have an order keyword for joins, so only one sort! would be needed
    # but I don't want to rebuild the sysimage with the new pkg version now 
end
println("Variance: $time_vars")
println("Join: $time_join")
flush(stdout)

time_write = @elapsed begin
    # write csvs
    CSV.write("results/ABC/variances/v_quants.csv", σ2_quants)
    CSV.write("results/ABC/variances/v_quals.csv", σ2_quals)
    CSV.write("results/ABC/variances/n_quants.csv", n_quants)
    CSV.write("results/ABC/variances/n_quals.csv", n_quals)
end
println("Write: $time_write")
