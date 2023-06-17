using CairoMakie, CSV, DataFrames, Statistics

include("../../src/GA/Plots.jl")

# obj = "shorttermprofit-0.0"
# obj = "longtermprofit-0.2"
# pcross = 0.5
# pmut = 0.02

# fitness = CSV.read("results/GA/4/$obj/fitnesshistory-80.csv", DataFrame, header = false);


plotfit("profit-np", 125)
plotfit("profit-p", 125)
plotfit("sev-np", 125)
plotfit("sev-p", 125)


plotfit("profit-np-s", 115)
plotfit("profit-p-s", 115)
plotfit("sev-np-s", 115)
plotfit("sev-p-s", 115)


fitfig = fitfigure("results/GA/4/2/", exps, poss, 125)
savedissGA("fit8.png", fitfig)
