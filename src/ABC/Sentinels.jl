function sentinel(id)
    Sentinel(false, id, 0, 0,
    # Int[],
    Float64[], Bool[])
end

function cycle_sentinels(model::SpatialRustABM, oldcycle::Int, newcycle::Int)
    for s in model.sentinels
        if s.cycle == oldcycle
            s.active = false
            # empty!(s.ages)
            empty!(s.areas)
            empty!(s.spores)
            delete!(model.sentinels, s)
        end
    end
    for c in filter(c -> c.sentinel.cycle == newcycle, model.agents)
        c.sentinel.active = true
        nonvisibles = filter!(i -> !c.spores[i], findall(<(0.001), c.areas))
        # c.sentinel.ages = @inbounds c.ages[nonvisibles]
        # c.sentinel.visibles = falses(length(nonvisibles))
        c.sentinel.areas = @inbounds c.areas[nonvisibles]
        c.sentinel.spores = @inbounds c.spores[nonvisibles]

        push!(model.sentinels, c.sentinel)
    end
end

function track_lesion!(sentinel::Sentinel)
    sentinel.n_lesions += 1
    # push!(sentinel.ages, 0)
    push!(sentinel.areas, 0.00005)
    push!(sentinel.spores, false)
end

# function remove_inactive!(sentinels::Set{Sentinel})

# end