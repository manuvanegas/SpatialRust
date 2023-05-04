
DoY(x::Int) = round(Int, 365 * x * inv(32))
propto08(x::Int) = (x + 1) * 0.75 * inv(32)
perioddays(x::Int) = (x + 1) * 4
proportion(x::Int) = (x + 1) * inv(32)

function ints_to_pars(transcr::Vector{Int}, steps, cprice)
    return (
        row_d = transcr[1],
        plant_d = transcr[2],
        shade_d = transcr[3],
        barriers = ifelse(Bool(transcr[4]), (1,1), (0,0)),
        barrier_row = transcr[5],
        prune_sch = DoY.(transcr[6:8]),
        post_prune = propto08.(transcr[9:11]),
        inspect_period = perioddays(transcr[12]),
        inspect_effort = proportion(transcr[13]),
        fungicide_sch = DoY.(transcr[14:16]),
        incidence_as_thr = Bool(transcr[17]),
        incidence_thr = proportion(transcr[18]),
        steps = steps,
        coffee_price = cprice
    )
end

function sptlrust_profit_fitness(pars::NamedTuple, reps::Int)
    models = [init_spatialrust(
        ; pars...
        ) for _ in 1:reps]
    # models = [pars[[1:3;5;8;9]] for _ in 1:reps]

    return mapreduce(farm_profit, +, models) ./ reps
end

function farm_profit(model::SpatialRustABM)
    shadetracker = zeros(365)

    s = 1
    while s < 366
        step!(model, dummystep, step_model!, 1)
        shadetracker[s] = model.current.ind_shade
        s += 1
    end

    avsunlight = 1.0 -  mean(shadetracker) * mean(model.shade_map)
    model.current.costs += model.mngpars.other_costs * avsunlight - 0.07

    while s <= steps && model.current.inbusiness
        step!(model, dummystep, step_model!, 1)
        if s % 364 == 0
            model.current.costs += model.mngpars.other_costs * avsunlight - 0.07
        end
        s += 1
    end

    if model.current.inbusiness
        score = -maxspores
    else
        y_lost = 1.0 - s * inv(steps)
        score = -(1.0 + y_lost) * maxspores
    end

    return (model.current.prod) * price - model.current.costs
end