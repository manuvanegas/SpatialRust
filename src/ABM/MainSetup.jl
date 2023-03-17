export Coffee, init_spatialrust, create_farm_map, create_fullsun_farm_map, create_regshaded_farm_map


mutable struct Sentinel
    active::Bool
    id::Int
    cycle::Int
    n_lesions::Int
    ages::Vector{Int}
    areas::Vector{Float64}
    spores::BitVector
end

# Coffee agent type
# mutable struct Coffee <: AbstractAgent
@agent Coffee GridAgent{2} begin
    sunlight::Float64 # let through by shade trees
    veg::Float64
    # shade_neighbors::Float64 # remember total neighboring shade trees
    storage::Float64
    production::Float64
    exh_countdown::Int
    rust_gr::Float64
    # fungicide::Int
    # fung_countdown::Int

    #Rust
    # infected::Bool
    newdeps::Float64
    deposited::Float64 
    n_lesions::Int
    ages::Vector{Int}
    areas::Vector{Float64}
    spores::BitVector

    # ABC
    # sample_cycle::Int # cycles where coffee should be sampled
    sentinel::Sentinel
end

# Coffee constructor
function Coffee(id, pos, max_lesions::Int, max_age::Int, rust_gr::Float64; # https://juliadynamics.github.io/Agents.jl/stable/api/#Adding-agents
    sunlight::Float64 = 1.0, veg::Float64 = 1.85, storage::Float64 = 100.0)

    # fill_n = max_lesions - length(ages)
    
    # Coffee(id, pos, sunlight, veg, storage, production, 0, [], deposited, n_lesions,
    # append!(ages, fill(max_age, fill_n)), append!(areas, fill(0.0, fill_n)),
    # append!(spores, fill(false, fill_n))) 
    Coffee(
        id, pos, sunlight, veg, storage, 0.0, 0, rust_gr,
        0.0, 0.0, 0,
        fill(max_age, max_lesions), fill(0.0, max_lesions), falses(max_lesions),
        sentinel(id)
    ) 
end

# Main abm initialization function

function init_spatialrust(;
    start_days_at::Int = 0,
    ini_rusts::Float64 = 0.01,              # % of initial rusts (# of initial clusters, if > 1)
    p_row::Int = 0,                         # parameter combination number (for ABC)
    rep::Int = 0,                           # repetition number (for other exps)

    # weather parameters
    rain_prob::Float64 = 0.6,
    wind_prob::Float64 = 0.5,
    mean_temp::Float64 = 22.5,
    rain_data::Tuple = (),                  # if provided, rain_prob is ignored
    wind_data::Tuple = (),                  # if provided, wind_prob is ignored
    temp_data::Tuple = (),                  # if provided, mean_temp is ignored

    # coffee parameters
    veg_d::Int = 1,                         # start of vegetative growth   
    rep_d::Int = 135,                       # start of reproductive growth
    f_avail::Float64 = 0.5,                 # fraction of daily assimilates available for allocation
    phs_max::Float64 = 0.2,                 # maximum assimilation rate
    k_sl::Float64 = 0.05,                   # half-rate constant for sunlight-dependent photosynthesic rate  
    k_v::Float64 = 0.2,                     # half-rate constant for veg-dependent photosynthesic rate 
    photo_frac::Float64 = 0.2,              # fraction of veg tissue that is photosynthetic
    phs_veg::Float64 = 0.8,                 # fraction of photosynthetate allocated and converted to veg 
    μ_veg::Float64 = 0.01,                  # rate of veg biomass loss
    phs_sto::Float64 = 0.6,                 # fraction of photosynthetate allocated and converted to storage
    res_commit::Float64 = 0.25,             # scaling par to determine resources commited to production
    μ_prod::Float64 = 0.01,                 # rate of production biomass loss

    # rust parameters
    max_lesions::Int64 = 25,                # maximum number of rust lesions
    temp_cooling::Float64 = 4.0,            # temp reduction due to shade
    light_inh::Float64 = 0.1,               # extent of effect of UV inactivation 
    rain_washoff::Float64 = 0.3,            # " " " rain wash-off (0 to 1); Savary et al 2004
    max_inf::Float64 = 0.9,                 # Max infection probability
    rust_gr::Float64 = 0.16,                # rust area growth rate
    opt_g_temp::Float64 = 22.5,             # optimal rust growth temp
    host_spo_inh::Float64 = 1.0,            # Coeff for inhibition of storage on sporul
    max_g_temp::Float64 = 30.0,             # maximum rust growth temp
    rep_gro::Float64 = 0.7,                 # resource sink effect on area growth
    # veg_gro::Float64 = 0.3,                 # growth during vegetative phase
    spore_pct::Float64 = 0.6,               # % of area that sporulates
    fung_inf::Float64 = 0.9,                # infection prob under fungicide mod
    fung_gro_prev::Float64 = 0.3,           # fungicide mod to growth rate on preventive fungicide
    fung_gro_cur::Float64 = 0.75,           # fungicide mod to growth rate on curative fungicide
    fung_spor_prev::Float64 = 0.0,          # fungicide mod to spor prob on preventive fungicide
    fung_spor_cur::Float64 = 0.85,          # fungicide mod to spor prob on curative fungicide
    
    steps::Int = 500,                       # simulation steps. Included in RustPars to reset Rust ages values on exhaustion
    rust_paras::Float64 = 0.1,              # resources taken per unit of total area
    exh_threshold::Float64 = 0.5,           # veg threshold for exhaustion (0 to 2)
    exh_countdown::Int = 731,               # days to count after plant has been exhausted (2-3 y to resume production) 

    map_side::Int = 100,                    # side size
    rain_distance::Float64 = 1.0,           # mean distance of spores dispersed by rain
    diff_splash::Float64 = 2.0,             # times rain distance due to enhanced kinetic e (shade) (Avelino et al. 2020 "Kinetic energy was twice as high"+Gagliardi)
    tree_block::Float64 = 0.8,              # prob a tree will block rust dispersal
    wind_distance::Float64 = 5.0,           # mean distance of spores dispersed by wind
    diff_wind::Float64 = 3.0,               # additional wind distance due to increased openness (Pezzopane
    shade_block::Float64 = 0.5,             # prob of Shades blocking a wind dispersal event

    # farm management
    harvest_day::Int = 365,                 # 365 or 182, depending on the region
    prune_sch::Vector{Int} = [182,-1,-1],
    inspect_period::Int = 7,                # days
    fungicide_sch::Vector{Int} = [91,273,-1],
    incidence_as_thr::Bool = false,         # use incidence as threshold? alternative is area
    incidence_thresh::Float64 = 0.1,        # incidence that triggers fungicide use (10% from Cenicafe's Boletin 36)
    max_fung_sprayings::Int = 3,            # maximum fung treatments per year

    prune_cost::Float64 = 1.0,              # per shade
    inspect_cost::Float64 = 1.0,            # per coffee inspected
    fung_cost::Float64 = 1.0,               # per coffee
    other_costs::Float64 = 1.0,             # other costs considered
    coffee_price::Float64 = 1.0,

    lesion_survive::Float64 = 0.1,
    target_shade::Vector{Float64} = [0.3, 0.5, 0.0],            # individual shade level after pruning
    inspect_effort::Float64 = 0.01,         # % coffees inspected each time
    fung_effect::Int = 30,                  # length of fungicide effect
    # by_fragments::Bool = true,            # apply fungicide differentially by fragments?
    # shade parameters
    shade_g_rate::Float64 = 0.008,           # shade growth rate
    shade_r::Int = 3,                       # radius of influence of shades

    # farm map
    farm_map::Array{Int} = Int[],              # if provided, parameters below are ignored
    common_map::Symbol = :none,             # :fullsun or :regshaded
    row_d::Int = 2,                         # distance between rows (options: 1, 2, 3)
    plant_d::Int = 1,                       # distance between plants (options: 1, 2)
    shade_d::Int = 6,                       # distance between shades (only considered when :regular)
    shade_pattern::Symbol = :regular,       # or :rand
    barrier_rows::Int = 2,                  # or 2 = double
    barriers::NTuple{2, Int} = (1, 0),      # barrier arrangement: 1->internal(0, 1, or 2),2->edges(0 or 1)

    # fragmentation::Bool = false
    # random::Bool = true
    # p_density::Float64 = 1.0
    )

    w = Weather{steps}(
        isempty(rain_data) ? Tuple(rand(steps) .< rain_prob) : rain_data[1:steps],
        isempty(wind_data) ? Tuple(rand(steps) .< wind_prob) : wind_data[1:steps],
        isempty(temp_data) ? Tuple(fill(mean_temp, steps) .+ randn() .* 2) : temp_data[1:steps]
    )

    if isempty(farm_map)
        if common_map == :none
            farm_map = create_farm_map(map_side, row_d, plant_d, shade_d, shade_pattern, barrier_rows, barriers)
        elseif common_map == :fullsun
            farm_map = create_fullsun_farm_map(map_side, row_d, plant_d)
        elseif common_map == :regshaded
            farm_map = create_regshaded_farm_map(map_side, row_d, plant_d, shade_d)
        end
    else
        map_side = size(farm_map)[1]
    end

    smap = create_shade_map(farm_map, shade_r, map_side)

    cp = CoffeePars(
        veg_d, rep_d, f_avail * phs_max, k_sl, k_v, photo_frac,
        phs_veg, μ_veg, phs_sto, res_commit, μ_prod, exh_countdown
    )

    rp = RustPars(
        max_lesions, temp_cooling, light_inh, rain_washoff, max_inf, rust_gr, opt_g_temp,
        # host_spo_inh, max_g_temp, rep_gro, veg_gro, spore_pct, fung_inf, fung_gro_prev,
        host_spo_inh, max_g_temp, rep_gro, spore_pct, fung_inf, fung_gro_prev,
        fung_gro_cur, fung_spor_prev, fung_spor_cur, 
        #
        steps, (steps * 2 + 1), rust_paras, exh_threshold, exh_countdown,
        #
        map_side, rain_distance, diff_splash, tree_block, wind_distance, diff_wind, shade_block
    )

    n_shades = count(farm_map .== 2)
    n_coffees = count(farm_map .== 1)
    pruneskept = prune_sch .> 0
    prune_sch = Tuple(sort!(filter!(>(0), prune_sch)))
    target_shade = Tuple(filter!(>(0.0), target_shade[pruneskept]))
    fungicide_sch = Tuple(sort!(filter!(>(0), fungicide_sch)))
    n_inspect = trunc(Int, inspect_effort * n_coffees)

    mp = MngPars{length(prune_sch),length(fungicide_sch)}(
        harvest_day, prune_sch,
        inspect_period, fungicide_sch,
        incidence_as_thr, incidence_thresh, max_fung_sprayings,
        #
        n_shades, prune_cost * n_shades,
        n_coffees, inspect_cost * n_inspect, fung_cost * n_coffees,
        other_costs, coffee_price,
        #
        lesion_survive, target_shade, n_inspect, fung_effect,
        shade_g_rate, shade_r
    )

    doy = start_days_at == 0 ? veg_d - 1 : start_days_at

    b = Books(
        doy, 0, ind_shade_i(shade_g_rate, doy, target_shade, prune_sch),
        0.0, false, false, 0.0, 0, 0, 0.0, 0.0, 0.0, true
    )

    if ini_rusts > 0.0
        return init_abm_obj(Props(w, cp, rp, mp, b, farm_map, smap, zeros(8),
        Set{Coffee}(),
        # ),
        Set{Sentinel}()),
        ini_rusts)
    else
        return init_abm_obj(Props(w, cp, rp, mp, b, farm_map, smap, zeros(8),
        Set{Coffee}(),
        # ),
        Set{Sentinel}()),
        )
    end
end

# Definitions of the different parameter structs

struct Weather{N}
    rain_data::NTuple{N, Bool}
    wind_data::NTuple{N, Bool}
    temp_data::NTuple{N, Float64}
end

struct CoffeePars
    veg_d::Int
    rep_d::Int
    photo_const::Float64 # f_avail * phs_max * photo_frac
    k_sl::Float64
    k_v::Float64
    photo_frac::Float64
    phs_veg::Float64
    μ_veg::Float64
    phs_sto::Float64
    res_commit::Float64
    μ_prod::Float64
    exh_countdown::Int          
end

struct RustPars
    # growth
    max_lesions::Int64
    temp_cooling::Float64
    light_inh::Float64
    rain_washoff::Float64
    max_inf::Float64
    rust_gr::Float64
    opt_g_temp::Float64
    host_spo_inh::Float64
    max_g_temp::Float64
    rep_gro::Float64
    # veg_gro::Float64
    spore_pct::Float64
    fung_inf::Float64 
    fung_gro_prev::Float64
    fung_gro_cur::Float64 
    fung_spor_prev::Float64
    fung_spor_cur::Float64 
    # parasitism
    steps::Int
    reset_age::Int
    rust_paras::Float64
    exh_threshold::Float64
    exh_countdown::Int
    # dispersal
    map_side::Int
    rain_distance::Float64
    diff_splash::Float64
    tree_block::Float64
    wind_distance::Float64
    diff_wind::Float64
    shade_block::Float64
end

struct MngPars{N,M}
    # action scheduling
    harvest_day::Int
    prune_sch::NTuple{N,Int}
    inspect_period::Int
    fungicide_sch::NTuple{M,Int}
    incidence_as_thr::Bool
    incidence_thresh::Float64
    max_fung_sprayings::Int
    # financials
    n_shades::Int
    tot_prune_cost::Float64
    n_cofs::Int
    tot_inspect_cost::Float64
    tot_fung_cost::Float64
    other_costs::Float64
    coffee_price::Float64
    # others
    lesion_survive::Float64
    target_shade::NTuple{N, Float64}
    n_inspected::Int
    fung_effect::Int
    # by_fragments::Bool = true,            # apply fungicide differentially by fragments?
    shade_g_rate::Float64
    shade_r::Int
end

mutable struct Books
    days::Int                               # same as ticks unless start_days_at != 0
    ticks::Int                              # initialized as 0 but the 1st thing that happens is +=1, so it effectvly starts at 1
    # cycle::Vector{Int}
    # rusts::Set{Coffee}
    ind_shade::Float64
    temperature:: Float64
    rain::Bool
    wind::Bool
    wind_h::Float64
    fungicide::Int
    fung_count::Int
    obs_incidence::Float64
    costs::Float64
    prod::Float64
    inbusiness::Bool
    # net_rev::Float64
    # max_rust::Float64
end

struct Props
    weather::Weather
    coffeepars::CoffeePars
    rustpars::RustPars
    mngpars::MngPars
    current::Books
    farm_map::Array{Int, 2}
    shade_map::Array{Float64}
    outpour::Vector{Float64}
    rusts::Set{Coffee}
    sentinels::Set{Sentinel}
    # 8 positions, one per direction the spores can leave the farm (from (0,0) which is the farm)
    # indexing is weird (also remember, julia goes column-first): 
    # 1 -> (0,-1), 2 -> (0,1), 3 -> (-1,0), 4 -> (-1,-1), 5 -> (-1,1), 6 -> (1,0), 7 -> (1,-1), 8 ->(1,1)
end

# Calculate initial ind_shade
function ind_shade_i(
    shade_g_rate::Float64,
    start_day_at::Int,
    target_shade::NTuple{N, Float64},
    prune_sch::NTuple{N, Int}) where {N}

    if isempty(prune_sch)
        return 0.8
    else
        day = start_day_at > 0 ? start_day_at : 1
        # calculate elapsed days since last prune
        prune_diff = filter(>(0), day .- prune_sch)
        if isempty(prune_diff)
            lastprune, prune_i = findmax(prune_sch)
            last_prune = 365 + day - lastprune
            pruned_to = target_shade[prune_i]
        else
            lastprune, prune_i = findmin(prune_diff)
            last_prune = minimum(prune_diff)
            pruned_to = target_shade[prune_i]
        end
        # logistic equation to determine starting shade level
        return (0.8 * pruned_to) / (pruned_to + (0.8 - pruned_to) * exp(-(shade_g_rate * last_prune)))
    end
end



# function init_spatialrust(parameters::Parameters, farm_map::Array{Int,2}, weather::Weather)
#     # parameters.steps == length(Weather.rain_data) || error(
#     #     "number of steps is different from length of rain data")
#     model = init_abm_obj(parameters, farm_map, weather)
#     return model
# end

# function init_spatialrust(parameters::Parameters, farm_map::Array{Int,2})
#     init_spatialrust(parameters, farm_map, create_weather(parameters.rain_prob, parameters.wind_prob, parameters.mean_temp, parameters.steps))
# end

# function init_spatialrust(parameters::Parameters, weather::Weather)
#     init_spatialrust(parameters, create_farm_map(parameters), weather)
# end

# function init_spatialrust(parameters::Parameters)
#     init_spatialrust(parameters, create_farm_map(parameters), create_weather(parameters.rain_prob, parameters.wind_prob, parameters.mean_temp, parameters.steps))
# end

# function init_spatialrust()
#     pars = Parameters()
#     # farm_map = create_farm_map(pars)
#     # weather = create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp)

#     return init_spatialrust(pars, create_farm_map(pars), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
# end


# function create_weather(
#     rain_prob::Float64,
#     wind_prob::Float64,
#     mean_temp::Float64,
#     steps::Int,
#     )
#     #println("Check data! This has not been validated!")
#     return Weather{steps}(
#         rand(steps) .< rain_prob,
#         rand(steps) .< wind_prob,
#         fill(mean_temp, steps) .+ randn() .* 2
#         # rand(steps) .< rain_prob,
#         # rand(steps) .< wind_prob,
#         # fill(mean_temp, steps) .+ randn() .* 2
#     )
# end

# function create_weather(
#     rain_data::AbstractVector{Bool},
#     wind_prob::Float64,
#     temp_data::Vector{Float64},
#     steps::Int,
#     )
#     return Weather{steps}(
#         rain_data,
#         rand(steps) .< wind_prob,
#         temp_data
#         # rain_data,
#         # rand(steps) .< wind_prob,
#         # temp_data
#     )
# end

# function create_weather(
#     rain_data::AbstractVector{Bool},
#     wind_data::AbstractVector{Bool},
#     temp_data::Vector{Float64},
#     )
#     return Weather{steps}(
#         rain_data,
#         wind_data,
#         temp_data
#         # rain_data,
#         # rand(steps) .< wind_prob,
#         # temp_data
#     )
# end

# function create_weather(
#     rain_prob::Float64,
#     mean_temp::Float64,
#     steps::Int,
#     )
#     return Weather{steps}(
#         rand(steps) .< rain_prob,
#         # rand(steps) .* 360.0,
#         fill(mean_temp, steps) .+ randn() .* 2
#         # rain_data,
#         # rand(steps) .< wind_prob,
#         # temp_data
#     )
# end
# function create_weather(
#     rain_data::AbstractVector{Bool},
#     temp_data::Vector{Float64},
#     steps::Int,
#     )
#     return Weather{steps}(
#         rain_data,
#         # rand(steps) .* 360.0,
#         temp_data
#         # rain_data,
#         # rand(steps) .< wind_prob,
#         # temp_data
#     )
# end

