using CairoMakie, CSV, DataFrames, Statistics

include("../../src/GA/Plots.jl")

obj = "shorttprofit"
obj = "longtprofit"
pcross = 0.5
pmut = 0.02

fitness = CSV.read("results/GA/$obj-$pcross-$pmut/fitnesshistory.csv", DataFrame, header = false)

summfitness = select(fitness,
    AsTable(:) => ByRow(mean) => :meanfit,
    AsTable(:) => ByRow(maximum) => :maxfit,
    AsTable(:) => ByRow(std) => :sd,
    eachindex => :gen
)

plotfit(summfitness)



