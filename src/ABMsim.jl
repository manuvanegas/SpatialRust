## Agent types
mutable struct Coffee <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    # prob a model param: p_density::Float64 # coffee plants / grid cell
    area::Float64 # healthy foliar area (= 25 - rust.area * rust.n_lesions)
    sunlight::Float64 # let through by shade trees
    shade_neighbors::Array{Int,1} # remember which neighbors are shade trees
    progression::Float64
    production::Float64
    exh_countdown::Int
    age::Int
    hg_id::Int
end

mutable struct Shade <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    shade::Float64 # between 20 and 90 %
    production::Float64
    age::Int
    hg_id::Int
end

mutable struct Rust <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    germinated::Bool # has it germinated and penetrated leaf tissue?
    area::Float64 # total, equal to latent + sporulating
    spores::Float64
    n_lesions::Int
    age::Int
    hg_id::Int
    #successful_landings::Int # maybe useful metric?
    #parent::Int # id of rust it came from
end

Base.@kwdef mutable struct Books
    days::Int
    ticks::Int = 1
    coffee_ids::Vector{Int} = Int[]
    shade_ids::Vector{Int} = Int[]
    rust_ids::Vector{Int} = Int[]
    outpour::Float64 = 0.0
    #temp_var::Float64 = 0.0
    temperature:: Float64 = 0.0
    rain::Bool = true
    wind::Bool = true
    costs::Float64 = 0.0
    gains::Float64 = 0.0
    yield::Float64 = 0.0
end

Base.@kwdef struct Parameters
    dims::Int
    #farm_map::BitArray
    harvest_cycle::Int # 182 or 365
    karma::Bool
    # farmer's strategy and finances
    p_density::Float64 # 0 to 1
    fungicide_period::Int # in days
    prune_period::Int # in days
    inspect_period::Int # days
    n_inspected::Int # coffee plants inspected
    target_shade::Float64 # 0.2 to 0.9
    n_pruned::Int # shade trees pruned
    #n_pruned::Int 0 # n shade trees pruned
    coffee_price::Float64 # 1 for now
    prune_cost::Float64 # 1 for now
    # weather and abiotic parameters
    rain_distance::Float64
    wind_distance::Float64
    rain_data::Vector{Bool}
    wind_data::Vector{Bool}
    temp_data::Vector{Float64}
    mean_temp::Float64
    uv_inact::Float64 # extent of effect of UV inactivation (0 to 1)
    rain_washoff::Float64 # " " " rain wash-off (0 to 1)
    temp_cooling::Float64 # temp reduction due to shade
    diff_splash::Float64 # % extra distance due to enhanced kinetic e (shade)
    wind_protec::Float64 # % extra wind distance due to absence of shade
    # biotic parameters
    shade_rate::Float64 # shade growth rate
    max_cof_gr::Float64
    opt_g_temp::Float64 # optimal rust growth temp
    fruit_load::Float64 # extent of fruit load effect on rust growth (severity; 0 to 1)
    spore_pct::Float64 # % of area that sporulates
    # record-keeping
    current::Books
end


## Setup functions

function count_shades!(model::ABM)
    for c in model.current.coffee_ids
        neighbors = nearby_ids(model[c], model) # get ids of neighboring plants
        model[c].shade_neighbors = collect(Iterators.Filter(id -> model[id] isa Shade, neighbors))
    end
end

function create_props(input::Input)
    Parameters(
    dims = input.map_dims,
    harvest_cycle = input.harvest_cycle,
    karma = input.karma,
    # farmer's strategy and finances
    p_density = input.p_density,
    fungicide_period = input.fungicide_period,
    prune_period = input.prune_period,
    inspect_period = input.inspect_period,
    n_inspected = trunc(Int, input.inspect_effort * sum(input.farm_map)),
    target_shade = input.target_shade,
    n_pruned = trunc(Int, input.pruning_effort * count(==(0), input.farm_map)),
    coffee_price = input.coffee_price,
    prune_cost = input.prune_cost,
    rain_distance =  input.rain_distance,
    wind_distance = input.wind_distance,
    rain_data = input.rain_data,
    wind_data = input.wind_data,
    temp_data = input.temp_data,
    mean_temp = input.mean_temp,
    uv_inact = input.uv_inact,
    rain_washoff = input.rain_washoff,
    temp_cooling = input.temp_cooling,
    diff_splash = input.diff_splash,
    wind_protec = input.wind_protec,
    shade_rate = input.shade_rate,
    max_cof_gr = input.max_cof_gr,
    opt_g_temp = input.opt_g_temp,
    fruit_load = input.fruit_load,
    spore_pct = input.spore_pct,
    # record-keeping
    current = Books(days = input.days)
    )
end

function setup_sim(input::Input)::ABM
    space = GridSpace((input.map_dims, input.map_dims), periodic = false, metric = :chebyshev)

    model = ABM(Union{Shade, Coffee, Rust}, space;
        properties = create_props(input),
        # scheduler = by_type((Shade, Cofffee, Rust), true)
        #scheduler = custom_scheduler,
        warn = false)

    if input.days != 0
        prod_d = truncated(Normal(input.days, input.days * 0.02), 0.0, input.days)
        # introducing some variability, but most of the plants are expected to have accumulated (close to) optimal productivity
        id = 0
        for patch in CartesianIndices(input.farm_map)
            id += 1
            if input.farm_map[patch]
                add_agent_pos!(Coffee(id, Tuple(patch), 25.0, 1.0, Int[], 0.0, rand(prod_d), 0, 0, 0), model)
                push!(model.current.coffee_ids, id)
            else
                add_agent_pos!(Shade(id, Tuple(patch), input.target_shade, 0.0, 0, 0), model)
                push!(model.current.shade_ids, id)
            end
        end
    else
        id = 0
        for patch in CartesianIndices(input.farm_map)
            id += 1
            if input.farm_map[patch]
                add_agent_pos!(Coffee(id, Tuple(patch), 25.0, 1.0, Int[], 0.0, 1.0, 0, 0, 0), model)
                push!(model.current.coffee_ids, id)
            else
                add_agent_pos!(Shade(id, Tuple(patch), input.target_shade, 0.0, 0, 0), model)
                push!(model.current.shade_ids, id)
            end
        end
    end

    count_shades!(model)

    inoculate_rand_rust!(model, input.n_rusts)

    return model

end

## "Step" functions

function pre_step!(model)

    #day = model.days % model.harvest_cycle + 1
    # rain_w = Weights([model.rain_prob[day], (1 - model.rain_prob[day])])
    # model.rain = sample(Bool[1, 0], rain_w)
    # # why not model.rain = rand() < model.rain_prob?
    # wind_w = Weights([model.wind_prob[day], (1 - model.wind_prob[day])])
    # model.wind = sample(Bool[1, 0], wind_w)
    # model.temp_var = (randn() * 2)
    # if length(model.temp_series) < 1
    #     model.temperature = model.mean_temp + model.temp_var
    # else
    #     model.temperature = model.temp_series[day]
    # end
    model.current.rain = model.rain_data[model.current.ticks]
    model.current.wind = model.wind_data[model.current.ticks]
    model.current.temperature = model.temp_data[model.current.ticks]
    if model.karma && rand(model.rng) < sqrt(model.current.outpour)/(model.dims^2)
        inoculate_rand_rust!(model, 1)
    end
end

function shade_step!(tree::Shade, model::ABM)
    grow!(tree, model.shade_rate)
end

function coffee_step!(coffee::Coffee, model::ABM)

    if coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    elseif coffee.exh_countdown == 1
        coffee.area = 25
        coffee.exh_countdown = 0
    else
        update_sunlight!(coffee, model)
        grow!(coffee, model.max_cof_gr)
        acc_production!(coffee)
    end
end

function rust_step!(rust::Rust, model::ABM)

    host = collect(agents_in_position(rust, model))[1]
    if host.area > 0.0 # not exhausted
        if rust.spores > 0.0
            disperse!(rust, host, model)
        end
        parasitize!(rust, host, model)
        grow!(rust, host, model)
    end
end

function model_step!(model)
    if model.current.days % model.harvest_cycle === 0
        harvest!(model)
    end

    model.current.days += 1
    model.current.ticks += 1
    # if model.days % model.fungicide_period === 0
    #     fingicide!(model)
    # end
    # if model.days % model.prune_period === 0
    #     prune!(model)
    # end
    # if model.days % model.inspect_period === 0
    #     inspect!(model)
    # end
end
