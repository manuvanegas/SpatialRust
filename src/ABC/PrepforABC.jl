## Plant sampling setup

function setup_plant_sampling!(model::ABM, ncycles::Int, nblocks::Int)
    # draw 5x5 sampling blocks
    blocks = sample(model.rng, 1:324, nblocks, replace = false)
    # create matrix with block position coordinates from 1 to 5
    blockcoords = [(i,j) for i in 1:5, j in 1:5]
    middlecoords = [(i,j) for i in 2:4, j in 2:4]

    if ncycles == 3
        nadd = 2 # n of additional coffees to sample (after 1st is sampled from central 3x3 block)
        init = 1 # id of initial cycle
    elseif ncycles == 6
        nadd = 6
        init = 4
    end

    for b in blocks
        # find last row and column before the block begins
        r = mod1(b, 18) * 5
        c = (div(b, 18) + 1) * 5
        # get 5x5 section of matrix storing coffee ids
        idsinblock = model.space.stored_ids[(r + 1):(r + 5), (c + 1):(c + 5)]

        # draw position (within central block) of initial coffee
        c1pos = sample(model.rng, middlecoords, weights(idsinblock[2:4,2:4] .> 0))
        c1id = idsinblock[c1pos...]

        # calculate sampling weights (euclidean distance to c1), but if position is empty, then weight = 0
        distweights = quickdist.(blockcoords, Ref(c1pos)) .* (idsinblock .> 0)
        cofs = sample(model.rng, idsinblock, weights(distweights), nadd, replace = false)

        # assign sample cycle id to each coffee 
        model[c1id].sample_cycle = init
        for (cycle, cof) in enumerate(cofs)
            model[cof].sample_cycle = cycle + init
        end
    end
end

quickdist(pos1::NTuple{2,Int}, pos2::NTuple{2,Int}) = sqrt(sum((pos1 .- pos2) .^ 2))


## Coffee storage and veg initialization

function add_abc_trees!(model::ABM)
    farm_map::Matrix{Int} = model.farm_map
    shade_map::Matrix{Float64} = model.shade_map
    ind_shade::Float64 = model.current.ind_shade
    max_lesions::Int = model.rustpars.max_lesions
    max_age::Int = model.rustpars.reset_age
    light_noise = truncated(Normal(0.0, 0.005), -0.01, 0.01)
    rustgr_dist = truncated(Normal(model.rustpars.rust_gr, 0.005), 0.0, 0.35)

    cof_pos = findall(x -> x == 1, farm_map)
    for pos in cof_pos
        let sunlight = clamp(1.0 - shade_map[pos] * ind_shade + rand(model.rng, light_noise), 0.0, 1.0)
            add_agent!(
                Tuple(pos), model, max_lesions, max_age, rand(model.rng, rustgr_dist);
                sunlight = sunlight, 
                veg = init_veg_116(sunlight),
                storage = init_storage_116(sunlight)
            )
        end
    end
end

function init_veg_116(sunlight::Float64)
    return -2.9 * exp(-4.2 * sunlight) + 4.7
end

function init_storage_116(sunlight::Float64)
    return 100.0 * exp(-6.5 * sunlight) + 7.8
end