export dummyrun_spatialrust, simplerun, justtwosteps

function dummyrun_spatialrust(steps::Int = 200, side::Int = 60, maxlesions::Int = 25; kwargs...)
    model = init_spatialrust(steps = steps, map_side = side, max_lesions = maxlesions; kwargs...)

    a_df, m_df = run!(model, dummystep, step_model!, steps;
        # adata = [(:n_lesions, median, justrusts), (:state, medsum_s, justrusts), (:production, mean, justcofs)],
        adata = [(:n_lesions, emedian, rusted), (tot_area, emedian, rusted), (:production, mean)],
        mdata = [incidence, n_rusts])
    rename!(a_df, [:step, :n_lesion_med, :tot_area_med, :production_mean])

    return a_df, m_df, model
end

# function dummyrun_fullsun_spatialrust(steps::Int = 200, side::Int = 60, maxlesions::Int = 25; kwargs...)
#     model = init_spatialrust(steps = steps, map_side = side, max_lesions = maxlesions, common_map = :fullsun; kwargs...)

#     a_df, m_df = run!(model, dummystep, step_model!, steps;
#         # adata = [(:n_lesions, median, justrusts), (:state, medsum_s, justrusts), (:production, mean, justcofs)],
#         adata = [(:n_lesions, emedian, rusted), (tot_area, emedian, rusted), (:production, mean)],
#         mdata = [incidence, n_rusts])
#     rename!(a_df, [:step, :n_lesion_med, :tot_area_med, :production_mean])

#     return a_df, m_df, model
# end

function justtwosteps(side::Int = 60)
    model = init_spatialrust(steps = steps, map_side = side, max_lesions = maxlesions, common_map = :fullsun)
    step!(model, dummystep, step_model!, 2)
    return model
end

function simplerun(steps::Int = 365; kwargs...)
    model = init_spatialrust(steps = steps; kwargs...)

    df = runsimple!(model, steps)

    return df#, model
end

function runsimple!(model::SpatialRustABM, steps::Int)
    meanshade = mean(model.shade_map)
    ncofs = length(model.agents)

    df = DataFrame(dayn = Int[],
        veg = Float64[], storage = Float64[], production = Float64[],
        indshade = Float64[], mapshade = Float64[],
        nl = Float64[], sumarea = Float64[], sumspore = Float64[],
        active = Float64[]
    )
    for c in eachcol(df)
        sizehint!(c, steps)
    end

    s = 0
    while s < steps
        indshade = model.current.ind_shade

        sumareas = Iterators.filter(>(0.0), map(r -> sum(r.areas), model.agents))
        if isempty(sumareas)
            msuma = 0.0
            msumsp = 0.0
        else
            msuma = mean(sumareas)
            sumspores = map(r -> sum(r.spores), model.agents)
            msumsp = mean(sumspores)
        end

        push!(df, [
            model.current.days,
            mean(map(a -> a.veg, model.agents)),
            mean(map(a -> a.storage, model.agents)),
            mean(map(a -> a.production, model.agents)),
            indshade,
            indshade * meanshade,
            mean(map(a -> a.n_lesions, model.agents)),
            msuma,
            msumsp,
            sum(active.(model.agents)) / ncofs
        ])
        step!(model, dummystep, step_model!, 1)
        s += 1
    end

    indshade = model.current.ind_shade
    
    sumareas = Iterators.filter(>(0.0), map(r -> sum(r.areas), model.agents))
    if isempty(sumareas)
        msuma = 0.0
        msumsp = 0.0
    else
        msuma = mean(sumareas)
        sumspores = map(r -> sum(r.spores), model.agents)
        msumsp = mean(sumspores)
    end

    push!(df, [
        model.current.days,
        mean(map(a -> a.veg, model.agents)),
        mean(map(a -> a.storage, model.agents)),
        mean(map(a -> a.production, model.agents)),
        indshade,
        indshade * meanshade,
        mean(map(a -> a.n_lesions, model.agents)),
        msuma,
        msumsp,
        sum(active.(model.agents)) / ncofs
    ])

    return df
end
