@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using CSV, DataFrames, SpatialRust
    using StatsBase: sample
    using Statistics: mean, std
    include("../../src/GA/Runner.jl")
end

parnames = [
    :row_d, :plant_d, :shade_d, :barriers, :barrier_rows, :prune_sch, :target_shade,
    :inspect_period, :inspect_effort, :fungicide_sch, :incidence_as_thr, :incidence_thr
]
lnths = [2; 1; 2; 1; 1; fill(5, 3); fill(5,3); 4; 5; fill(5, 3); 1; 5]

popsize = parse(Int, ARGS[1])
gens = parse(Int, ARGS[2])
reps = parse(Int, ARGS[3])
pcross = parse(Float64, ARGS[4])
pmut = parse(Float64, ARGS[5])
steps = parse(Int, ARGS[6])
coffee_price = parse(Float64, ARGS[7])

obj = ARGS[8]

# obj = "longtprofit"
# obj = "shorttprofit"
# obj = "minrustspores"
pdir = mkpath(string("results/GA/", obj))

sdirpop = mkpath(string("/scratch/mvanega1/GA/", obj, "/pops/"))
sdirfit = mkpath(string("/scratch/mvanega1/GA/", obj, "/fitns/"))

ftail = string(popsize, "-", gens, "-", pcross, "-", pmut, ".csv")

finalpop, histbest, histfitm = GA(lnths, parnames, popsize, gens, reps, pcross, pmut, steps, coffee_price, obj)
histfit = DataFrame(histfitm, :auto)

CSV.write(string(pdir, "/finalpop", ftail), finalpop)
CSV.write(string(pdir, "/histbest", ftail), histbest)
CSV.write(string(pdir, "/histfit", ftail), histfit)
