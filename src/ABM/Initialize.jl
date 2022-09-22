#=
Input-handling structs and functions. If necessary, call create farm_map or Weather,
then call init_abm_obj. Returns model object ready to be run
=#

export Weather, Parameters, init_spatialrust, create_weather, create_farm_map, create_fullsun_farm_map, create_midshade_farm_map, CoffeePars

struct Weather{S}
    rain_data::SVector{S, Bool}
    wind_data::SVector{S, Bool}
    temp_data::SVector{S, Float64}
end

struct CoffeePars
    K_phs::Float64                  # photosynthesis efficiency constant
    lgh::Float64                    # light half-rate constant
    f_a::Float64                    # fraction of photosynthetate to area
    f_S::Float64                    # fraction of photosynthetate to storage
    commit_P::Float64               # constant for resource commitment to production
    deficit::Float64                # storage threshold for deficit state
    μ_P::Float64                    # production resource demand rate 
    μ_a::Float64                    # area resource demand rate
    harvest_day::Int              # or 182, depending on the region
    veg_d::Int                      # start of vegetative growth
    rep_d::Int                      # start of reproductive growth
    exh_countdown::Int              # days to count after plant has been exhausted (2-3 y to resume production)
end

Base.@kwdef struct Parameters
    steps::Int = 500
    start_days_at::Int = 0
    ini_rusts::Float64 = 0.01           # % of initial rusts (# of initial clusters, if > 1)
    #par_row::Int = 0                   # parameter combination number (for ABC)
    switch_cycles::Vector{Int} = []

    # farm management
    # prune_period::Int = 91              # days
    prune_sch::SVector{3, Int} = [182,-1,-1]
    target_shade::Float64 = 0.3         # shade provided by each, after pruning
    # pruning_effort::Float64 = 0.75      # % shades pruned each time
    prune_cost::Float64 = 1.0           # per shade


    inspect_period::Int = 7             # days
        # disease monitoring
    inspect_effort::Float64 = 0.01      # % coffees inspected each time
    # n_inspected::Int = 100              # n of coffees inspected
    inspect_cost::Float64 = 1.0         # per coffee inspected

    # fungicide_period::Int = 1461        # days
    fungicide_sch::SVector{3,Int} = [91,273,-1]
    # fung_rates::NamedTuple = (growth = 0.95, spor = 0.8, germ = 0.9)
    # fung_effect::Int = 15             # days with f effect
    incidence_thresh::Float64 = 0.1     # incidence that triggers fungicide use (10% from Cenicafe's Boletin 36)
    incidence_as_thr::Bool = false      # use incidence as threshold? alternative is area
    max_fung_sprayings::Int = 3         # maximum fung treatments per year
    fung_effect = 15                    # length of fungicide effect
    by_fragments::Bool = true           # apply fungicide differentially by fragments?
    fung_cost::Float64 = 1.0            # per coffee
    coffee_price::Float64 = 1.0

    # abiotic parameters
    rain_distance::Float64 = 1.0
    wind_distance::Float64 = 5.0
    rain_prob::Float64 = 0.5
    wind_prob::Float64 = 0.4
    # wind_disp_prob::Float64 = 0.5
    mean_temp::Float64 = 22.5
    uv_inact::Float64 = 0.1             # extent of effect of UV inactivation (0 to 1)
    rain_washoff::Float64 = 0.3         # " " " rain wash-off (0 to 1); Savary et al 2004
    # shade-related
    temp_cooling::Float64 = 3.0         # temp reduction due to shade
    diff_splash::Float64 = 2.0          # % extra rain distance due to enhanced kinetic e (shade) (Avelino et al. 2020 "Kinetic energy was twice as high"+Gagliardi)
    diff_wind::Float64 = 1.2            # % extra wind distance due to increased openness
    disp_block::Float64 = 0.8           # prob a tree will block rust dispersal
    shade_g_rate::Float64 = 0.1         # shade growth rate
    shade_r::Int = 3                    # radius of influence of shades

    # coffee parameters
    # K_phs::Float64 = 3.0
    # f_a::Float64 = 0.2
    # f_S::Float64 = 0.08
    # commit_P::Float64 = 0.15
    # deficit::Float64 = 5.0
    # μ_P::Float64 = 0.1
    # μ_a::Float64 = 0.05
    # harvest_day::Int = 365
    # veg_d::Int = 1
    # rep_d::Int = 140
    # exh_countdown::Int = 731
    coffee_pars::CoffeePars = CoffeePars()

    # rust parameters
    max_lesions::Int64 = 25             # maximum number of rust lesions
    rust_gr::Float64 = 0.16             # rust area growth rate
    opt_g_temp::Float64 = 22.5          # optimal rust growth temp
    # fruit_load::Float64 = 1.0           # extent of fruit load effect on rust growth (severity; 0 to 1)
    spore_pct::Float64 = 0.6            # % of area that sporulates


    # farm parameters (used if farm_map is not provided)
    map_side::Int = 100                 # side size
    row_d::Int = 2                      # distance between rows (options: 1, 2, 3)
    plant_d::Int = 1                    # distance between plants (options: 1, 2)
    shade_d::Int = 6                    # distance between shades (only considered when :regular)
    shade_pattern::Symbol = :regular    # :rand
    barrier_rows::Int = 2               # or 2 = double
    barriers::NTuple{2, Int} = (1, 0)
    # 1->internal, 2->edges


    # fragmentation::Bool = false
    # random::Bool = true
    # p_density::Float64 = 1.0
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


function create_weather(
    rain_prob::Float64,
    wind_prob::Float64,
    mean_temp::Float64,
    steps::Int,
    )
    #println("Check data! This has not been validated!")
    return Weather{steps}(
        rand(steps) .< rain_prob,
        rand(steps) .< wind_prob,
        fill(mean_temp, steps) .+ randn() .* 2
        # rand(steps) .< rain_prob,
        # rand(steps) .< wind_prob,
        # fill(mean_temp, steps) .+ randn() .* 2
    )
end

function create_weather(
    rain_data::AbstractVector{Bool},
    wind_prob::Float64,
    temp_data::Vector{Float64},
    steps::Int,
    )
    return Weather{steps}(
        rain_data,
        rand(steps) .< wind_prob,
        temp_data
        # rain_data,
        # rand(steps) .< wind_prob,
        # temp_data
    )
end

function create_weather(
    rain_data::AbstractVector{Bool},
    wind_data::AbstractVector{Bool},
    temp_data::Vector{Float64},
    )
    return Weather{steps}(
        rain_data,
        wind_data,
        temp_data
        # rain_data,
        # rand(steps) .< wind_prob,
        # temp_data
    )
end

function create_weather(
    rain_prob::Float64,
    mean_temp::Float64,
    steps::Int,
    )
    return Weather{steps}(
        rand(steps) .< rain_prob,
        # rand(steps) .* 360.0,
        fill(mean_temp, steps) .+ randn() .* 2
        # rain_data,
        # rand(steps) .< wind_prob,
        # temp_data
    )
end
function create_weather(
    rain_data::AbstractVector{Bool},
    temp_data::Vector{Float64},
    steps::Int,
    )
    return Weather{steps}(
        rain_data,
        # rand(steps) .* 360.0,
        temp_data
        # rain_data,
        # rand(steps) .< wind_prob,
        # temp_data
    )
end

function CoffeePars(;
    K_phs::Float64 = 3.0,
    f_a::Float64 = 0.2,
    f_S::Float64 = 0.08,
    commit_P::Float64 = 0.15,
    deficit::Float64 = 5.0,
    μ_P::Float64 = 0.1,
    μ_a::Float64 = 0.05,
    harvest_day::Int = 365,
    veg_d::Int = 1,
    rep_d::Int = 140,
    exh_countdown::Int = 731
)
    return CoffeePars(
        K_phs, f_a, f_S, commit_P, deficit, μ_P, μ_a, harvest_day,
        veg_d, rep_d, exh_countdown
    )
end


function Parameters(

)
 barriers
 prune_sch
 fungicide_sch (sort and SV)

end
