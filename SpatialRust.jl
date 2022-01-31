#module SpatialRust

using Agents, DataFrames, Distributions, Random
using DrWatson: srcdir
using StatsBase: sample

include(srcdir("ABMinputs.jl"))
include(srcdir("ABMsetup.jl"))
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
