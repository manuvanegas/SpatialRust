#module SpatialRust

using Agents, DataFrames, Distributions, Random
using DrWatson: srcdir
using StatsBase: sample

include(srcdir("ABMinputs.jl"))
include(srcdir("ABMsetup.jl"))#module SpatialRust

using Agents, DataFrames, Distributions, Random
using DrWatson: srcdir
using StatsBase: sample

include(srcdir("ABMinputs.jl"))
include(srcdir("ABMsetup.jl"))
include(srcdir("ABMstep.jl"))
include(srcdir("ABCsetup.jl"))
include(srcdir("ABCmetrics.jl"))
# include(srcdir("CustomRun.jl"))

#export initialize_sim, step_model!, run_for_abc, Shade, Coffee, Rust
#end


function dummyrun_spatialrust()
    pars = Parameters(steps = 50, map_side = 20)
    model = init_spatialrust(pars, create_farm_map(FarmSpace(map_dims = 20, shade_percent = 0.0)), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
    run!() ## ...
end

pars = Parameters(steps = 50, map_side = 100, n_rusts = 100)

pars = Parameters(steps = 50, map_side = 100, n_rusts = 100, switch_cycles = copy(when_cycle))
model = init_spatialrust(pars, create_fullsun_farm_map(), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
custom_sampling!(model, 0.05, 1)
add, mdd = run!(model, dummystep, step_model!, 50;
    # adata = [(x) -> (x.shade_neighbors[i]) for i in 1:2],
    when_model = when_collect, mdata = [areas_per_age, total_lesion_area, coffee_production])

Juno.@profiler for i in 1:2
    pars = Parameters(steps = 400, map_side = 100, n_rusts = 100, switch_cycles = copy(when_cycle))
    model = init_spatialrust(pars, create_fullsun_farm_map(), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
    custom_sampling!(model, 0.05, 1)
    add, mdd = run!(model, dummystep, step_model!, 400; when_model = when_collect, mdata = [fallen_coffees, total_lesion_area, coffee_production])
end

@benchmark init_spatialrust(pars, create_fullsun_farm_map(), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))

include(srcdir("ABMstep.jl"))
include(srcdir("ABCrun.jl"))
include(srcdir("CustomRun.jl"))

#export initialize_sim, step_model!, run_for_abc, Shade, Coffee, Rust
#end


function dummyrun_spatialrust()
    pars = Parameters(steps = 50, map_side = 20)
    model = init_spatialrust(pars, create_farm_map(FarmSpace(map_dims = 20, shade_percent = 0.0)), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
    run!() ## ...
end
