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

n = parse(Int, ARGS[1]) * parse(Int, ARGS[4]) # n > 10
mean_temp = parse(Float64, ARGS[2])
rain_prob = parse(Float64, ARGS[3])

cvs = coeff_vars(n, mean_temp, rain_prob)

CSV.write(projectdir("results/Shading/CVs-$mean_temp-$rain_prob.csv"), cvs)

## Plot it
using CairoMakie

cvs = CSV.read(projectdir("results/Shading/CVs-22.5-0.8.csv"), DataFrame)

fig = Figure()
ax = Axis(fig[1,1], xlabel = "Number of runs", ylabel = "CV")
lines!(ax, cvs.n, cvs.prod, label = "Coffee Production CV")
lines!(ax, cvs.n, cvs.area, label = "Max Rust Area CV")
axislegend()
fig

save("plots/Shading/CVs.png", fig)
