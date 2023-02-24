
# Coffee constructor function
# function Coffee(id, pos, max_lesions::Int, max_age::Int; # https://juliadynamics.github.io/Agents.jl/stable/api/#Adding-agents
#     sunlight::Float64 = 1.0, veg::Float64 = 1.85, storage::Float64 = 100.0, production::Float64 = 0.0,
#     deposited::Float64 = 0.0, ages::Vector{Int} = fill(max_age, max_lesions),
#     areas::Vector{Float64} = fill(0.0, max_lesions), spores::Vector{Bool} = fill(false, max_lesions),
#     n_lesions::Int = 0)

#     # fill_n = max_lesions - length(ages)
    
#     # Coffee(id, pos, sunlight, veg, storage, production, 0, [], deposited, n_lesions,
#     # append!(ages, fill(max_age, fill_n)), append!(areas, fill(0.0, fill_n)),
#     # append!(spores, fill(false, fill_n))) 
#     Coffee(id, pos, sunlight, veg, storage, production, 0, 0, 0.0,
#     deposited, n_lesions, ages, areas, spores) 
# end

function Coffee(id, pos, max_lesions::Int, max_age::Int; # https://juliadynamics.github.io/Agents.jl/stable/api/#Adding-agents
    sunlight::Float64 = 1.0, veg::Float64 = 1.85, storage::Float64 = 100.0)

    # fill_n = max_lesions - length(ages)
    
    # Coffee(id, pos, sunlight, veg, storage, production, 0, [], deposited, n_lesions,
    # append!(ages, fill(max_age, fill_n)), append!(areas, fill(0.0, fill_n)),
    # append!(spores, fill(false, fill_n))) 
    Coffee(id, pos, sunlight, veg, storage, 0.0, 0, 0,
    0.0, 0.0, 0, fill(max_age, max_lesions), fill(0.0, max_lesions), fill(false, max_lesions)) 
end
# Coffee(id, pos; shades = Int[], production = 0.0) = Coffee(id, pos, 1.0, 1.0, shades, 0.0, production, 0, 0, 0, Int[])

## Setup functions

# Add coffee agents according to farm_map
function add_trees!(model::ABM)
    farm_map::Matrix{Int} = model.farm_map
    shade_map::Matrix{Float64} = model.shade_map
    # startday::Int = model.current.days
    ind_shade::Float64 = model.current.ind_shade
    max_lesions::Int = model.rustpars.max_lesions
    max_age::Int = model.rustpars.reset_age

    cof_pos = findall(x -> x == 1, farm_map)
    for pos in cof_pos
        let sunlight = 1.0 - shade_map[pos] * ind_shade
            add_agent!(
                Tuple(pos), model, max_lesions, max_age;
                sunlight = sunlight, storage = init_storage(sunlight)
            )
        end
    end
end

# function appr_storage(shade_map::Matrix{Float64}, target_shade::Float64, start_days::Int, coffee_pars::CoffeePars)
#     prod_cycle_d = start_days % coffee_pars.harvest_day
#     if coffee_pars.veg_d <= prod_cycle_d < coffee_pars.rep_d
#         return new_veg_storage.(shade, target_shade)
#     # elseif coffee_pars.rep_d < coffee_pars.veg_d <= prod_cycle_d
#     #     return new_veg_storage.(shade)
#     else
#         return new_repr_storage.(shade, target_shade)
#     end
# end

# function add_coffees!(model::ABM, start_days_at::Int, pos::CartesianIndex{2})
#     # newcof = Coffee(nextid(model), Tuple(pos); shades = [round(Int, model.shade_map[pos])], production = float(start_days_at))
#     newcof = Coffee(nextid(model), Tuple(pos), 1.0, 1.0, Int[], 0.0, 0.0, 0, 0, 0, Int[])
#
#     add_agent!(newcof, model)
# end

# Add initial rust agents

function rusted_cluster(model::ABM, r::Int, avail_cofs) # Returns a "cluster" of initially rusted coffees
    main_c = sample(model.rng, collect(Iterators.filter( 
        c -> all(minp .<= c.pos .<= maxp), avail_cofs
    )))
    cluster = nearby_agents(main_c, model, r)

    return cluster
end

function init_rusts!(model::ABM, ini_rusts::Real) # inoculate coffee plants
    if ini_rusts < 1.0
        n_rusts = max(round(Int, ini_rusts * nagents(model)), 1)
        rusted_cofs = sample(model.rng, collect(allagents(model)), n_rusts, replace = false)
        # rusted_cofs = collect(model[i] for i in rusted_ids)
    elseif ini_rusts < 2.0
        r = 1
        minp = r + 1
        maxp = model.rustpars.map_side - r
        avail_cofs = Iterators.filter(c -> all(minp .<= c.pos .<= maxp), allagents(model)) # rm coffees in the map margins
        rusted_cofs = rusted_cluster(model, r, avail_cofs)
    else
        r = 1
        minp = r + 1
        maxp = model.rustpars.map_side - r
        avail_cofs = Iterators.filter(c -> all(minp .<= c.pos .<= maxp), allagents(model))
        rusted_cofs = rusted_cluster(model, 1, avail_cofs)
        avail_cofs = Iterators.filter(c -> c ∉ rusted_cofs, avail_cofs)
        for i in 2.0:ini_rusts
            rusted_cofs = Iterators.flatten((rusted_cofs, rusted_cluster(model, 1, avail_cofs)))
            avail_cofs = Iterators.filter(c -> c ∉ rusted_cofs, avail_cofs)
        end
        rusted_cofs = unique(rusted_cofs)
    end

    # nl_dist = LogUniform(1,25.999)
    # a_dist = truncated(Exponential(0.2), 0, 1)
    # rids = collect(getproperty.(rusted_cofs, (:id)))
    nl_distr = Binomial(24, 0.1)

    for rusted in rusted_cofs
        deposited = 0.0
        max_nl = model.rustpars.max_lesions
        nl = n_lesions = 1 + rand(model.rng, nl_distr)
        # nl = n_lesions = rand(model.rng, 1:model.rustpars.max_lesions)
        # nl = n_lesions = trunc(Int, rand(model.rng, nl_dist))
        ages = fill((model.rustpars.steps * 2 + 1), max_nl)
        areas = zeros(max_nl)
        spores = fill(false, max_nl)

        for li in 1:nl
            area = rand(model.rng)
            # area = rand(model.rng, a_dist)
            # if area < 0.05 then the lesion is just in the "deposited" state,
            # so no changes have to be made to any of its variables
            if 0.05 < area < 0.9
                ages[li] = 0
                areas[li] = area
            elseif area > 0.9
                ages[li] = 0
                areas[li] = area
                spores[li] = true
            else
                deposited += 1.0
                n_lesions -= 1
            end
        end

        sortidx = sortperm(areas; rev = true)

        rusted.deposited = deposited
        rusted.n_lesions = n_lesions
        rusted.ages = ages[sortidx]
        rusted.areas = areas[sortidx]
        rusted.spores = spores[sortidx]
        push!(model.current.rusts, rusted)
    end
end

function init_abm_obj(props::Props)::ABM
    space = GridSpaceSingle((props.rustpars.map_side, props.rustpars.map_side), periodic = false, metric = :chebyshev)

    model = UnkillableABM(Coffee, space; properties = props, warn = false)

    # TODO: comment out ABC coffee initialization
    # add_trees!(model)
    add_abc_trees!(model)

    return model
end

function init_abm_obj(props::Props, ini_rusts::Float64)::ABM
    model = init_abm_obj(props)
    init_rusts!(model, ini_rusts)

    return model
end
