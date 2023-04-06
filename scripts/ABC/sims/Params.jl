using DrWatson
@quickactivate "SpatialRust"

using Arrow, CSV, DataFrames, Distributions, Random

Ns = 10^6 # number of parameter combinations to test

newid = 9
file_name = string("parameters_", newid, ".csv")
arr_file_name = string("parameters_", newid, ".arrow")
par_path = datadir("ABC", file_name)

opt_temp_dist = truncated(Normal(22.0, 1.0), 14.0, 30.0)
max_temp_dist = truncated(Normal(30.0, 1.0), 22.0, 38.0)

parameters = DataFrame(
    p_row = collect(1:Ns),
    shade_block = rand(Uniform(), Ns),
    # wind_distance = rand(Uniform(5.0, 20.0), Ns),
    tree_block = rand(Uniform(), Ns),
    rain_distance = rand(Uniform(0.0, 10.0), Ns),
    lesion_survive = rand(Uniform(), Ns),
    max_inf = rand(Uniform(), Ns),
    spore_pct = rand(Uniform(), Ns),
    host_spo_inh = rand(Uniform(), Ns),
    rep_gro = rand(Uniform(), Ns),
    rust_gr = rand(Uniform(0.0, 0.3), Ns),
    rust_paras = rand(Uniform(0.0, 0.1), Ns),
    exh_threshold = rand(Uniform(0.0, 1.5), Ns),
    # μ_prod = rand(Uniform(0.0, 0.05), Ns),
    # res_commit = rand(Uniform(0.0, 0.5), Ns),
    μ_prod = vcat(fill(0.25, div(Ns,2)), fill(0.3, div(Ns,2))),
    res_commit = vcat(fill(0.01, div(Ns,2)), fill(0.008, div(Ns,2))),
    max_g_temp = rand(max_temp_dist, Ns),
    opt_g_temp = rand(opt_temp_dist, Ns),

    # temp_cooling = 
    # light_inh = 
    # rain_washoff = 
)

checktemps = true

while checktemps
    filter!([:opt_g_temp, :max_g_temp] => (opt, max) -> opt < max, parameters)
    remrows = nrow(parameters)
    if remrows == Ns
        checktemps = false
    else
        newrows = Ns - remrows
        append!(parameters,
        DataFrame(
            p_row = filter(n -> n ∉ parameters[:, :p_row], 1:Ns),
            max_inf = rand(Uniform(), newrows),
            host_spo_inh = rand(Uniform(0.0, 20.0), newrows),
            opt_g_temp = rand(opt_temp_dist, newrows),
            max_g_temp = rand(max_temp_dist, newrows),
            spore_pct = rand(Uniform(), newrows),
            rust_paras = rand(Uniform(), newrows),
            exh_threshold = rand(Uniform(0.0, 1.5), newrows),
            rain_distance = rand(Uniform(0.0, 10.0), newrows),
            tree_block = rand(Uniform(), newrows),
            # wind_distance = rand(Uniform(0.0, 20.0), newrows),
            shade_block = rand(Uniform(), newrows),
            lesion_survive = rand(Uniform(), newrows),
        
            # temp_cooling = 
            # light_inh = 
            # rain_washoff = 
            # rep_gro = 
        ))
    end
end

parameters[!, :wind_distance] = parameters[!, :rain_distance] .* 2.0

CSV.write(par_path, parameters)
Arrow.write(datadir("ABC", arr_file_name), parameters)
