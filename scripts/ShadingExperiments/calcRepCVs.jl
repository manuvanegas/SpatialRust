# @everywhere using DrWatson
# @everywhere @quickactivate "SpatialRust"
@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using Agents, CSV, DataFrames, SpatialRust
    # using StatsBase: sample
    using Statistics: std, mean
    include("../../src/ShadingExperiments/NumberOfRuns.jl")
end

mkpath("results/Shading/ABCests/CV")

n = parse(Int, ARGS[1]) # n > 100
mean_temp = parse(Float64, ARGS[2])
rain_prob = parse(Float64, ARGS[3])

cvs = coeff_vars(n, mean_temp, rain_prob)

CSV.write("results/Shading/ABCests/CV/CVs-$mean_temp-$rain_prob-$n.csv", cvs)