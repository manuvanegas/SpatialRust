using DrWatson
@quickactivate "SpatialRust"

using Arrow, CSV, DataFrames, Distributions, Random

Ns = 10^6 # number of parameter combinations to test

newid = "16"
arr_file_name = string("parameters_", newid, ".arrow")

opt_temp_distr = Normal(23.0, 0.5) # Motisi et al, 2022
amp_temp_distr = Normal(5.0, 0.5) # Waller, 1982; Merle et al, 2020
sporepct_distr = Normal(0.35, 0.05) # McCain & Hennen, 1984
# tempcool_distr = Normal(4.0, 0.5) # Merle et al., 2022

parameters = DataFrame(
    p_row = collect(1:Ns),
    shade_block = rand(Uniform(), Ns),
    wind_dst = rand(Uniform(4.0, 8.0), Ns),
    tree_block = rand(Uniform(), Ns),
    rain_dst = rand(Uniform(0.0, 3.0), Ns),
    les_surv = rand(Uniform(), Ns),
    rust_paras = rand(Uniform(0.0, 0.5), Ns),  #(0.0,0.02)
    spore_pct = rand(sporepct_distr, Ns),
    rust_gr = rand(Uniform(0.0, 0.2), Ns), #()
    rep_gro = rand(Uniform(0.0, 0.5), Ns), #(0,2)
    pdry_spo = rand(Uniform(0.5, 1.0), Ns),
    rep_spo = rand(Uniform(0, 1.0), Ns),
    light_inh = rand(Uniform(), Ns),
    rep_inf = rand(Uniform(0, 2.0), Ns),
    max_inf = rand(Uniform(0.0, 2.0), Ns),
    temp_cooling = rand(Uniform(0.5, 2.5), Ns),
    temp_ampl = rand(amp_temp_distr, Ns),
    opt_temp = rand(opt_temp_distr, Ns),
)

# parameters[!, :wind_dst] = parameters[!, :rain_dst] .* parameters[!, :wind_dst]

Arrow.write(datadir("ABC", arr_file_name), parameters)
