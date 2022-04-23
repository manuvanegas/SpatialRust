Pkg.activate(".")
using Agents, DrWatson, Random
using Statistics: median, mean

include(projectdir("SpatialRust.jl"))
using .SpatialRust

using Arrow, DataFrames
using CSV: read as crd

when_rust = Vector(Arrow.Table("data/exp_pro/inputs/sun_whentocollect_rust.arrow")[1])
when_plant = Vector(Arrow.Table("data/exp_pro/inputs/sun_whentocollect_plant.arrow")[1])

# read climate data
rain_data = Vector(Arrow.Table("data/exp_pro/inputs/sun_weather.arrow")[1])
temp_data = Vector(Arrow.Table("data/exp_pro/inputs/sun_weather.arrow")[2])

pars = Parameters(steps = 231, map_side = 100, switch_cycles = copy(when_plant))
model = init_spatialrust(pars, Main.SpatialRust.create_fullsun_farm_map(), Main.SpatialRust.create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
Main.SpatialRust.custom_sampling_first!(model, 0.05)
paramss = crd(datadir("ABC", "parameters_10.csv"), DataFrame)

sim_abc(eachrow(paramss)[4], rain_data, temp_data, when_rust, when_plant, 0.5, 231)

Random.seed!(1234)
for rr in eachrow(paramss)[1:5]
    sim_abc(rr, rain_data, temp_data, when_rust, when_plant, 0.5, 231)
end

using BenchmarkTools
Random.seed!(1234)
@btime sim_abc($(eachrow(paramss)[1]), $rain_data, $temp_data, $when_rust, $when_plant, 0.5, 231)

@btime sim_abc($(eachrow(paramss)[4]), $rain_data, $temp_data, $when_rust, $when_plant, 0.5, 231)
# 55 s!

tmodel = justtwosteps() #tmodel has only 5 steps
SpatialRust.abc_run!(tmodel,
    SpatialRust.step_model!,
    2;
    when_rust = true,
    rust_data = [SpatialRust.ind_data],
    prod_data = [SpatialRust.prod_metrics],
    obtainer = identity)
