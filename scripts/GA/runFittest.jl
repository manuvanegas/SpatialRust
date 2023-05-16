import Pkg
Pkg.activate(".")
using CSV, DataFrames, DelimitedFiles, SpatialRust
include("../../src/GA/GARuns.jl")

pcross = parse(Float64, ARGS[1])
pmut = parse(Float64, ARGS[2])
obj = ARGS[3]
rem = parse(Float64, ARGS[4])

fitness = CSV.read("results/GA2/$obj-$pcross-$pmut/fitnesshistory.csv", DataFrame, header = false)[end,:]
lastpopf = readdir("/scratch/mvanega1/GA2/$obj-$pcross-$pmut/pops/", join = true, sort = true)[end]
lastpop = readdlm(lastpopf, ',', Bool);

indcol = argmax(stack(fitness))
pars = transcripts(lastpop[:, indcol])

println("Fittest ind is $indcol.
Pars = $pars")

df = garuns(150, 1460, rem; pars...)

CSV.write("results/GA2/$obj-$pcross-$pmut/fittest.csv", df)
