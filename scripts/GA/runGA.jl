# @everywhere begin
#     using Pkg
#     Pkg.activate(".")
# end
# @everywhere begin
    using CSV, DataFrames, SpatialRust
    using StatsBase: sample
    using Statistics: mean, std
    include("../../src/GA/Runner.jl")
# end

popsize = 10
gens = 20
reps = 3
pcross = 0.5
pmut = 0.1

popsize = parse(Int, ARGS[1])
gens = parse(Int, ARGS[2])
reps = parse(Int, ARGS[3])
pcross = parse(Float64, ARGS[4])
pmut = parse(Float64, ARGS[5])

obj_fun = farm_profit(2191, 1.0)
# obj_fun = yearly_spores(2191)

pdir = mkpath("results/GA/longtprofit")
ftail = string(popsize, "-", gens, "-", pcross, "-", pmut, ".csv")

finalpop, histbest, histfitm = GA(lnths, tparnames, popsize, gens, reps, pcross, pmut, obj_fun)
histfit = DataFrame(histfitm, :auto)

CSV.write(string(pdir, "/finalpop", ftail), finalpop)
CSV.write(string(pdir, "/histbest", ftail), histbest)
CSV.write(string(pdir, "/histfit", ftail), histfit)
