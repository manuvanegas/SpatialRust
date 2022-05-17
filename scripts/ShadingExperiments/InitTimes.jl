thetime =@elapsed begin
@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere begin
using Agents, CSV, DataFrames, Distributed
using SpatialRust
include("../../src/ShadingExperiments/Shading.jl")
end
end

ntasks = ARGS[1]

println("Time to init with $ntasks ntasks: $thetime")
