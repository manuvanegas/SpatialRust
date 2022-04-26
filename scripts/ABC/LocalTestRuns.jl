Pkg.activate(".")
using Agents, DrWatson, Random
using Statistics: median, mean

using Arrow, DataFrames
using CSV: read as crd

when_rust = Vector(Arrow.Table("data/exp_pro/inputs/sun_whentocollect_rust.arrow")[1])
const when_plant = Vector(Arrow.Table("data/exp_pro/inputs/sun_whentocollect_plant.arrow")[1])

# const when_rust = sort!(union(when_plant, when_rust)) # needed because the first 5 dates of when_prod are not in when_rust

# read climate data
const rain_data = Vector(Arrow.Table("data/exp_pro/inputs/sun_weather.arrow")[1])
const temp_data = Vector(Arrow.Table("data/exp_pro/inputs/sun_weather.arrow")[2])
const paramss = crd(datadir("ABC", "parameters_10.csv"), DataFrame)

include(projectdir("SpatialRust.jl"))
using .SpatialRust

# Random.seed!(1234)
# for rr in eachrow(paramss)[1:2]
#     sim_abc(rr, rain_data, temp_data, when_rust, when_plant, 0.5, 231)
# end

sim_abc(eachrow(paramss)[1], rain_data, temp_data, when_rust, when_plant, 0.5, 231)

using BenchmarkTools
Random.seed!(1234)
@btime sim_abc(
    $(eachrow(paramss)[1]), $rain_data, $temp_data,
    $when_rust, $when_plant, 0.5, 231)

for i in 1:10
    println(i)
    sim_abc(eachrow(paramss)[1], rain_data, temp_data, when_rust, when_plant, 0.5, 231)
end

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

##
pars = Parameters(steps = 231, map_side = 100, switch_cycles = copy(when_plant))
ttmodel = init_spatialrust(pars, Main.SpatialRust.create_fullsun_farm_map(), Main.SpatialRust.create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
Main.SpatialRust.custom_sampling_second!(ttmodel, 0.05)


Random.seed!(1234)
pars = Parameters(steps = 231, map_side = 100, switch_cycles = copy(when_plant))
for i in 1:500
    ttmodel = init_spatialrust(pars, Main.SpatialRust.create_fullsun_farm_map(), Main.SpatialRust.create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
    Main.SpatialRust.custom_sampling_second!(ttmodel, 0.05)
    if isempty(Iterators.filter(c -> c isa Coffee && 8 in c.sample_cycle, allagents(ttmodel)))
        println(i)
        break
    end
end

using DataFrames
tmodel = justtwosteps()
SpatialRust.custom_sampling_first!(tmodel, 0.05)
ttmodel.current.cycle =[5,6]
SpatialRust.ind_data(ttmodel)
stepdata = collect_model_data!(DataFrame(step = Int[], ind_data = DataFrame(rust = DataFrame(), prod = DataFrame())),
    ttmodel, [SpatialRust.ind_data], 2; obtainer = identity)

SpatialRust.update_dfs!(per_age, per_cycle, stepdata[1, :ind_data][1, :rust], stepdata[1, :ind_data][1, :prod])
