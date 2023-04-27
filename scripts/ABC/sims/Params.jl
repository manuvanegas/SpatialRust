using DrWatson
@quickactivate "SpatialRust"

using Arrow, CSV, DataFrames, Distributions, Random

Ns = 10^6 # number of parameter combinations to test

newid = "12"
arr_file_name = string("parameters_", newid, ".arrow")
par_path = datadir("ABC", file_name)

opt_temp_distr = Normal(23.0, 0.5) # Motisi et al, 2022
amp_temp_distr = Normal(5.0, 0.5) # Waller, 1982; Merle et al, 2020 
# max_temp_dist = truncated(Normal(30.0, 1.0), 22.0, 38.0)
sporepct_distr = Normal(0.35, 0.05) # McCain & Hennen, 1984
washoff_distr = truncated(Normal(0.25, 0.04), 0.15, 0.35) # Avelino et al, 2020
tempcool_distr = Normal(4.0, 0.5) # Merle et al., 2022
viabloss_distr = Normal(0.75, 0.02) # Nutman et al., 1963

parameters = DataFrame(
    p_row = collect(1:Ns),
    shade_block = rand(Uniform(), Ns),
    wind_dst = rand(Uniform(1.0, 3.0), Ns),
    tree_block = rand(Uniform(), Ns),
    rain_dst = rand(Uniform(0.0, 3.0), Ns),
    les_surv = rand(Uniform(), Ns),
    rust_paras = rand(Uniform(0.0, 1.0), Ns),  #(0.0,0.02)
    spore_pct = rand(sporepct_distr, Ns),
    rust_gr = rand(Uniform(0.0, 0.2), Ns), #()
    rep_gro = rand(Uniform(0.0, 1.0), Ns), #(0,2)
    pdry_spo = rand(Uniform(0.5, 1.0), Ns),
    rep_spo = rand(Uniform(0, 1.0), Ns),
    # host_spo_inh = rand(Uniform(0.0,2.0), Ns), #(0,2)
    # rain_washoff = rand(washoff_distr, Ns),
    light_inh = rand(Uniform(), Ns),
    # viab_loss = rand(viabloss_distr, Ns),
    rep_inf = rand(Uniform(0, 2.0), Ns),
    max_inf = rand(Uniform(0.0, 2.0), Ns), #()
    temp_cooling = rand(tempcool_distr, Ns),
    # μ_prod = rand(Uniform(0.0, 0.05), Ns),
    # res_commit = rand(Uniform(0.0, 0.5), Ns),
    # μ_prod = vcat(fill(0.25, div(Ns,2)), fill(0.3, div(Ns,2))),
    # res_commit = vcat(fill(0.01, div(Ns,2)), fill(0.008, div(Ns,2))),
    # max_g_temp = rand(max_temp_dist, Ns),
    # opt_g_temp = rand(opt_temp_distr, Ns),
    temp_ampl = rand(amp_temp_distr, Ns),
    opt_temp = rand(opt_temp_distr, Ns),
)

parameters[!, :wind_dst] = parameters[!, :rain_dst] .* parameters[!, :wind_dst]

Arrow.write(datadir("ABC", arr_file_name), parameters)
