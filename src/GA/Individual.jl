
DoY(x::Int) = round(Int, 365 * x * inv(64))
sch(days::Vector{Int}) = collect(ifelse(s == 1, DoY(f), -1) for (f,s) in Iterators.partition(days, 2))
propto08(x::Int) = x * 0.75 * inv(64)
perioddays(x::Int) = x * 2
proportion(x::Int) = x * inv(128) # (*inv(64) * 0.5)
fung_str(x::Int) = ifelse(x < 3, ifelse(x == 1, :cal, :cal_incd), ifelse(x == 3, :incd, :flor))

function ints_to_pars(transcr::Matrix{Int}, steps, cprice)
    return (
        row_d = transcr[1],
        plant_d = transcr[2],
        shade_d = ifelse(transcr[3] < 2, 100, transcr[3] * 3),
        barriers = ifelse(Bool(transcr[4] - 1), (1,1), (0,0)),
        barrier_rows = transcr[5],
        prune_sch = sch(transcr[6:11]),
        post_prune = propto08.(transcr[12:14]),
        inspect_period = perioddays(transcr[15]),
        inspect_effort = proportion(transcr[16]),
        fungicide_sch = sch(transcr[17:22]),
        fung_stratg = fung_str(transcr[23]),
        incidence_thresh = proportion(transcr[24]),
        steps = steps,
        coffee_price = cprice
    )
end

function sptlrust_profit_fitness(pars::NamedTuple, reps::Int, steps::Int, cprice::Float64)
    models = (init_light_spatialrust(
        ; pars...
        ) for _ in 1:reps)
    # models = [pars[[1:3;5;8;9]] for _ in 1:reps]
    
    fmod = first(models)
    pp = fmod.mngpars.post_prune
    #if pars.shade_d < 13 && (isempty(pp) || all(pp .>= 0.4)) # Farfan & Robledo, 2009
    #    shadeprem = 0.1
    #else
    #    shadeprem = 0.0
    #end
    
    sumscores = 0.0
    
    for m in models
        #sumscores += farm_profit(m, steps, cprice + shadeprem)
        sumscores += farm_profit(m, steps, cprice)
    end
    return sumscores / reps
    # return mapreduce(m -> farm_profit(m, pars.steps, pars.coffee_price), +, models) ./ reps
end

function farm_profit(model::SpatialRustABM, steps::Int, cprice::Float64)
    shadetracker = 0.0
    s = 0
    nofung = true
    fungpremium = 0.1
    
    # shade_n = 0
    # while s < 365
    #     s += step_n!(model, 5)
    #     shadetracker += model.current.ind_shade
    #     shade_n += 1
    # end

    # avsunlight = 1.0 -  (shadetracker / shade_n) * mean(model.shade_map)
    # model.current.costs += model.mngpars.other_costs * avsunlight - 0.032

    everyn = 7 # (7*4*13=364)
    while s <= (steps - 1) && model.current.inbusiness
        s += step_n!(model, everyn)
        if s % 365 == 364
            # model.current.costs += model.mngpars.other_costs * avsunlight - 0.032
            if model.current.fung_count > 0
                nofung = false
            end
            step_model!(model)
            s += 1
        end
    end

    #if !model.current.inbusiness
    #    score = -1e8 #(model.current.prod) * cprice - model.current.costs
    #else
    #    # y_lost = 1.0 - s * inv(steps)
    #    score = (model.current.prod) * cprice - model.current.costs # -(1.0 + y_lost) * (model.current.prod) * cprice - model.current.costs
    #end

    #return score
    #return (model.current.prod) * (cprice + ifelse(nofung, fungpremium, 0.0)) - model.current.costs
    return (model.current.prod) * cprice - model.current.costs
    # return model.current.prod
end