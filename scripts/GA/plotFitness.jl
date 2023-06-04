using CairoMakie, CSV, DataFrames, Statistics

include("../../src/GA/Plots.jl")

obj = "shorttermprofit"
obj = "longtermprofit2"
pcross = 0.5
pmut = 0.02

fitness = CSV.read("results/GA/3/$obj-$pcross-$pmut/fitnesshistory-125.csv", DataFrame, header = false)

summfitness = select(fitness,
    AsTable(:) => ByRow(mean) => :meanfit,
    AsTable(:) => ByRow(maximum) => :maxfit,
    AsTable(:) => ByRow(std) => :sd,
    eachindex => :gen
)

plotfit(summfitness)



