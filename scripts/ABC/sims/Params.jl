using DrWatson
@quickactivate "SpatialRust"

using Arrow, CSV, DataFrames, Distributions, Random

Ns = 10^6 # number of parameter combinations to test

file_name = string("parameters_", Ns, ".csv")
arr_file_name = string("parameters_", Ns, ".arrow")
par_path = datadir("ABC", file_name)

# temp_dist = truncated(Normal(22.5, 1.0), 0.0, 38.0)

parameters = DataFrame(
    RowN = collect(1:Ns),
    # opt_g_temp = rand(temp_dist, Ns),
    rust_gr = rand(Uniform(0.0, 2.0), Ns),
    cof_gr = rand(Uniform(), Ns),
    spore_pct = rand(Uniform(), Ns),
    fruit_load = rand(Uniform(), Ns),
    light_inh = rand(Uniform(), Ns),
    rain_washoff = rand(Uniform(), Ns),
    rain_distance = rand(Uniform(0.0, 2.0), Ns),
    wind_distance = rand(Uniform(0.0, 8.0), Ns),
    exhaustion = rand(Uniform(0.0, 25.0), Ns) )

CSV.write(par_path, parameters)
Arrow.write(datadir("ABC", arr_file_name), parameters)
