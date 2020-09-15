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
end

mutable struct Shade <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    shade::Float64 # between 20 and 90 %
    production::Float64
end

mutable struct Rust <: AbstractAgent
    id::Int
    pos::Tuple{Int,Int}
    germinated::Bool # has it germinated and penetrated leaf tissue?
    area::Float64 # total, equal to latent + sporulating
    spores::Float64
    n_lesions::Int
    #successful_landings::Int # maybe useful metric?
    #parent::Int # id of rust it came from
end

## Setup functions

function count_shades!(model::ABM)
    for c in model.coffee_ids
        neighbors = space_neighbors(model[c], model) # get ids of neighboring plants
        model[c].shade_neighbors = filter(id -> model[id] isa Shade, neighbors)
    end
end

function inoculate_rust!(model::ABM)
    # move from a random cell outside
    # need to update the path function

    rusted_id = rand(model.coffee_ids)
    here = get_node_agents(model[rusted_id], model)
    if length(here) > 1
        here[2].n_lesions += 1
    else
        new_id = nextid(model)
        add_agent_pos!(Rust(new_id, model[rusted_id].pos, true, 0.01, 0.0, 1), model)
        push!(model.rust_ids, new_id)
    end
end

function setup_sim(input::Input)::ABM
    space = GridSpace((input.map_dims, input.map_dims), moore = true)

    props = Dict(
    :dims => input.map_dims,
    :farm_map => input.farm_map,
    :harvest_cycle => input.harvest_cycle,
    :karma => true,
    # farmer's strategy and finances
    :p_density => input.p_density,
    :fungicide_period => input.fungicide_period,
    :prune_period => input.prune_period,
    :inspect_period => 7, #input.inspect_period,
    :target_shade => input.target_shade,
    :n_pruned => 0, # n shade trees pruned
    :coffee_price => input.coffee_price,
    :prune_cost => input.prune_cost,
    # weather and abiotic parameters
    :rain_distance => input.rain_distance,
    :wind_distance => input.wind_distance,
    :rain_prob => input.rain_prob,
    :wind_prob => input.wind_prob,
    :temp_series => input.temp_series,
    :mean_temp => input.mean_temp,
    :uv_inact => input.uv_inact, # extent of effect of sunlight on germination (UV)
    :rain_washoff => input.rain_washoff,
    :temp_cooling => input.temp_cooling, # temp reduction due to shade
    :diff_splash => input.diff_splash, # % extra distance due to enhanced kinetic e (shade)
    :wind_protec => input.wind_protec, # % extra wind distance due to absence of shade
    # biotic parameters
    :shade_rate => input.shade_rate, # shade growth rate
    :fruit_load => input.fruit_load, # extent of fruit load effect on rust growth (severity)
    :spore_pct => input.spore_pct, # percentage of diseased area sporulating
    # record-keeping
    :coffee_ids => Int[],
    :shade_ids => Int[],
    :rust_ids => Int[],
    :outpour => 0.0,
    :days => 1,
    :temp_var => 0.0,
    :temperature => 22,
    :rain => true,
    :wind => true,
    :costs => 0.0,
    :gains => 0.0,
    :yield => 0.0
    )


    model = ABM(Union{Shade, Coffee, Rust}, space;
    properties = props,
    # scheduler = by_type((Shade, Cofffee, Rust), true)
    scheduler = custom_scheduler, warn = false)

    id = 0
    for patch in CartesianIndices(input.farm_map)
        id += 1
        if input.farm_map[patch]
            add_agent_pos!(Coffee(id, Tuple(patch), 25.0, 1.0, Int[], 0.0, 1.0, 0), model)
            push!(model.coffee_ids, id)
        else
            add_agent_pos!(Shade(id, Tuple(patch), input.target_shade, 0.0), model)
            push!(model.shade_ids, id)
        end
    end

    model.n_pruned = trunc(Int, input.pruning_effort * length(model.shade_ids))

    count_shades!(model)

    inoculate_rust!(model)

    return model

end

## "Step" functions

function pre_step!(model)
    day = model.days % model.harvest_cycle + 1
    rain_w = Weights([model.rain_prob[day], (1 - model.rain_prob[day])])
    model.rain = sample(Bool[1, 0], rain_w)
    wind_w = Weights([model.wind_prob[day], (1 - model.wind_prob[day])])
    model.wind = sample(Bool[1, 0], wind_w)
    model.temp_var = (randn() * 2)
    if length(model.temp_series) < 1
        model.temperature = model.mean_temp + model.temp_var
    else
        model.temperature = model.temp_series[day]
    end
    if model.karma && rand() < sqrt(model.outpour)/(model.dims^2)
        inoculate_rust!(model)
    end
end

function agent_step!(tree::Shade, model::ABM)
    grow!(tree, model.shade_rate)
end

function agent_step!(coffee::Coffee, model::ABM)
    days_to_rec = coffee.exh_countdown
    if days_to_rec > 1
        coffee.exh_countdown -= 1
    elseif days_to_rec === 1
        coffee.area = 25
        coffee.exh_countdown = 0
    else
        update_sunlight!(coffee, model)
        grow!(coffee)
        acc_production!(coffee)
    end
end

function agent_step!(rust::Rust, model::ABM)

    host = get_node_agents(rust, model)[1]
    if host.area > 0.0 # not exhausted
        if rust.spores > 0.0
            disperse!(rust, host, model)
        end
        parasitize!(rust, host, model)
        grow!(rust, host, model)
    end
end

function model_step!(model)
    if model.days % model.harvest_cycle === 0
        harvest!(model)
    end
    # if model.days % model.fungicide_period === 0
    #     fingicide!(model)
    # end
    if model.days % model.prune_period === 0
        prune!(model)
    end

    if model.days % model.inspect_period === 0
        inspect!(model)
    end

    model.days += 1
end
