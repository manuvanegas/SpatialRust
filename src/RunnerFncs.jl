export dummyrun_spatialrust, nlesions_spatialrust

function dummyrun_spatialrust(steps::Int = 200, side::Int = 60)
    pars = Parameters(steps = steps, map_side = side)
    model = init_spatialrust(pars, create_fullsun_farm_map(), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
    justcofs(a) = a isa Coffee
    justrusts(a) = a isa Rust
    incidence(model::ABM) = length(model.current.rust_ids) / length(model.current.coffee_ids)
    a_df, m_df = run!(model, dummystep, step_model!, steps;
        adata = [(:n_lesions, median, justrusts), (:area, medsum, justrusts), (:production, mean, justcofs)],
        mdata = [incidence])
end

function nlesions_spatialrust(steps::Int = 200, side::Int = 60, maxlesions::Int = 25)
    pars = Parameters(steps = steps, map_side = side, max_lesions = maxlesions)
    model = init_spatialrust(pars, create_fullsun_farm_map(), create_weather(pars.rain_prob, pars.wind_prob, pars.mean_temp, pars.steps))
    justcofs(a) = a isa Coffee
    justrusts(a) = a isa Rust
    incidence(model::ABM) = length(model.current.rust_ids) / length(model.current.coffee_ids)
    a_df, m_df = run!(model, dummystep, step_model!, steps;
        adata = [(:n_lesions, median, justrusts), (:area, medsum, justrusts), (:production, mean, justcofs)],
        mdata = [incidence])
end

function medsum(x); (median ∘ sum)(x); end
