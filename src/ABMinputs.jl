#=
Input-handling structs and functions. If necessary, create farm_map or Weather,
then call init_abm_obj. Returns model object
=#

struct Weather
    rain_data::Vector{Bool}
    wind_data::Vector{Bool}
    temp_data::Vector{Float64}
end

Base.@kwdef struct Parameters
    steps::Int = 500
    start_days_at::Int = 0
    p_rusts::Float64 = 0.01            # % of initial rusts
    harvest_cycle::Int = 365           # or 365/2, depending on the region
    karma::Bool = true                 # producing more spores means more spores coming from elsewhere?
    #par_row::Int = 0                   # parameter combination number (for ABC)
    switch_cycles::Vector{Int} = []

    # farm management
    fungicide_period::Int = 182        # days
    prune_period::Int = 91             # days
    inspect_period::Int = 7            # days
    inspect_effort::Float64 = 0.01     # % coffees inspected each time
    target_shade::Float64 = 0.3        # shade provided by each, after pruning
    pruning_effort::Float64 = 0.75     # % shades pruned each time
    coffee_price::Float64 = 1.0
    prune_cost::Float64 = 1.0

    # abiotic parameters
    rain_distance::Float64 = 1.0
    wind_distance::Float64 = 5.0
    rain_prob::Float64 = 0.5
    wind_prob::Float64 = 0.4
    mean_temp::Float64 = 22.5
    uv_inact::Float64 = 0.1            # extent of effect of UV inactivation (0 to 1)
    rain_washoff::Float64 = 0.1        # " " " rain wash-off (0 to 1)
    temp_cooling::Float64 = 3.0        # temp reduction due to shade
    diff_splash::Float64 = 2.0         # % extra distance due to enhanced kinetic e (shade) (Avelino et al. 2020 "Kinetic energy was twice as high")
    wind_protec::Float64 = 1.0         # % extra wind distance due to absence of shade
    disp_block::Float64 = 0.9          # prob a tree will block rust dispersal
    shade_g_rate::Float64 = 0.1        # shade growth rate

    # coffee and rust parameters
    exhaustion::Float64 = 5.0          # rust level that causes plant exhaustion
    max_cof_gr::Float64 = 0.5
    opt_g_temp::Float64 = 22.5         # optimal rust growth temp
    fruit_load::Float64 = 1.0          # extent of fruit load effect on rust growth (severity; 0 to 1)
    spore_pct::Float64 = 0.6           # % of area that sporulates


    # farm parameters (used if farm_map is not provided)
    map_side::Int = 100                # side size
    shade_percent::Float64 = 0.3
    shade_arrangement::Symbol = :rand  # :fragment or :regular
    # fragmentation::Bool = false
    # random::Bool = true
    #p_density::Float64 = 1.0
end


function init_spatialrust(parameters::Parameters, farm_map::Array{Int,2}, weather::Weather)
    # parameters.steps == length(Weather.rain_data) || error(
    #     "number of steps is different from length of rain data")
    model = init_abm_obj(parameters, farm_map, weather)
    return model
end

function init_spatialrust(parameters::Parameters, farm_map::Array{Int,2})
    init_spatialrust(parameters, farm_map, create_weather(parameters.rain_prob, parameters.wind_prob, parameters.mean_temp, parameters.steps))
end

function init_spatialrust(parameters::Parameters, weather::Weather)
    init_spatialrust(parameters, create_farm_map(parameters), weather)
end

function init_spatialrust(parameters::Parameters)
    init_spatialrust(parameters, create_farm_map(parameters), create_weather(parameters.rain_prob, parameters.wind_prob, parameters.mean_temp, parameters.steps))
end

function init_spatialrust()
    pars = Parameters()
    # farm_map = create_farm_map(pars)
    # weather = create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp)

    return init_spatialrust(pars, create_farm_map(pars), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
end




function create_weather(rain_prob::Float64, wind_prob::Float64, mean_temp::Float64, steps::Int)
    #println("Check data! This has not been validated!")
    return Weather(rand(Float64, steps) .< rain_prob, rand(Float64, steps) .< wind_prob, fill(mean_temp, steps) .+ randn() .* 2)
end

function create_farm_map(parameters::Parameters)
end

function create_fullsun_farm_map()
    farm_map = zeros(Int,100,100)
    for c in 1:2:100
        farm_map[:,c] .= 1
    end
    return farm_map
end
