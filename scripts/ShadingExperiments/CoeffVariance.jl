using DrWatson
@quickactivate "SpatialRust"
using Agents, CSV, DataFrames, Distributed
using StatsBase: sample
using SpatialRust

include("src/ShadingExperiments/NumberOfRuns.jl")
mkpath("results/Shading")

mean_temp = parse(Int, ARGS[2])
rain_prob = parse(Int, ARGS[3])

cvs = coeff_vars(parse(Int, ARGS[1]), mean_temp, rain_prob)

CSV.write(projectdir("results/Shading/CVs-$mean_temp-$rain_prob.csv"), cvs)
