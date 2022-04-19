
export Shade, Coffee, Rust

Base.@kwdef mutable struct Books
    days::Int = 0 # same as ticks unless start_days_at != 0
    ticks::Int = 0
    cycle::Vector{Int} = [0]
    coffee_ids::Vector{Int} = Int[]
    shade_ids::Vector{Int} = Int[]
    rust_ids::Vector{Int} = Int[]
    outpour::Float64 = 0.0
    #temp_var::Float64 = 0.0
    temperature:: Float64 = 0.0
    rain::Bool = true
    wind::Bool = true
    costs::Float64 = 0.0
    net_rev::Float64 = 0.0
    yield::Float64 = 0.0
end

struct Props
    # input parameters
    pars::Parameters

    # record-keeping
    current::Books

    weather::Weather
end

## Agent types and constructor fcts
@agent Coffee GridAgent{2} begin
    area::Float64 # healthy foliar area (= 25 - rust.area * rust.n_lesions/25)
    sunlight::Float64 # let through by shade trees
    shade_neighbors::Vector{Int} # remember which neighbors are shade trees
    progression::Float64
    production::Float64
    exh_countdown::Int
    age::Int
    hg_id::Int # "host-guest id": coffee is host, then this stores corresponding rust's id
    sample_cycle::Vector{Int} # vector with cycles where coffee should be sampled
    #fung_countdown::Int
end

Coffee(id, pos; production = 1.0) = Coffee(id, pos, 1.0, 1.0, Int[], 0.0, production, 0, 0, 0, [100]) # https://juliadynamics.github.io/Agents.jl/stable/api/#Adding-agents

@agent Shade GridAgent{2} begin
    shade::Float64 # between 20 and 90 %
    production::Float64
    age::Int
    hg_id::Int
end

Shade(id, pos; shade = 0.3) = Shade(id, pos, shade, 0.0, 0, 0)

@agent Rust GridAgent{2} begin
    # germinated::Vector{Bool} # has it germinated and penetrated leaf tissue?
    # area::Vector{Float64} # total, equal to latent + sporulating
    # spores::Vector{Bool}
    # age::Vector{Int}
    state::Matrix{Float64}
    n_lesions::Int
    hg_id::Int # "host-guest id": rust is guest, then this stores corresponding host's id
    sample_cycle::Vector{Int} # inherits days of sampling from host
    #successful_landings::Int # maybe useful metric?
    #parent::Int # id of rust it came from
end

# @agent Rust{N} GridAgent{2} begin
#     germinated::MVector{N, Bool} # has it germinated and penetrated leaf tissue?
#     area::MVector{N, Float64} # total, equal to latent + sporulating
#     spores::MVector{N, Bool}
#     age::MVector{N, Int}
#     n_lesions::Int
#     hg_id::Int # "host-guest id": rust is guest, then this stores corresponding host's id
#     sample_cycle::Vector{Int} # inherits days of sampling from host
#     #successful_landings::Int # maybe useful metric?
#     #parent::Int # id of rust it came from
# end

function Rust(
    id::Int, pos::NTuple{2,Int},
    max_lesions::Int,
    max_age::Int;
    germinated::Vector{Bool} = fill(false, max_lesions),
    area::Vector{Float64} = fill(0.0, max_lesions),
    spores::Vector{Bool} = fill(false, max_lesions),
    age::Vector{Int} = fill((max_age + 1), max_lesions),
    n_lesions = 1,
    hg_id = 0,
    sample_cycle = []
    )

    # vgerminated = vcat(germinated, fill(false, (max_lesions - length(germinated))))
    # varea = vcat(area, fill(0.0, (max_lesions - length(area))))
    # vspores = vcat(spores, fill(false, (max_lesions - length(spores))))
    # vage = vcat(age, fill((max_age + 1), (max_lesions - length(age))))

    vgerminated = vcat(germinated, fill(0.0, (max_lesions - length(germinated))))
    varea = vcat(area, fill(0.0, (max_lesions - length(area))))
    vspores = vcat(spores, fill(0.0, (max_lesions - length(spores))))
    vage = vcat(age, fill((max_age + 1.0), (max_lesions - length(age))))

    mstate = vcat(vgerminated', varea', vspores', vage')

    # vgerminated = MVector{max_lesions}(vcat(germinated, fill(false, (max_lesions - length(germinated)))))
    # varea = MVector{max_lesions}(vcat(area, fill(0.0, (max_lesions - length(area)))))
    # vspores = MVector{max_lesions}(vcat(spores, fill(false, (max_lesions - length(spores)))))
    # vage = MVector{max_lesions}(vcat(age, fill((max_age + 1), (max_lesions - length(age)))))

    Rust(id, pos, mstate, n_lesions, hg_id, sample_cycle)
end

# function Rust(id, pos;
#     onelesion::Bool = true,
#     fgerminated::Bool = false,
#     farea::Float64 = 0.0,
#     fspores::Float64 = 0.0,
#     fage::Int = 0,
#     hg_id = 0,
#     sample_cycle = [])
#     Rust(id, pos;
#     germinated = vcat(germinated, fill(false, model.pars.max_lesions - 1)),
#     area = vcat(area, fill(0.0, model.pars.max_lesions - 1)),
#     spores = vcat(spores, fill(0.0, model.pars.max_lesions - 1)),
#     age = vcat(age, fill((model.pars.steps + 1), model.pars.max_lesions - 1)),
#     hg_id = hg_id,
#     sample_cycle = sample_cycle)
# end

## Setup functions

function add_trees!(model::ABM, farm_map::Array{Int,2})
    for patch in positions(model)
        if farm_map[patch...] == 1
            push!(model.current.coffee_ids, add_agent!(patch, Coffee, model).id) # push! works because add_agent! returns the new agent
        elseif farm_map == 2
            push!(model.current.shade_ids, add_agent!(patch, Shade, model; shade = model.pars.target_shade).id)
        end
    end
end

function add_trees!(model::ABM, farm_map::Array{Int,2}, start_days_at::Int)
    cycle_adv = mod(start_days_at, model.pars.harvest_cycle) # how advanced in the harvest cycle are we
    prod_dist = truncated(Normal(cycle_adv, cycle_adv * 0.02), 0.0, cycle_adv)

    for patch in positions(model)
        if farm_map[patch...] == 1
            push!(model.current.coffee_ids, add_agent!(patch, Coffee, model; production = rand(model.rng, prod_dist)).id)
        elseif farm_map == 2
            push!(model.current.shade_ids, add_agent!(patch, Shade, model; shade = model.pars.target_shade).id)
        end
    end
end

function count_shades!(model::ABM)
    for c in model.current.coffee_ids
        neighbors = nearby_ids(model[c], model, model.pars.shade_r) # get ids of neighboring plants
        model[c].shade_neighbors = collect(Iterators.Filter(id -> model[id] isa Shade, neighbors))
    end
end

function init_rusts!(model::ABM, p_rusts::Float64) # inoculate random coffee plants
    # move from a random cell outside
    # need to update the path function
    n_rusts = max(round(Int, p_rusts * length(model.current.coffee_ids)), 1)
    rusted_ids = sample(model.rng, model.current.coffee_ids, n_rusts, replace = false)

    for rusted in rusted_ids
        nlesions = sample(model.rng, 1:model.pars.max_lesions)
        germinates = zeros(model.pars.max_lesions)
        areas = zeros(model.pars.max_lesions)
        spores = zeros(model.pars.max_lesions)
        ages = fill((model.pars.steps + 1.0), model.pars.max_lesions)

        for li in 1:nlesions
            area = rand(model.rng)
            if 0.05 < area < 0.9
                germinates[li] = 1.0
                areas[li] = area
                ages[li] = 0.0
            elseif area > 0.9
                germinates[li] = 1.0
                areas[li] = area
                spores[li] = 1.0
                ages[li] = 0.0
            end
        end

        new_rust = add_agent!(
        model[rusted].pos, Rust, model,
        model.pars.max_lesions,
        model.pars.steps;
        germinated = germinates,
        area = areas,
        spores = spores,
        age = ages,
        n_lesions = nlesions,
        hg_id = model[rusted].id,
        sample_cycle = model[rusted].sample_cycle
        )
        model[rusted].hg_id = new_rust.id
        model[rusted].area = model[rusted].area - (sum(areas) / model.pars.max_lesions)
        push!(model.current.rust_ids, new_rust.id)
    end
end

function init_abm_obj(parameters::Parameters, farm_map::Array{Int,2}, weather::Weather)::ABM
    space = GridSpace((parameters.map_side, parameters.map_side), periodic = false, metric = :chebyshev)

    if parameters.start_days_at <= 132
        model = ABM(Union{Shade, Coffee, Rust}, space;
            properties = Props(parameters, Books(days = parameters.start_days_at), weather),
            warn = false) # ...
    else
        model = ABM(Union{Shade, Coffee, Rust}, space;
            properties = Props(parameters, Books(days = parameters.start_days_at, ticks = parameters.start_days_at - 132, cycle = [4]), weather),
            warn = false)
    end

    if parameters.start_days_at == 0 # simulation starts at the beginning of a harvest cycle
        add_trees!(model, farm_map)
    else
        add_trees!(model, farm_map, parameters.start_days_at) # simulation starts later in harvest cycle, so accumulated production is drawn from truncated normal dist
    end

    count_shades!(model)

    init_rusts!(model, parameters.p_rusts)

    if isempty(model.current.shade_ids)
        push!(model.current.shade_ids, add_agent!(random_empty(model), Shade, model; shade = -1.0).id)
    end

    return model
end
