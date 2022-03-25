
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
    germinated::Vector{Bool} # has it germinated and penetrated leaf tissue?
    area::Vector{Float64} # total, equal to latent + sporulating
    spores::Vector{Float64}
    age::Vector{Int}
    n_lesions::Int
    hg_id::Int # "host-guest id": rust is guest, then this stores corresponding host's id
    sample_cycle::Vector{Int} # inherits days of sampling from host
    #successful_landings::Int # maybe useful metric?
    #parent::Int # id of rust it came from
end

function Rust(id, pos;
    germinated = fill(false, model.pars.max_lesions),
    area = fill(0.0, model.pars.max_lesions),
    spores = fill(0.0, model.pars.max_lesions),
    age = fill((model.pars.steps + 1), model.pars.max_lesions),
    n_lesions = 1,
    hg_id = 0,
    sample_cycle = [])

    Rust(id, pos, germinated, area, spores, age, n_lesions, hg_id, sample_cycle)
end

function Rust(id, pos;
    germinated = false,
    area = 0.0,
    spores = 0.0,
    age = 0,
    hg_id = 0,
    sample_cycle = [])
    Rust(id, pos;
    germinated = vcat(germinated, fill(false, model.pars.max_lesions - 1)),
    area = vcat(area, fill(0.0, model.pars.max_lesions - 1)),
    spores = vcat(spores, fill(0.0, model.pars.max_lesions - 1)),
    age = vcat(age, fill((model.pars.steps + 1), model.pars.max_lesions - 1)),
    hg_id = hg_id,
    sample_cycle = sample_cycle)
end

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
    prod_dist = truncated(Normal(start_days_at, start_days_at * 0.02), 0.0, start_days_at)

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
        neighbors = nearby_ids(model[c], model) # get ids of neighboring plants
        model[c].shade_neighbors = collect(Iterators.Filter(id -> model[id] isa Shade, neighbors))
    end
end

function init_rusts!(model::ABM, p_rusts::Float64) # inoculate random coffee plants
    # move from a random cell outside
    # need to update the path function
    n_rusts = max(round(Int, p_rusts * length(model.current.coffee_ids)), 1)
    rusted_ids = sample(model.rng, model.current.coffee_ids, n_rusts, replace = false)

    for rusted in rusted_ids
        area = rand(model.rng)
        nlesions = sample(model.rng, 1:model.pars.max_lesions)
        if area < 0.05
            new_id = add_agent!(model[rusted].pos, Rust, model; age = (model.pars.steps + 1), hg_id = model[rusted].id, sample_cycle = model[rusted].sample_cycle).id
        elseif area > 0.9
            new_id = add_agent!(model[rusted].pos, Rust, model; age = (model.pars.steps + 1), germinated = true, area = area, spores = area * model.pars.spore_pct, hg_id = model[rusted].id, sample_cycle = model[rusted].sample_cycle).id
        else
            new_id = add_agent!(model[rusted].pos, Rust, model; age = (model.pars.steps + 1), germinated = true, area = area, spores = 0.0, hg_id = model[rusted].id, sample_cycle = model[rusted].sample_cycle).id
        end
        model[rusted].hg_id = new_id
        model[rusted].area = model[rusted].area - model[new_id].area
        push!(model.current.rust_ids, new_id)
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
            warn = false) # ...
    end

    if parameters.start_days_at == 0 # simulation starts at the beginning of a harvest cycle
        add_trees!(model, farm_map)
    else
        add_trees!(model, farm_map, parameters.start_days_at) # simulation starts later, so accumulated production is drawn from truncated normal dist
    end

    count_shades!(model)

    init_rusts!(model, parameters.p_rusts)

    return model
end

# function create_bitmap(dims::Int, shade_percent::Float64, fragmentation::Bool = false, random::Bool = true)::BitArray
#     n_shades = round(Int, shade_percent * dims ^ 2)
#     if random == true # random placement of shade trees
#         b_map = trues(dims, dims) # all coffees
#         b_map[sample(1:(dims^2), n_shades, replace = false)] .= false
#     else # produce structured layout
#         if fragmentation == true
#         # TODO: turn fragmentation into Int? -> different levels of fragmentation
#             if (n_shades) > (dims * 6 - 9) # if shade trees are enough to separate space into 4 microlots
#                 b_map = falses(dims,dims)
#                 q_side = dims / 4
#                 coffees_lot, extra = fldmod(((1 - shade_percent) * dims^2)::Float64, 4.0::Float64)
#                 microlot_half_side = (floor(sqrt(coffees_lot)) / 2)
#                 first_q = Int(ceil(q_side))
#                 second_q = Int(ceil(q_side * 3))
#
#                 if microlot_half_side == 0.0 # "radius" of microlot is 0
#                     for x in [first_q, second_q]
#                         for y in [first_q, second_q]
#                             b_map[x, y] = true
#                         end
#                     end
#                 elseif microlot_half_side == 1.0
#                     for x in [first_q, second_q]
#                         for y in [first_q, second_q]
#                             b_map[(x - 1) : x, (y - 1) : y] .= true
#                         end
#                     end
#
#                 elseif microlot_half_side % 1 != 0.0 # "radius" is odd
#                     microlot_half_side = Int(ceil(microlot_half_side - 1))
#                     for x in [first_q, second_q]
#                         for y in [first_q, second_q] # get the (approx) center of each quadrant
#                             b_map[(x - microlot_half_side) : (x + microlot_half_side), (y - microlot_half_side) : (y + microlot_half_side)] .= true
#
#                             rest = coffees_lot - ((microlot_half_side * 2) + 1)^2
#                             extra_x = 0
#                             extra_y = 1
#                             while rest > 0 #add rest of coffee plants
#                                 b_map[(x - microlot_half_side + extra_x), (y - microlot_half_side + extra_y)] = true
#                                 rest = rest - 1
#                                 extra_x = extra_x + 1
#                                 if extra_x > q_side
#                                     extra_x = 0
#                                     extra_y = extra_y + 1
#                                 end
#                             end
#                         end
#                     end
#                 else # "radius" is even
#                     microlot_half_side = Int(microlot_half_side - 1)
#                     for x in [first_q, second_q]
#                         for y in [first_q, second_q] # get the (approx) center of each quadrant
#                             b_map[(x - microlot_half_side - 1) : (x + microlot_half_side), (y - microlot_half_side - 1) : (y + microlot_half_side)] .= true
#
#                             rest = coffees_lot - ((microlot_half_side * 2) + 1)^2
#                             extra_x = 0
#                             extra_y = 1
#                             while rest > 0 #add rest of coffee plants
#                                 b_map[(x - microlot_half_side + extra_x), (y - microlot_half_side + extra_y)] = true
#                                 rest = rest - 1
#                                 extra_x = extra_x + 1
#                                 if extra_x > q_side
#                                     extra_x = 0
#                                     extra_y = extra_y + 1
#                                 end
#                             end
#                         end
#                     end
#                 end
#             else # if shade trees are not enough, divide quadrants until possible
#                 b_map = trues(dims, dims)
#                 half_side = Int(dims / 2)
#                 line_coord = half_side # gets to max 2
#                 x_coor = 1 # gets to max half_side
#                 y_coor = 1
#                 while n_shades > 0
#                     if x_coor <= dims
#                         b_map[x_coor, line_coord] = false
#                         x_coor = x_coor + 1
#                     elseif y_coor <= dims
#                         b_map[line_coord, y_coor] = false
#                         y_coor = y_coor + 1
#                     elseif line_coord == half_side
#                         x_coor = 1
#                         y_coor = 1
#                         line_coord = 1
#                         b_map[x_coor, line_coord] = false
#                         x_coor = x_coor + 1
#                     elseif line_coord == 1
#                         x_coor = 1
#                         y_coor = 1
#                         line_coord = dims
#                         b_map[x_coor, line_coord] = false
#                         x_coor = x_coor + 1
#                     end
#                     n_shades = n_shades - 1
#                 end
#             end
#         else
#             b_map = trues(dims, dims)
#         end
#     end
#     return b_map
# end
