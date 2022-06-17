module SpatialRust

using Agents, Distributions, Random, StaticArrays
using DataFrames
using DrWatson: srcdir, datadir
using StatsBase: sample, weights

include(srcdir("ABM/Initialize.jl"))
include(srcdir("ABM/Setup.jl"))
include(srcdir("ABM/Step.jl"))

include(srcdir("ABM/CGrowerSteps.jl"))
include(srcdir("ABM/FarmMap.jl"))
include(srcdir("ABM/RustDispersal.jl"))
include(srcdir("ABM/RustGrowth.jl"))
include(srcdir("ABM/ShadeSteps.jl"))

include(srcdir("QuickRuns.jl"))
include(srcdir("QuickMetrics.jl"))

include(srcdir("ABC", "Sims.jl"))

precompile(dummyrun_spatialrust, (Int, Int, Int))
end
#
# function dummyrun_spatialrust()
#     pars = Parameters(steps = 50, map_side = 20)
#     model = init_spatialrust(pars, create_farm_map(FarmSpace(map_dims = 20, shade_percent = 0.0)), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
#     run!() ## ...
# end
#
#
# pars = Parameters(steps = 50, map_side = 100)
#
#
# rdd, pdd = rust_df, plant_df = abc_run!(model, step_model!, 231;
#     when_rust = when_rust, when_prod = when_plant, rust_data = [d_per_ages, d_per_cycles], prod_data = prod_metrics)
#
# paramss = crd(datadir("ABC", "parameters_10.csv"), DataFrame)
# for rr in eachrow(paramss)[1:2]
#     sim_and_write(rr, rain_data, temp_data, when_rust, when_plant, 0.5, 231)
# end
# # add, mdd = run!(model, dummystep, step_model!, 10;
# #     adata = [(x) -> (x.shade_neighbors[i]) for i in 1:2],
# #     when_model = when_collect, mdata = [areas_per_age, total_lesion_area, coffee_production])
#
# Juno.@profiler for i in 1:2
#     pars = Parameters(steps = 400, map_side = 100, switch_cycles = copy(when_cycle))
#     model = init_spatialrust(pars, create_fullsun_farm_map(), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
#     custom_sampling!(model, 0.05, 1)
#     add, mdd = run!(model, dummystep, step_model!, 400; when_model = when_collect, mdata = [fallen_coffees, total_lesion_area, coffee_production])
# end
#
# @benchmark init_spatialrust(pars, create_fullsun_farm_map(), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
#
# include(srcdir("ABMstep.jl"))
# include(srcdir("ABCrun.jl"))
# include(srcdir("CustomRun.jl"))
#
# #export initialize_sim, step_model!, run_for_abc, Shade, Coffee, Rust
# #end
#
#
# function dummyrun_spatialrust()
#     pars = Parameters(steps = 50, map_side = 20)
#     model = init_spatialrust(pars, create_farm_map(FarmSpace(map_dims = 20, shade_percent = 0.0)), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
#     run!() ## ...
# end
