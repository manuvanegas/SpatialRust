cd("~/SpatialRust/")
usings_time = @elapsed begin
    using Distributed
    @everywhere using DrWatson #: projectdir, datadir, srcdir, @quickactivate
    #@everywhere Pkg.activate(".")

    @everywhere begin
        @quickactivate "SpatialRust"
        using DataFrames
        using Distributed: pmap
        using CSV: read as crd, write as cwr
        using Arrow: write as awr
        include(projectdir("SpatialRust.jl"))
        using .SpatialRust
        # include(srcdir("ABC","ABCsims.jl"))
    end
end

# ARGS: params file, slurm job array id, chunk size
println(ARGS)

load_time = @elapsed begin
    startat = 2
    less_this = 0

    if length(ARGS) > 1
        n_rows = parse(Int, ARGS[3]) - 1
        startat = (parse(Int, ARGS[2]) - 1) * n_rows + 1
    end

    when_rust = crd(datadir("exp_pro/inputs/sun_whentocollect_rust.csv"), DataFrame, select = [false, true])[!, 1]
    when_plant = crd(datadir("exp_pro/inputs/sun_whentocollect_plant.csv"), DataFrame, select = [false, true])[!, 1]

    # read climate data
    weather = crd(datadir("exp_pro/inputs/sun_weather.csv"), DataFrame)
    rain_data = Vector{Bool}(weather[!, :Rainy])
    temp_data = Vector{Float64}(weather[!, :MeanTa])

    parameters = crd(datadir("ABC", ARGS[1]), DataFrame, skipto = startat, limit = n_rows, threaded = false)

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

dummy_time = @elapsed begin
    #dummy run
    abc_run!(parameters[1,:], rain_data, temp_data, when_rust, when_plant, 0.5, 30)
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

cwr(string("~/SpatialRust/timing", ARGS[2],".txt"), timings)
