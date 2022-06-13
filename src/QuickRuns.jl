export dummyrun_spatialrust, dummyrun_fullsun_spatialrust, justtwosteps

function dummyrun_spatialrust(steps::Int = 200, side::Int = 60, maxlesions::Int = 25)
    pars = Parameters(steps = steps, map_side = side, max_lesions = maxlesions)
    model = init_spatialrust(pars)

    a_df, m_df = run!(model, dummystep, step_model!, steps;
        # adata = [(:n_lesions, median, justrusts), (:state, medsum_s, justrusts), (:production, mean, justcofs)],
        adata = [(:n_lesions, median, justrusts), (:production, mean, justcofs)],
        mdata = [incidence])
end

function dummyrun_fullsun_spatialrust(steps::Int = 200, side::Int = 60, maxlesions::Int = 25)
    pars = Parameters(steps = steps, map_side = side, max_lesions = maxlesions)
    model = init_spatialrust(pars, create_fullsun_farm_map(side), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))

    a_df, m_df = run!(model, dummystep, step_model!, steps;
        # adata = [(:n_lesions, median, justrusts), (:state, medsum_s, justrusts), (:production, mean, justcofs)],
        adata = [(:n_lesions, median, justrusts), (:production, mean, justcofs)],
        mdata = [incidence])
end

function justtwosteps(side::Int = 60)
    pars = Parameters(steps = 5, map_side = side, max_lesions = 25)
    model = init_spatialrust(pars, create_fullsun_farm_map(side))
    step!(model, dummystep, step_model!, 2)
    return model
end
