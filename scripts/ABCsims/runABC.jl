usings_time = @elapsed begin
    @everywhere using DrWatson
    @everywhere @quickactivate "SpatialRust"
    @everywhere begin
        using DataFrames                                                        
        using Distributed: pmap                                                 
        using CSV: read as crd, write as cwr                                    
        using Arrow: write as awr                                               
        include(projectdir("SpatialRust.jl"))
    end                                                                         
    @everywhere begin                                                           
        using .SpatialRust                                                      
    end                                                                         
end                                       

# ARGS: params file, slurm job array id, chunk size
println(ARGS)

load_time = @elapsed begin
    n_rows = parse(Int, ARGS[3])
    startat = parse(Int, ARGS[2]) == 1 ? 2 : (parse(Int, ARGS[2]) - 1) * n_rows + 1

    when_rust = crd(datadir("exp_pro/inputs/sun_whentocollect_rust.csv"), DataFrame, select = [false, true])[!, 1]
    when_plant = crd(datadir("exp_pro/inputs/sun_whentocollect_plant.csv"), DataFrame, select = [false, true])[!, 1]

    # read climate data
    weather = crd(datadir("exp_pro/inputs/sun_weather.csv"), DataFrame)
    rain_data = Vector{Bool}(weather[!, :Rainy])
    temp_data = Vector{Float64}(weather[!, :MeanTa])

    parameters = crd(datadir("ABC", ARGS[1]), DataFrame, header = 1, skipto = startat, limit = n_rows, threaded = false)

    mkpath("/scratch/mvanega1/ABCraw/ages/")
    mkpath("/scratch/mvanega1/ABCraw/cycles")
    mkpath("/scratch/mvanega1/ABCraw/prod")
    #mkpath("/scratch/mvanega1/ABCveryraw/cycledata")
end

# pars = Parameters(steps = 231, map_side = 100, switch_cycles = copy(when_plant))
# model = init_spatialrust(pars, create_fullsun_farm_map(), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
# custom_sampling!(model, 0.05, 1)
# paramss = crd(datadir("ABC", "parameters_10.csv"), DataFrame)
# for rr in eachrow(paramss)[1:2]
#     sim_and_write(rr, rain_data, temp_data, when_rust, when_plant, 0.5, 231)
# end

println(parameters)

dummy_time = @elapsed begin
    #dummy run
    sim_and_write(parameters[1,:], rain_data, temp_data, when_rust, when_plant, 0.5)
    println("Dummy run completed")
end

run_time = @elapsed begin
    processed = pmap(p -> sim_and_write(p, rain_data, temp_data, when_rust, when_plant, 0.5),
                    eachrow(parameters); retry_delays = fill(0.1, 3))
    println("total: ",sum(processed))
end

timings = """
Init: $usings_time
Loads: $load_time
Compile: $dummy_time
Run: $run_time
"""

println(ARGS[2])
println(timings)
#cwr(string("~/SpatialRust/scripts/ABCsims/timing", ARGS[2],".txt"), timings)
