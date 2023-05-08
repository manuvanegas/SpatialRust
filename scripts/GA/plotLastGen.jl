using CairoMakie, CSV, DataFrames, DelimitedFiles, Statistics
using SpatialRust
include("../../src/GA/Plots.jl")
include("../../src/GA/FittestRun.jl")

obj = "shorttprofit"
obj = "longtermprofit"
pcross = 0.5
pmut = 0.02

lastpopf = readdir("results/GA/$obj-$pcross-$pmut/pops/", join = true, sort = true)[end]
lastpop = readdlm(lastpopf, ',', Bool);

function transcripts(col)
    pos = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:19, 20:25, 26:31, 32:37, 38:43, 44:48, 49:54, 55:60, 61:66, 67:72, 73:73, 74:79]
    transcripts = [bits_to_int(col[p]) for p in pos]
    transcripts[[1:3; 5]] .+= 1
    return ints_to_pars(transcripts, 1460, 1.0)
end

parsdf = DataFrame(map(transcripts, eachcol(lastpop)));
transform!(parsdf, eachindex => :indiv)

fitness = CSV.read("results/GA/$obj-$pcross-$pmut/fitnesshistory.csv", DataFrame, header = false);
lastfitns = DataFrame(indiv = 1:ncol(fitness), fitns = stack(fitness[end,:]))

# lastfitns = DataFrame(indiv = 1:30, fitns = vec(readdlm("results/GA/shorttprofit3032-0.5-0.02/g-032.csv",',')))

leftjoin!(parsdf, lastfitns, on = :indiv)

bestpars = subset(parsdf, :fitns => ByRow(==(maximum(parsdf.fitns))))
sort(parsdf, :fitns, rev = true)[1:5,:]

bdf = garuns(1, 1460, 0.48; bestpars[1,Not([:indiv,:fitns])]...)

lines(bdf.dayn, bdf.production)
lines(bdf.dayn, bdf.sumarea)
lines(bdf.dayn, bdf.sporearea)
lines(bdf.dayn, bdf.fung)
lines(bdf.dayn, bdf.active)
lines(bdf.dayn, bdf.remprofit)
lines(bdf.dayn, bdf.remprofit .- bdf.costs)
lines(bdf.dayn, bdf.incidence)
lines!(bdf.dayn, bdf.obs_incidence)
current_figure()
