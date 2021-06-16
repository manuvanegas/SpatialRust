using DrWatson
@quickactivate "SpatialRust"

using CSV, DataFrames, Distributions, Random

Ns = 10^6 # number of parameter combinations to test

file_name = string("parameters_", Ns, ".csv")
par_path = datadir("ABC", file_name)

opt_g_temp = rand(Normal(22.5, 1.0), Ns)
spore_pct = rand(Uniform(), Ns)
fruit_load = rand(Uniform(), Ns)
uv_inact = rand(Uniform(), Ns)
rain_washoff = rand(Uniform(), Ns)
rain_distance = rand(Uniform(0.0, 2.0), Ns)
wind_distance = rand(Uniform(0.0, 8.0), Ns)
parameters = DataFrame(
    RowN = collect(1:Ns), opt_g_temp = opt_g_temp,
    spore_pct = spore_pct, fruit_load = fruit_load,
    uv_inact = uv_inact, rain_washoff = rain_washoff,
    rain_distance = rain_distance, wind_distance = wind_distance)

CSV.write(par_path, parameters)
