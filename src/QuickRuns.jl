export dummyrun_spatialrust, dummyrun_fullsun_spatialrust, justtwosteps

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
