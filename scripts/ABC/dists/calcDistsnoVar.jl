@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using Arrow, CSV, DataFrames, FileTrees
    include("../../../src/ABC/NoVarDistances.jl")
end

# ARGS: min_exh_perc, max_exh_perc, min_incid_perc, min_cor, quantsdirname, qualsdirname
compare_quals = parse.(Float64, ARGS[1:4])
quantsdirname = ARGS[5]
qualsdirname = ARGS[6]

empdata = CSV.read("data/exp_pro/perdate_age_long.csv", DataFrame, missingstring = "NA")

time_dists = @elapsed begin
    l_dists = calc_l_dists(qualsdirname, compare_quals...)
    nt_dists, nmissings = calc_nt_dists(quantsdirname, empdata)
end
println("Distances: $time_dists")
flush(stdout)

time_joinwrite = @elapsed begin
    # count # observations per stat
    obscounts = count_obs(quantv)
    # scale quant dists by # obs
    scale_dists!(nt_dists, obscounts)
    # join quant and qual dists
    dists = leftjoin(nt_dists, l_dists, on = :p_row)
    # write
    CSV.write("results/ABC/novardists/squareddists.csv", dists)
    CSV.write("results/ABC/novardists/nmissings.csv", nmissings)
end
println("Join+write: $time_joinwrite")
