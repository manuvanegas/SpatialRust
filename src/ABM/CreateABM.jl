## Setup functions

# Add coffee agents according to farm_map
function add_trees!(model::SpatialRustABM)
    farm_map::Matrix{Int} = model.farm_map
    shade_map::Matrix{Float64} = model.shade_map
    ind_shade::Float64 = model.current.ind_shade
    max_lesions::Int = model.rustpars.max_lesions
    rustgr_dist = truncated(Normal(model.rustpars.rust_gr, 0.001), 0.0, 0.35)

    cof_pos = findall(x -> x == 1, farm_map)
    for pos in cof_pos
        sunlight = 1.0 - shade_map[pos] * ind_shade
        add_agent!(
            # Tuple(pos), model, max_lesions, max_age, rand(model.rng, rustgr_dist);
            Tuple(pos), model, max_lesions, rand(model.rng, rustgr_dist);
            sunlight = sunlight,
            storage = init_storage(sunlight)
        )
    end
end


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
    return nothing
end

function init_abm_obj(props::Props, rng::Xoshiro, ini_rusts::Float64)::SpatialRustABM
    space = GridSpaceSingle((props.rustpars.map_side, props.rustpars.map_side), periodic = false, metric = :chebyshev)

    model = UnremovableABM(Coffee, space; properties = props, rng = rng)

    # TODO: comment out ABC coffee initialization
    # add_trees!(model)
    # pre_run365!(model, props.mngpars)
    add_abc_trees!(model)
    pre_run_abc!(model, props.mngpars)

    ini_rusts > 0.0 && init_rusts!(model, ini_rusts)

    # print(mean(map(c -> c.veg, model.agents)), ", ")
    # print(mean(map(c -> c.storage, model.agents)), ", ")
    # println(mean(map(c -> c.production, model.agents)))
    return model
end

#assumes harvest_day is 365 and start_day_at is 0
function pre_run365!(model::SpatialRustABM, mngpars::MngPars)
    p1 = p2 = p3 = 0
    t1 = t2 = t3 = 0.0
    prune1 = prune2 = prune3 = no_prune

    sch = mngpars.prune_sch
    shadets = mngpars.target_shade
    lsch = length(sch)
    if lsch == 1
        p1 = sch[1]
        t1 = shadets[1]
        prune1 = prune_shades!
    elseif lsch == 2
        p1, p2 = sch
        t1, t2 = shadets
        prune1 = prune2 = prune_shades!
    elseif lsch == 3
        p1, p2, p3 = sch        
        t1, t2, t3 = shadets
        prune1 = prune2 = prune3 = prune_shades!
    end

    g_rate = mngpars.shade_g_rate

    s = 0
    while s < p1
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune1(model, t1)
    while s < p2
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune2(model, t2)
    while s < p3
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune3(model, t3)
    while s < 365
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    map(harvest_day, model.agents)

    while s < 365 + p1
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune1(model, t1)
    while s < 365 + p2
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune2(model, t2)
    while s < 365 + p3
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune3(model, t3)
    while s < 730
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    map(harvest_day, model.agents)

    model.current.days = 0
    return nothing
end

function no_prune(model::SpatialRustABM, target::Float64)
end

harvest_day(c::Coffee) = c.production = 0.0
