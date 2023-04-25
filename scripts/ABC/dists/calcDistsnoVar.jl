@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using Arrow, CSV, DataFrames, FileTrees
    using StatsBase: mean
    include("../../../src/ABC/NoVarDistances.jl")
end

# ARGS: quantsdirname, qualsdirname
quantsdirname = ARGS[1]
qualsdirname = ARGS[2]
qldats = (
    P12loss = [0.3, 0.85], #
    LP = [25, 65],
    incid = [0.7, 1.01],
    rusts = [10, 5001],
    meandeps = [-10.0, 0.001],
    meanlatent = [-0.001, 10.0], ##
    cor = [0.2, 0.95], # ##
)
# qldats = DataFrame(
#     P1att = [-0.005, 0.6], #
#     bienniality = [-0.01, 1.0],
#     Pattpct = [0.0, 0.25],
#     areas = [-0.1, 25.0],
#     nls = [-25.0, 0.1],
#     P1loss = [0.1, 0.65], ##
#     P12loss = [1.1, 0.95], # ##
#     incidiff = [0.35, 1.0],
#     cor = [0.2, 0.95]
# )

v = "10a"

mkpath(string("results/ABC/dists/sents/", v))

empdata = DataFrame(Arrow.Table("data/exp_pro/v2/compare.arrow"))
# qntvars = CSV.read("results/ABC/variances/sents/q9/v_gquants.csv", DataFrame)
# qlvars = CSV.read("results/ABC/variances/sents/q9/v_quals.csv", DataFrame)

time_dists = @elapsed begin
    l_dists = calc_l_dists(qualsdirname, qldats)
    nt_dists, nmissings = calc_nt_dists(quantsdirname, empdata)
    # l_distsn, l_distsv = calc_l_dists(qualsdirname, qldats, qlvars[1,:])
    # nt_dists, nmissings = calc_nt_dists(quantsdirname, empdata, qntvars[1,:])
end
println("Distances: $time_dists")
flush(stdout)

time_joinwrite = @elapsed begin
    # count # observations per stat
    # obscounts = count_obs(empdata)
    # scale quant dists by # obs
    # scale_dists!(nt_dists, obscounts)
    # join quant and qual dists
    ndists = leftjoin(nt_dists, l_dists, on = :p_row)
    # vdists = leftjoin(nt_dists, l_distsv, on = :p_row)
    # write
    # CSV.write("results/ABC/dists/sents/novar/squareddists.csv", dists)
    CSV.write(string("results/ABC/dists/sents/", v, "/squareddists.csv"), ndists)
    # CSV.write(string("results/ABC/dists/sents/", v, "/squareddists_v.csv"), vdists)
    CSV.write(string("results/ABC/dists/sents/", v, "/nmissings.csv"), nmissings)
end
println("Join+write: $time_joinwrite")
