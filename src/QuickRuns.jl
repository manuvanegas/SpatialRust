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

    return df
end

function runsimple!(model::SpatialRustABM, steps::Int)
    meanshade = mean(model.shade_map)
    ncofs = length(model.agents)

    df = DataFrame(dayn = Int[],
        veg = Float64[], storage = Float64[], production = Float64[],
        indshade = Float64[], mapshade = Float64[],
        nl = Float64[], sumarea = Float64[], sumspore = Float64[],
        active = Float64[], nrusts = Int[]
    )
    for c in eachcol(df)
        sizehint!(c, steps)
    end

    s = 0
    while s < steps
        indshade = model.current.ind_shade

        sumareas = sum.(getproperty.(model.agents, :areas))
        # sumareas = filter(>(-10.0), sum.(getproperty.(model.agents, :areas)))
        if isempty(sumareas)
            msuma = 0.0
            msumsp = 0.0
        else
            msuma = mean(sumareas)
            sumspores = sum.(getproperty.(model.agents, :spores))
            # sumspores = filter(>(-10.0), sum.(getproperty.(model.agents, :spores)))
            msumsp = isempty(sumareas) ? 0.0 : mean(sumspores)
        end

        push!(df, [
            s,
            mean(getproperty.(model.agents, :veg)),
            mean(getproperty.(model.agents, :storage)),
            mean(getproperty.(model.agents, :production)),
            indshade,
            indshade * meanshade,
            mean(getproperty.(model.agents, :n_lesions)),
            msuma,
            msumsp,
            sum(active.(model.agents)) / ncofs,
            length(model.rusts)
        ])
        step!(model, dummystep, step_model!, 1)
        s += 1
    end

    indshade = model.current.ind_shade

    sumareas = filter(>(0.0), sum.(getproperty.(model.agents, :areas)))
    if isempty(sumareas)
        msuma = 0.0
        msumsp = 0.0
    else
        msuma = mean(sumareas)
        sumspores = filter(>(0.0), sum.(getproperty.(model.agents, :spores)))
        isempty(sumareas) ? (msumsp = 0.0) : (msumsp = mean(sumspores))
    end

    push!(df, [
        s,
        mean(getproperty.(model.agents, :veg)),
        mean(getproperty.(model.agents, :storage)),
        mean(getproperty.(model.agents, :production)),
        indshade,
        indshade * meanshade,
        mean(getproperty.(model.agents, :n_lesions)),
        msuma,
        msumsp,
        sum(active.(model.agents)) / ncofs,
        length(model.rusts)
    ])
    return df
end
