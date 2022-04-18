using Arrow, CSV, DataFrames, StatsPlots

include("Ranks.jl")

dists = CSV.read("results/ABC/dists.csv", DataFrame)

parameters = DataFrame(Arrow.Table(string("data/ABC/", "parameters_", 10^6, ".arrow")))

thenames = names(parameters)[2:10]
@df parameters[1:100,:] violin(cols(2:10), ticks= thenames)

@df parameters[1:100,:] boxplot(y = cols(2:10))

@df parameters[1:100, :] violin(xlabel = "opt", :opt_g_temp)


@df parameters[1:100, :] violin(:opt_g_temp)
@df parameters[1:100, :] violin!(:max_cof_gr)

using CairoMakie

sparam = stack(parameters)

@df sparam violin(:variable, :value)
