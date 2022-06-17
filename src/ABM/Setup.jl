export Coffee, Rust

## Agent types and constructor fcts
mutable struct Coffee <: AbstractAgent
    id::Int
    pos::NTuple{2, Int}
    area::Float64 # healthy foliar area (= 25 - rust.area * rust.n_lesions/25)
    sunlight::Float64 # let through by shade trees
    shade_neighbors::Vector{Float64} #Float64 # remember which neighbors are shade trees
    progression::Float64
    production::Float64
    exh_countdown::Int
    age::Int
    hg_id::Int # "host-guest id": coffee is host, then this stores corresponding rust's id
    sample_cycle::Vector{Int} # vector with cycles where coffee should be sampled
    #fung_countdown::Int
end

Coffee(id, pos; shades = [0.0], production = 0.0) = Coffee(id, pos, 1.0, 1.0, shades, 0.0, production, 0, 0, 0, []) # https://juliadynamics.github.io/Agents.jl/stable/api/#Adding-agents
# Coffee(id, pos; shades = Int[], production = 0.0) = Coffee(id, pos, 1.0, 1.0, shades, 0.0, production, 0, 0, 0, Int[])

# mutable struct Shade <: AbstractAgent
#     id::Int
#     pos::NTuple{2, Int}
#     shade::Float64 # between 20 and 90 %
#     production::Float64
#     age::Int
#     hg_id::Int
# end
#
# Shade(id, pos; shade = 0.3) = Shade(id, pos, shade, 0.0, 0, 0)

mutable struct Rust <: AbstractAgent
    id::Int
    pos::NTuple{2, Int}
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
    germinated::Vector{Float64} = fill(0.0, max_lesions),
    area::Vector{Float64} = fill(0.0, max_lesions),
    spores::Vector{Float64} = fill(0.0, max_lesions),
    age::Vector{Float64} = fill((max_age + 1.0), max_lesions),
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

## Model properties and book-keeping

Base.@kwdef mutable struct Books
    days::Int = 0 # same as ticks unless start_days_at != 0
    ticks::Int = 0
    cycle::Vector{Int} = [0]
    coffees::Vector{Coffee} = Coffee[]
    # shade_ids::Vector{Int} = Int[]
    rusts::Vector{Rust} = Rust[]
    ind_shade::Float64 = 0.0
    n_shades::Int = 0
    outpour::Float64 = 0.0
    #temp_var::Float64 = 0.0
    temperature:: Float64 = 0.0
    rain::Bool = true
    wind::Bool = true
    wind_h::Float64 = 0.0
    fung_effect::Int = 0
    costs::Float64 = 0.0
    net_rev::Float64 = 0.0
    prod::Float64 = 0.0
    max_rust::Float64 = 0.0
end

struct Props
    # input parameters
    pars::Parameters
    # record-keeping
    current::Books
    # weather time-series
    weather::Weather
    # farm map
    farm_map::Array{Int,2}
    # shade map
    shade_map::Matrix{Float64}
end

## Setup functions

# Shade map

function create_shade_map(farm_map::Matrix{Int}, shade_r::Int, side::Int)
    possible_ns = CartesianIndices((-shade_r:shade_r, -shade_r:shade_r))
    # possible_ns = [CartesianIndex(a) for a in Iterators.product([(-shade_r):shade_r for d in 1:2]...)]
    shades = findall(x -> x == 2, farm_map)
    shade_map = zeros(size(farm_map))
    # shade_map = map(x -> zeros(1), farm_map)
    for sh in shades
        shade_map[sh] += 1.0
        neighs = Iterators.filter(x -> in_farm(x, side), sh + n for n in possible_ns)
        for n in neighs
            shade_map[n] += 1 / shade_dist(sh, n)
        end
    end
    # maxs = findall(y -> y[1] > 1.0, shade_map)
    # for m in maxs
    #     shade_map[m][1] = 1.0
    # end
    shade_map = min.(1.0, shade_map)
    return shade_map
end

function shade_dist(pos1::CartesianIndex{2}, pos2::CartesianIndex{2})
    caths = pos1 - pos2
    @inbounds dist = sqrt(caths[1]^2 + caths[2]^2)
    return dist + 0.05
end

function shade_dist(pos1::Tuple, pos2::Tuple)
    caths = pos1 .- pos2
    dist = sqrt(caths[1]^2 + caths[2]^2)
    return dist + 0.05
end

function in_farm(coord::CartesianIndex, side::Int)::Bool
    @inbounds for d in 1:2
        1 <= coord[d] <= side || return false
    end
    return true
end
# Add coffee agents according to farm_map

# function add_trees!(model::ABM, start_days_at::Int)
#     cof_pos = findall(x -> x == 1, model.farm_map)
#     for pos in cof_pos
#         push!(model.current.coffees, add_agent!(
#         Tuple(pos), Coffee, model; shades = model.shade_map[pos], production = start_days_at).id
#         )
#     end
# end

function add_trees!(model::ABM, farm_map::Matrix{Int}, shade_map::Matrix{Float64}, start_days_at::Int)
    cof_pos = findall(x -> x == 1, farm_map)
    for pos in cof_pos
        let shade = shade_map[pos]
        push!(model.current.coffees, add_agent!(
        # model, start_days_at, pos).id
        Tuple(pos), Coffee, model; shades = [shade], production = start_days_at)
        )
        end
    end
end
function count_shades()
end

# function add_coffees!(model::ABM, start_days_at::Int, pos::CartesianIndex{2})
#     # newcof = Coffee(nextid(model), Tuple(pos); shades = [round(Int, model.shade_map[pos])], production = float(start_days_at))
#     newcof = Coffee(nextid(model), Tuple(pos), 1.0, 1.0, Int[], 0.0, 0.0, 0, 0, 0, Int[])
#
#     add_agent!(newcof, model)
# end

# Add initial rust agents

function init_rusted(model::ABM, r::Int) # Returns a "cluster" of initially rusted coffees
    minp = r + 1
    maxp = model.pars.map_side - r
    main = sample(model.rng, collect(Iterators.filter( # sample 1 coffee not in the map margins
        c -> all(minp .<= c.pos .<= maxp), allagents(model)
    )))
    cluster = nearby_agents(main, model, r)

    return cluster
end

function init_rusts!(model::ABM, ini_rusts::Float64) # inoculate coffee plants
    if ini_rusts < 1.0
        n_rusts = max(round(Int, ini_rusts * length(model.current.coffees)), 1)
        rusted_cofs = sample(model.rng, model.current.coffees, n_rusts, replace = false)
        # rusted_cofs = collect(model[i] for i in rusted_ids)
    else
        for i in 1:floor(Int, ini_rusts)
            rusted_cofs = init_rusted(model, 2)
        end
    end

    for rusted in rusted_cofs
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
        rusted.pos, Rust, model,
        model.pars.max_lesions,
        model.pars.steps;
        germinated = germinates,
        area = areas,
        spores = spores,
        age = ages,
        n_lesions = nlesions,
        hg_id = rusted.id,
        sample_cycle = rusted.sample_cycle
        )
        rusted.hg_id = new_rust.id
        rusted.area = rusted.area - (sum(areas) / model.pars.max_lesions)
        push!(model.current.rusts, new_rust)
    end
end

function init_abm_obj(parameters::Parameters, farm_map::Array{Int,2}, weather::Weather)::ABM
    space = GridSpace((parameters.map_side, parameters.map_side), periodic = false, metric = :chebyshev)

    shade_map = create_shade_map(farm_map, parameters.shade_r, parameters.map_side)

    if parameters.start_days_at <= 132
        properties = Props(parameters, Books(
        days = parameters.start_days_at,
        ind_shade = parameters.target_shade,
        ), weather,
        farm_map,
        shade_map
        )
    else
        properties = Props(parameters, Books(
        days = parameters.start_days_at,
        ind_shade = parameters.target_shade,
        # ticks = ?,
        cycle = [4]), weather,
        farm_map,
        shade_map
        )
    end

    model = ABM(Union{Coffee, Rust}, space; properties = properties, warn = false)

        # model = ABM(Union{Shade, Coffee, Rust}, space;
        #     properties = Props(parameters, Books(days = parameters.start_days_at,
# "ticks = parameters.start_days_at - 132"
        # , cycle = [4]), weather),
        #     warn = false)

    # update_shade_map!(model)

    add_trees!(model, farm_map, shade_map, parameters.start_days_at)

    init_rusts!(model, parameters.ini_rusts)

    return model
end
