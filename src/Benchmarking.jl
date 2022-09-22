## Benchmarking

using BenchmarkTools, CSV, DataFrames
using CSV: read as crd

when_collect_csv = CSV.read(datadir("exp_pro/inputs/whentocollect_sun.csv"), DataFrame)
when_collect = Vector{Int}(when_collect_csv[!, :x])

# read climate data
weather = CSV.read(datadir("exp_pro/inputs/Tur_Sun_Weather.csv"), DataFrame, footerskip = 1)
#weather[456, :meanTaTFS] = 23.0 # fix last temp value
rain_data = Vector{Bool}(weather[!, :Rainy])
temp_data = Vector{Float64}(weather[!, :meanTaTFS])

tparameters = CSV.read(datadir("ABC", "parameters_10.csv"), DataFrame)

d_mod = initialize_sim(; map_dims = 20, shade_percent = 0.0)
d_adata, _ = run!(d_mod, dummystep, step_model!, 10, adata = [:pos])

function b_mark()
    dd_mod = initialize_sim(; map_dims = 20, shade_percent = 0.0, steps = 50)
    dd_adata, _ = run!(dd_mod, dummystep, step_model!, 50, adata = [:pos])
    return nothing
end

function b_initialize()
    b_map = trues(100, 100)
    #emp_data = true
    steps = length(rain_data)
    initialize_sim(; steps = steps, map_dims = 100, shade_percent = 0.0,
    harvest_day = 365, start_at = 132, n_rusts = 100,
    farm_map = b_map, rain_data = rain_data, temp_data = temp_data,
    #emp_data = emp_data,
    opt_g_temp = tparameters[4, :opt_g_temp],
    spore_pct = tparameters[4, :spore_pct],
    fruit_load = tparameters[4, :fruit_load],
    uv_inact = tparameters[4, :uv_inact],
    rain_washoff = tparameters[4, :rain_washoff],
    rain_distance = tparameters[4, :rain_distance],
    wind_distance = tparameters[4, :wind_distance])
end


function b_run()
    tmodel = b_initialize()
    steps = length(rain_data)
    adata, _ = run!(tmodel, dummystep, step_model!, steps;
                    when = when_collect, adata = [:pos])
end

function b_abc()
    when_collect = crd(datadir("exp_pro/inputs/whentocollect_rust.csv"), DataFrame, select = [false, true])[!, 1]
    when_cycle = crd(datadir("exp_pro/inputs/whentocollect_plant.csv"), DataFrame, select = [false, true])[!, 1]

    # read climate data
    weather = crd(datadir("exp_pro/inputs/Tur_Sun_Weather.csv"), DataFrame, footerskip = 1)
    #weather[456, :meanTaTFS] = 23.0 # fix last temp value
    rain_data = Vector{Bool}(weather[!, :Rainy])
    temp_data = Vector{Float64}(weather[!, :meanTaTFS])

    tout_path = datadir()
    tparameters = crd(datadir("ABC", "parameters_10.csv"), DataFrame)
    #tprocess = run_for_abc(tparameters[1, :], rain_data, temp_data, when_collect, when_cycle, tout_path)
    tb_map = trues(100, 100)
    #emp_data = true
    tsteps = length(rain_data)

    tmod = initialize_sim(; steps = tsteps, map_dims = 100, shade_percent = 0.0,
        harvest_day = 365, start_at = 132, n_rusts = 100,
        farm_map = tb_map, rain_data = rain_data, temp_data = temp_data,
        #emp_data = emp_data,
        opt_g_temp = tparameters[1, :opt_g_temp],
        spore_pct = tparameters[1, :spore_pct],
        fruit_load = tparameters[1, :fruit_load],
        uv_inact = tparameters[1, :uv_inact],
        rain_washoff = tparameters[1, :rain_washoff],
        rain_distance = tparameters[1, :rain_distance],
        wind_distance = tparameters[1, :wind_distance])

    tsampler = coffee_sampling(tmod)

    tstep, tsub, tcycle = custom_abc_run!(tmod, dummystep, step_model!, tsteps;
                    when = when_collect, when_cycle = when_cycle,
                    stepdata = [fallen_pct, med_appr_area],
                    substepdata = [area_age, age],
                    cycledata = [med_cof_prod],
                    sampler = tsampler)
end
