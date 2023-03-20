@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using Arrow, CSV, DataFrames, FileTrees
    include("../../../src/ABC/NoVarDistances.jl")
end

# ARGS: min_exh_perc, max_exh_perc, min_incid_perc, min_cor, quantsdirname, qualsdirname
quantsdirname = ARGS[1]
qualsdirname = ARGS[2]
# qldats = parse.(Float64, ARGS[1:4])
# qldats = NamedTuple{(:P1loss, :incidiff, :cor, :P1att, :P12att, :bienniality, :areas, :nls)}([0.1, 0.35, 0.2, -10, 20, -0.01, -0.1, 0.1])
qldats = DataFrame(
    P1loss = 0.1,
    incidiff = 0.35,
    cor = 0.2,
    P1att = -10.0,
    P12att = 20.0,
    bienniality = -0.01,
    areas = -0.1,
    nls = 0.1
)

mkpath("results/ABC/dists/sents/q7")

empdata = DataFrame(Arrow.Table("data/exp_pro/compare/perdate_age_long_10.arrow"))
qntvars = CSV.read("results/ABC/variances/sents/q7/v_gquants.csv", DataFrame)
qlvars = CSV.read("results/ABC/variances/sents/q7/v_quals.csv", DataFrame)
# qlvars[!, :P1loss] .= 1.0
# qlvars[!, :P12loss] .= 1.0
# qlvars[!, :bienniality] .= 1.0


time_dists = @elapsed begin
    l_dists = calc_l_dists(qualsdirname, qldats[1,:], qlvars[1,:])
    nt_dists, nmissings = calc_nt_dists(quantsdirname, empdata, qntvars[1,:])
end
println("Distances: $time_dists")
flush(stdout)

time_joinwrite = @elapsed begin
    # count # observations per stat
    obscounts = count_obs(empdata)
    # scale quant dists by # obs
    scale_dists!(nt_dists, obscounts)
    # join quant and qual dists
    dists = leftjoin(nt_dists, l_dists, on = :p_row)
    # write
    # CSV.write("results/ABC/dists/sents/novar/squareddists.csv", dists)
    CSV.write("results/ABC/dists/sents/q7/squareddists.csv", dists)
    CSV.write("results/ABC/dists/sents/q7/nmissings.csv", nmissings)
end
println("Join+write: $time_joinwrite")
