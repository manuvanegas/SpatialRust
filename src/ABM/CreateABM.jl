## Setup functions

# Add coffee agents according to farm_map
function add_trees!(model::SpatialRustABM)
    farm_map::Matrix{Int} = model.farm_map
    shade_map::Matrix{Float64} = model.shade_map
    # startday::Int = model.current.days
    ind_shade::Float64 = model.current.ind_shade
    max_lesions::Int = model.rustpars.max_lesions
    # max_age::Int = model.rustpars.reset_age
    light_noise = truncated(Normal(0.0, 0.005), -0.01, 0.01)
    rustgr_dist = truncated(Normal(model.rustpars.rust_gr, 0.005), 0.0, 0.35)

    cof_pos = findall(x -> x == 1, farm_map)
    for pos in cof_pos
        let sunlight = clamp(1.0 - shade_map[pos] * ind_shade + rand(model.rng, light_noise), 0.0, 1.0)
            add_agent!(
                # Tuple(pos), model, max_lesions, max_age, rand(model.rng, rustgr_dist);
                Tuple(pos), model, max_lesions, rand(model.rng, rustgr_dist);
                sunlight = sunlight,
                veg = init_veg(sunlight),
                storage = init_storage(sunlight)
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

# function add_coffees!(model::SpatialRustABM, start_days_at::Int, pos::CartesianIndex{2})
#     # newcof = Coffee(nextid(model), Tuple(pos); shades = [round(Int, model.shade_map[pos])], production = float(start_days_at))
#     newcof = Coffee(nextid(model), Tuple(pos), 1.0, 1.0, Int[], 0.0, 0.0, 0, 0, 0, Int[])
#
#     add_agent!(newcof, model)
# end

# Add initial rust agents

function rusted_cluster(model::SpatialRustABM, r::Int, avail_cofs) # Returns a "cluster" of initially rusted coffees
    main_c = sample(model.rng, collect(Iterators.filter( 
        c -> all(minp .<= c.pos .<= maxp), avail_cofs
    )))
    cluster = nearby_agents(main_c, model, r)

    return cluster
end

function init_rusts!(model::SpatialRustABM, ini_rusts::Float64) # inoculate coffee plants
    if ini_rusts < 1.0
        n_rusts = max(round(Int, ini_rusts * nagents(model)), 1)
        rusted_cofs = sample(model.rng, model.agents, n_rusts, replace = false)
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
    nl_distr = Binomial(24, 0.05) # Merle, 2020

    for rusted in rusted_cofs
        deposited = 0.0
        # max_nl = model.rustpars.max_lesions
        nl = n_lesions = 1 + rand(model.rng, nl_distr)
        # nl = n_lesions = rand(model.rng, 1:model.rustpars.max_lesions)
        # nl = n_lesions = trunc(Int, rand(model.rng, nl_dist))
        # ages = fill((model.rustpars.steps * 2 + 1), max_nl)
        # areas = zeros(max_nl)
        # spores = fill(false, max_nl)
        ages = rusted.ages
        areas = rusted.areas
        spores = rusted.spores

        for li in 1:nl
            area = rand(model.rng)
            # area = rand(model.rng, a_dist)
            # if area < 0.05 then the lesion is just in the "deposited" state,
            # so no changes have to be made to any of its variables
            if 0.05 < area < 0.9
                # ages[li] = 0
                # areas[li] = area
                push!(ages, 0)
                push!(areas, area)
                push!(spores, false)
            elseif area > 0.9
                # ages[li] = 0
                # areas[li] = area
                # spores[li] = true
                push!(ages, 14)
                push!(areas, area)
                push!(spores, true)
            else
                deposited += 1.0
                n_lesions -= 1
            end
        end

        # sortidx = sortperm(areas; rev = true)

        rusted.rusted = true
        rusted.deposited = deposited
        rusted.n_lesions = n_lesions
        # rusted.ages = ages[sortidx]
        # rusted.areas = areas[sortidx]
        # rusted.spores = spores[sortidx]
        # push!(model.rusts, rusted)
    end
end

function init_abm_obj(props::Props, rng::Xoshiro, ini_rusts::Float64)::SpatialRustABM
    space = GridSpaceSingle((props.rustpars.map_side, props.rustpars.map_side), periodic = false, metric = :chebyshev)

    model = UnremovableABM(Coffee, space; properties = props, rng = rng)

    # TODO: comment out ABC coffee initialization
    # add_trees!(model)
    add_abc_trees!(model)

    ini_rusts > 0.0 && init_rusts!(model, ini_rusts)

    return model
end
