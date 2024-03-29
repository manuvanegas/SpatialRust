## Plant sampling setup

function setup_plant_sampling!(model::SpatialRustABM, ncycles::Int, nblocks::Int)
    # create matrix with block position coordinates from 1 to 5
    blockcoords = [(i,j) for i in 1:5, j in 1:5]
    middlecoords = [(i,j) for i in 2:4, j in 2:4]

    if ncycles == 3
        nadds = [2] # n of additional coffees to sample (after 1st is sampled from central 3x3 block)
        inits = [1] # id of initial cycle
        plots = 1
        # draw 5x5 sampling blocks
        blocks = [sample(model.rng, 1:324, nblocks, replace = false)]
    elseif ncycles == 6
        nadds = [6]
        inits = [4]
        plots = 1
        # draw 5x5 sampling blocks
        blocks = [sample(model.rng, 1:324, nblocks, replace = false)]
    elseif ncycles == 9
        nadds = [2, 5]
        inits = [1, 4]
        plots = 2
        # draw 5x5 sampling blocks
        blocks = [sample(model.rng, 1:144, nblocks, replace = false),
        sample(model.rng, 181:324, nblocks, replace = false)][shuffle!([1,2])]
    end

    for p in 1:plots, b in blocks[p]
        nadd = nadds[p]
        init = inits[p]
        # find last row and column before the block begins
        r = mod1(b, 18) * 5
        c = (div(b - 1, 18) + 1) * 5
        # get 5x5 section of matrix storing coffee ids
        idsinblock = model.space.stored_ids[(r + 1):(r + 5), (c + 1):(c + 5)]

        # draw position (within central block) of initial coffee
        c1pos = sample(model.rng, middlecoords, weights(idsinblock[2:4,2:4] .> 0))
        c1id = idsinblock[c1pos...]

        # calculate sampling weights (euclidean distance to c1), but if position is empty, then weight = 0
        distweights = quickdist.(blockcoords, Ref(c1pos)) .* (idsinblock .> 0)
        cofs = sample(model.rng, idsinblock, weights(distweights), nadd, replace = false)

        # assign sample cycle id to each coffee 
        model[c1id].sentinel.cycle = init
        for (cycle, cof) in enumerate(cofs)
            model[cof].sentinel.cycle = cycle + init
        end
    # end
    end
end

quickdist(pos1::NTuple{2,Int}, pos2::NTuple{2,Int}) = sqrt(sum((pos1 .- pos2) .^ 2))


## Coffee storage and veg initialization

function add_abc_trees!(model::SpatialRustABM)
    farm_map::Matrix{Int} = model.farm_map
    ind_shade::Float64 = model.current.ind_shade
    max_lesions::Int = model.rustpars.max_lesions
    rustgr_dist = truncated(Normal(model.rustpars.rust_gr, 0.001), 0.0, 0.35)

    cof_pos = findall(x -> x == 1, farm_map)

    if @inbounds farm_map[1] == 2
        shade_map::Matrix{Float64} = model.shade_map
        for pos in cof_pos
            sunlight = 1.0 - shade_map[pos] * ind_shade
            add_agent!(
                Tuple(pos), model, max_lesions, rand(model.rng, rustgr_dist);
                sunlight = sunlight, 
                veg = init_veg_116(sunlight),
                storage = init_storage_116(sunlight)
            )
        end
    else
        for pos in cof_pos
            add_agent!(
                Tuple(pos), model, max_lesions, rand(model.rng, rustgr_dist);
                sunlight = 1.0, 
                veg = init_veg_116(1.0),
                storage = init_storage_116(1.0)
            )
        end
    end
end

function init_veg_116(sunlight::Float64)
    return -2.9 * exp(-4.2 * sunlight) + 4.7
end

function init_storage_116(sunlight::Float64)
    # return 80.0 * exp(-5.8 * sunlight) + 7.8
    return 100.0 * exp(-7.1 * sunlight) + 7.8
end

function pre_run_abc!(model::SpatialRustABM, mngpars::MngPars)

    g_rate = mngpars.shade_g_rate

    s = 115
    while s < 166
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune_shades!(model, 0.2)
    while s < 365
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    map(harvest_day, model.agents)

    while s < 380
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune_shades!(model, 0.15)
    while s < 531
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune_shades!(model, 0.2)
    while s < 730
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    map(harvest_day, model.agents)

    while s < 381
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end
    prune_shades!(model, 0.15)
    while s < 845
        model.current.days += 1
        grow_shades!(model.current, g_rate)
        coffee_step!(model)
        s += 1
    end

    model.current.days = 115
    return nothing
end
