using DrWatson
@quickactivate "SpatialRust"

@everywhere using Agents, Random, StatsBase, DataFrames, CSV, Distributed

@everywhere include(srcdir("OneFarm.jl"))
@everywhere include(srcdir("FarmRunner.jl"))
@everywhere include(srcdir("CoffeeGA.jl"))
mkpath(projectdir("results","track"))

pop, hist_fitness = myGA(run_farm_ind, 31, 80, 80, 0.03, 0.7, 30)
# pop, hist_fitness = myGA(run_farm_ind, 31, 40, 40, 0.03, 0.6)
# pop, hist_fitness = myGA(run_farm_ind, 31, 2, 2, 0.03, 0.7, 2)

hist_fit = convert(DataFrame, hist_fitness)
CSV.write(projectdir("results","out_fitness.csv"), hist_fit)
final_pop = convert(DataFrame, pop)
CSV.write(projectdir("results","out_pop.csv"), final_pop)
