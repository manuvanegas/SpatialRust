@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere begin
using Agents, CSV, DataFrames, Distributed
using StatsBase: sample
using Statistics: std, mean
using SpatialRust
include("../../src/ShadingExperiments/NumberOfRuns.jl")
end

mkpath("results/Shading")

n = parse(Int, ARGS[1]) # n > 100
mean_temp = parse(Float64, ARGS[2])
rain_prob = parse(Float64, ARGS[3])

cvs = coeff_vars(n, mean_temp, rain_prob)

CSV.write(projectdir("results/Shading/CVs-$mean_temp-$rain_prob-$n.csv"), cvs)
