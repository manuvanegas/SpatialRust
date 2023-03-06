function sentinel(id)
    Sentinel(false, id, 0, 0, Int[], Float64[], Bool[])
end

function cycle_sentinels(model::SpatialRustABM, oldcycle::Int, newcycle::Int)
    for s in model.sentinels
        if s.cycle == oldcycle
            s.active = false
            empty!(s.ages)
            empty!(s.areas)
            empty!(s.spores)
            delete!(model.sentinels, s)
        end
    end
    for c in filter(c -> c.sentinel.cycle == newcycle, model.agents)
        c.sentinel.active = true
        # c.sentinel.n_lesions = true

        push!(model.sentinels, c.sentinel)
    end
end

function track_lesion!(sentinel::Sentinel)
    sentinel.n_lesions += 1
    push!(sentinel.ages, -1)
    push!(sentinel.areas, 0.001)
    push!(sentinel.spores, false)
end

# function remove_inactive!(sentinels::Set{Sentinel})

# end