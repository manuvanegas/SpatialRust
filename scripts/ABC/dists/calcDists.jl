@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using Arrow, CSV, DataFrames, FileTrees
    include("../../../src/ABC/Distances.jl")
end

#ARGS: exh_perc, corr_coeff, quantsdirname, qualsdirname
exh_perc = parse(Float64, ARGS[1])
corr_coeff = parse(Float64, ARGS[2])
quantsdirname = ARGS[3]
qualsdirname = ARGS[4]

# load data + var files
qualv = CSV.read("results/ABC/variances/v_quals.csv", DataFrame)
quantv = CSV.read(
    "results/ABC/variances/v_quants.csv", DataFrame, 
    skipto = 2,
    header = [:dayn, :age, :plot, :area_dat, :spore_dat, :nl_dat, :occup_dat, :area_var, :spore_var, :nl_var, :occup_var],
    types = Dict(:plot => Symbol)
)
gquantv = CSV.read("results/ABC/variances/v_gquants.csv", DataFrame)

time_dists = @elapsed begin
    l_dists = calc_l_dists(qualv, repeat([exh_perc, corr_coeff], 3), qualsdirname)
    nt_dists, gnt_dists, nmissings = calc_nt_dists(quantv, gquantv, quantsdirname)
end
println("Distances: $time_dists")
flush(stdout)

time_joinwrite = @elapsed begin
    # count # observations per stat
    obscounts = count_obs(quantv)
    # scale quant dists by # obs
    scale_dists!(nt_dists, obscounts)
    scale_dists!(gnt_dists, obscounts)
    # join quant and qual dists
    dists = leftjoin(nt_dists, l_dists, on = :p_row)
    gdists = leftjoin(gnt_dists, l_dists, on = :p_row)
    # write
    CSV.write("results/ABC/dists/squareddists.csv", dists)
    CSV.write("results/ABC/dists/gsquareddists.csv", gdists)
    CSV.write("results/ABC/dists/nmissings.csv", nmissings)
end
println("Join+write: $time_joinwrite")
