# struct Input
#     map_dims::Int
#     harvest_cycle::Int # 182 or 365
#     karma::Bool
#     days::Int
#     n_rusts::Int
#     # farmer's strategy and finances
#     p_density::Float64 # 0 to 1
#     fungicide_period::Int # in days
#     prune_period::Int # in days
#     inspect_period::Int # days
#     inspect_effort::Float64 # % coffee plants inspected
#     target_shade::Float64 # 0.2 to 0.9
#     pruning_effort::Float64 # % shade trees pruned
#     coffee_price::Float64 # 1 for now
#     prune_cost::Float64 # 1 for now
#     # weather and abiotic parameters
#     rain_distance::Float64
#     wind_distance::Float64
#     rain_data::Vector{Bool}
#     wind_data::Vector{Bool}
#     temp_data::Vector{Float64}
#     mean_temp::Float64
#     uv_inact::Float64 # extent of effect of UV inactivation (0 to 1)
#     rain_washoff::Float64 # " " " rain wash-off (0 to 1)
#     temp_cooling::Float64 # temp reduction due to shade
#     diff_splash::Float64 # % extra distance due to enhanced kinetic e (shade)
#     wind_protec::Float64 # % extra wind distance due to absence of shade
#     # biotic parameters
#     shade_rate::Float64 # shade growth rate
#     max_cof_gr::Float64
#     opt_g_temp::Float64 # optimal rust growth temp
#     fruit_load::Float64 # extent of fruit load effect on rust growth (severity; 0 to 1)
#     spore_pct::Float64 # % of area that sporulates
#     exhaustion::Float64 # rust level that causes plant exhaustion
#     # when map is given as input
#     farm_map::BitArray
# end

# mutable struct Sampler
#     cycle::Int
#     all_cofs
#     all_rusts # ...
# end

Base.@kwdef mutable struct Books
    days::Int = 0 # same as ticks unless start_days_at != 0
    ticks::Int = 0
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

struct Props
    # input parameters
    pars::Parameters

    # record-keeping
    current::Books

    # "virtual scientist" sampling (ABC)
    # sampler::Sampler
end

# struct Parameters
#     dims::Int
#     #farm_map::BitArray
#     harvest_cycle::Int # 182 or 365
#     karma::Bool
#     # farmer's strategy and finances
#     p_density::Float64 # 0 to 1
#     fungicide_period::Int # in days
#     prune_period::Int # in days
#     inspect_period::Int # days
#     n_inspected::Int # coffee plants inspected
#     target_shade::Float64 # 0.2 to 0.9
#     n_pruned::Int # shade trees pruned
#     #n_pruned::Int 0 # n shade trees pruned
#     coffee_price::Float64 # 1 for now
#     prune_cost::Float64 # 1 for now
#     # weather and abiotic parameters
#     rain_distance::Float64
#     wind_distance::Float64
#     rain_data::Vector{Bool}
#     wind_data::Vector{Bool}
#     temp_data::Vector{Float64}
#     mean_temp::Float64
#     uv_inact::Float64 # extent of effect of UV inactivation (0 to 1)
#     rain_washoff::Float64 # " " " rain wash-off (0 to 1)
#     temp_cooling::Float64 # temp reduction due to shade
#     diff_splash::Float64 # % extra distance due to enhanced kinetic e (shade)
#     wind_protec::Float64 # % extra wind distance due to absence of shade
#     # biotic parameters
#     shade_rate::Float64 # shade growth rate
#     max_cof_gr::Float64
#     opt_g_temp::Float64 # optimal rust growth temp
#     fruit_load::Float64 # extent of fruit load effect on rust growth (severity; 0 to 1)
#     spore_pct::Float64 # % of area that sporulates
#     exhaustion::Float64 # rust level that causes plant exhaustion
#     # record-keeping
#     current::Books
# end

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

Coffee(id, pos; production = 1.0) = Coffee(id, pos, 1.0, 1.0, Int[], 0.0, production, 0, 0, 0, []) # https://juliadynamics.github.io/Agents.jl/stable/api/#Adding-agents

@agent Shade GridAgent{2} begin
    shade::Float64 # between 20 and 90 %
    production::Float64
    age::Int
    hg_id::Int
end

Shade(id, pos; shade = 0.3) = Shade(id, pos, shade, 0.0, 0, 0)

@agent Rust GridAgent{2} begin
    germinated::Bool # has it germinated and penetrated leaf tissue?
    area::Float64 # total, equal to latent + sporulating
    spores::Float64
    n_lesions::Int
    age::Int
    hg_id::Int # "host-guest id": rust is guest, then this stores corresponding host's id
    sample_cycle::Vector{Int} # inherits days of sampling from host
    #successful_landings::Int # maybe useful metric?
    #parent::Int # id of rust it came from
end

Rust(id, pos, germinated = false, area = 0.0, hg_id = 0, sample_cycle = []) = Rust(id, pos, germinated, area, 0.0, 1, 0, hg_id, sample_cycle)

## Setup functions

# function create_props(input::Input)
#     Parameters(
#     dims = input.map_dims,
#     harvest_cycle = input.harvest_cycle,
#     karma = input.karma,
#     # farmer's strategy and finances
#     p_density = input.p_density,
#     fungicide_period = input.fungicide_period,
#     prune_period = input.prune_period,
#     inspect_period = input.inspect_period,
#     n_inspected = trunc(Int, input.inspect_effort * sum(input.farm_map)),
#     target_shade = input.target_shade,
#     n_pruned = trunc(Int, input.pruning_effort * count(==(0), input.farm_map)),
#     coffee_price = input.coffee_price,
#     prune_cost = input.prune_cost,
#     rain_distance =  input.rain_distance,
#     wind_distance = input.wind_distance,
#     rain_data = input.rain_data,
#     wind_data = input.wind_data,
#     temp_data = input.temp_data,
#     mean_temp = input.mean_temp,
#     uv_inact = input.uv_inact,
#     rain_washoff = input.rain_washoff,
#     temp_cooling = input.temp_cooling,
#     diff_splash = input.diff_splash,
#     wind_protec = input.wind_protec,
#     shade_rate = input.shade_rate,
#     max_cof_gr = input.max_cof_gr,
#     opt_g_temp = input.opt_g_temp,
#     fruit_load = input.fruit_load,
#     spore_pct = input.spore_pct,
#     exhaustion = input.exhaustion,
#     # record-keeping
#     current = Books(days = input.days)
#     )
# end

@agent Aut GridAgent{2} begin
end

d_mod = ABM(Aut, GridSpace((3,3) , periodic = false))

for p in positions(d_mod)
   show(p)
end

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

# function fill_trees!(model::ABM, farm_map::BitArray, days::Int)
#     prod_d = truncated(Normal(days, days * 0.02), 0.0, days)
#     # introducing some variability, but most of the plants are expected to have accumulated (close to) optimal productivity
#     id = 0
#     for patch in CartesianIndices(farm_map)
#         id += 1
#         if input.farm_map[patch]
#             add_agent_pos!(Coffee(id, Tuple(patch), 25.0, 1.0, Int[], 0.0, rand(prod_d), 0, 0, 0), model)
#             push!(model.current.coffee_ids, id)
#         else
#             add_agent_pos!(Shade(id, Tuple(patch), input.target_shade, 0.0, 0, 0), model)
#             push!(model.current.shade_ids, id)
#         end
#     end
# end
#
# function fill_trees!(model::ABM, farm_map::BitArray, prod::Float64)
#     id = 0
#     for patch in CartesianIndices(input.farm_map)
#         id += 1
#         if input.farm_map[patch]
#             add_agent_pos!(Coffee(id, Tuple(patch), 25.0, 1.0, Int[], 0.0, 1.0, 0, 0, 0), model)
#             push!(model.current.coffee_ids, id)
#         else
#             add_agent_pos!(Shade(id, Tuple(patch), input.target_shade, 0.0, 0, 0), model)
#             push!(model.current.shade_ids, id)
#         end
#     end
# end
#
# function fill_trees!(model::ABM, all_c::Bool, days::Int)
#     prod_d = truncated(Normal(days, days * 0.02), 0.0, days)
#     id = 0
#     for patch in positions(model)
#         id += 1
#         add_agent_pos!(Coffee(id, Tuple(patch), 25.0, 1.0, Int[], 0.0, rand(prod_d), 0, 0, 0), model)
#     end
# end
#
# function fill_trees!(model::ABM, all_c::Bool, prod::Float64)
#     id = 0
#     for patch in positions(model)
#         id += 1
#         add_agent_pos!(Coffee(id, Tuple(patch), 25.0, 1.0, Int[], 0.0, 1.0, 0, 0, 0), model)
#     end
# end

function count_shades!(model::ABM)
    for c in model.current.coffee_ids
        neighbors = nearby_ids(model[c], model) # get ids of neighboring plants
        model[c].shade_neighbors = collect(Iterators.Filter(id -> model[id] isa Shade, neighbors))
    end
end

function init_rusts!(model::ABM, n_rusts::Int) # inoculate random coffee plants
    # move from a random cell outside
    # need to update the path function

    rusted_ids = sample(model.rng, model.current.coffee_ids, n_rusts, replace = false)

    area_dist = Uniform(0.0, (model.pars.start_days_at / 365))

    for rusted in rusted_ids
        new_id = add_agent!(model[rusted].pos, Rust, model, true, rand(model.rng, area_dist), model[rusted].id, model[rusted].sample_cycle).id
        model[rusted].hg_id = new_id
        model[rusted].area = model[rusted].area - model[new_id].area
        push!(model.current.rust_ids, new_id)
    end
end

function init_abm_obj(parameters::Parameters, farm_map::Array{Int,2}, weather::Weather)::ABM
    space = GridSpace((parameters.map_side, parameters.map_side), periodic = false, metric = :chebyshev)

    # model = ABM(Union{Shade, Coffee, Rust}, space;
    #     properties = create_props(input),
    #     # scheduler = by_type((Shade, Cofffee, Rust), true)
    #     #scheduler = custom_scheduler,
    #     warn = false)

    model = ABM(Union{Shade, Coffee, Rust}, space;
        properties = Props(parameters, Books(days = parameters.start_days_at)),
        warn = false) # ...

    if parameters.start_days_at == 0 # simulation starts at the beginning of a harvest cycle
        add_trees!(model, farm_map)
    else
        add_trees!(model, farm_map, parameters.start_days_at) # simulation starts later, so accumulated production is drawn from truncated normal dist
    end

    # if input.days != 0
    #     if sum(input.farm_map) == input.map_dims ^ 2
    #         fill_trees!(model, true, input.days)
    #         model.current.coffee_ids = collect(1:input.map_dims ^ 2)
    #     else
    #         fill_trees!(model, input.farm_map, input.days)
    #     end
    # elseif sum(input.farm_map) == input.map_dims ^ 2
    #     fill_trees!(model, true, 1.0)
    #     model.current.coffee_ids = collect(1:input.map_dims ^ 2)
    # else
    #     fill_trees!(model, input.farm_map, 1.0)
    # end

    count_shades!(model)

    init_rusts!(model, parameters.n_rusts)

    return model
end

# function initialize_sim(;
#     steps::Int = 10,
#     map_dims::Int = 10,
#     harvest_cycle::Int = 182,
#     karma::Bool = true,
#     start_days_at = 0,
#     n_rusts = 1,
#     shade_percent::Float64 = 0.3,
#     fragmentation::Bool = false,
#     random::Bool = false,
#     p_density::Float64 = 1.0,
#     fungicide_period::Int = 182,
#     prune_period::Int = 91,
#     inspect_period::Int = 7,
#     inspect_effort::Float64 = 0.01,
#     target_shade::Float64 = 0.3,
#     pruning_effort::Float64 = 0.75,
#     coffee_price::Float64 = 1.0,
#     prune_cost::Float64 = 1.0,
#     rain_distance::Float64 = 1.0,
#     wind_distance::Float64 = 5.0,
#     rain_prob::Float64 = 0.5,
#     wind_prob::Float64 = 0.4,
#     mean_temp::Float64 = 22.5,
#     #emp_data::Bool = false,
#     rain_data::Vector{Bool} = [true],
#     temp_data::Vector{Float64} = [22.5],
#     uv_inact::Float64 = 0.1,
#     rain_washoff::Float64 = 0.1,
#     temp_cooling::Float64 = 3.0,
#     diff_splash::Float64 = 2.0, # Avelino et al. 2020 "Kinetic energy was twice as high"
#     wind_protec::Float64 = 1.0, #
#     shade_rate::Float64 = 0.01, # look up
#     max_cof_gr::Float64 = 0.5,
#     opt_g_temp::Float64 = 22.5,
#     fruit_load::Float64 = 1.0, # might not be needed
#     spore_pct::Float64 = 0.6,
#     exhaustion::Float64 = 5.0,
#     farm_map::BitArray = create_bitmap(map_dims, shade_percent, fragmentation, random))::ABM
#
#     if length(rain_data) == 1 # if no weather data is provided, use probs to create own
#         rain_data = rand(Float64, steps) .< rain_prob
#         temp_data = fill(mean_temp, steps) .+ randn() .* 2
#     elseif length(rain_data) != steps
#         println("# steps != length of rain data. Using the latter as # steps")
#     end
#
#
#     wind_data = rand(Float64, steps) .< wind_prob
#
#     input = Input(
#         map_dims,
#         harvest_cycle,
#         karma,
#         start_days_at,
#         n_rusts,
#         p_density,
#         fungicide_period,
#         prune_period,
#         inspect_period,
#         inspect_effort,
#         target_shade,
#         pruning_effort,
#         coffee_price,
#         prune_cost,
#         rain_distance,
#         wind_distance,
#         rain_data, # rain data is passed instead of rain_prob
#         wind_data,
#         temp_data,
#         mean_temp,
#         uv_inact,
#         rain_washoff,
#         temp_cooling,
#         diff_splash,
#         wind_protec,
#         shade_rate,
#         max_cof_gr,
#         opt_g_temp,
#         fruit_load,
#         spore_pct,
#         exhaustion,
#         farm_map)
#
#     return setup_sim(input)
# end

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
