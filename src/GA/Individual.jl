using StatsBase

DoY(x::Int) = round(Int, 365 * x / 126)
#sch(days::Vector{Int}) = collect(ifelse(s == 1, DoY(f), -1) for (f,s) in Iterators.partition(days, 2))
sch(days::Vector{Int}) = collect(ifelse(d == 1 || d == 128, -1, DoY(d - 1)) for d in days)
propto08(x::Int) = round(x * 0.75 / 64.0, digits = 4)
perioddays(x::Int) = x * 2
proportion(x::Int) = x * inv(256) # (*inv(64) * 0.5)
fung_str(x::Int) = ifelse(x < 3, ifelse(x == 1, :cal, :cal_incd), ifelse(x == 3, :incd, :flor))

function ints_to_pars(transcr::Matrix{Int}, steps, cprice)
    return (
        #row_d = transcr[1],
        #plant_d = transcr[2],
        #shade_d = ifelse(transcr[3] < 2, 100, transcr[3] * 3),
        #barriers = ifelse(Bool(transcr[4] - 1), (1,1), (0,0)),
        #barrier_rows = transcr[5],
        #prune_sch = sch(transcr[6:11]),
        #post_prune = propto08.(transcr[12:14]),
        #inspect_period = perioddays(transcr[15]),
        #inspect_effort = proportion(transcr[16]),
        #fungicide_sch = sch(transcr[17:22]),
        #fung_stratg = fung_str(transcr[23]),
        #incidence_thresh = proportion(transcr[24]),
        prune_sch = sch(transcr[1:3]),
        post_prune = propto08.(transcr[4:6]),
        rm_lesions = transcr[7],
        inspect_period = perioddays(transcr[8]),
        row_d = transcr[9],
        inspect_effort = proportion(transcr[10]),
        plant_d = transcr[11],
        shade_d = ifelse(transcr[12] < 2, 100, transcr[12] * 3),
        barriers = ifelse(Bool(transcr[13] - 1), (1,1), (0,0)),
        fungicide_sch = sch(transcr[14:16]),
        fung_stratg = fung_str(transcr[17]),
        incidence_thresh = proportion(transcr[18]),
        steps = steps,
        coffee_price = cprice
    )
end

function sptlrust_fitness(pars::NamedTuple, reps::Int, steps::Int, cprice::Float64, obj::Symbol, premiums::Bool)
    models = (init_light_spatialrust(
        ; pars...
        ) for _ in 1:reps)
    # models = [pars[[1:3;5;8;9]] for _ in 1:reps]
    #fmod = first(models)
    #pp = fmod.mngpars.post_prune
    #if pars.shade_d < 13 && (isempty(pp) || all(pp .>= 0.4)) # Farfan & Robledo, 2009
    #    shadeprem = 0.1
    #else
    #    shadeprem = 0.0
    #end
    #premiums = false
    
    sumscores = 0.0
    if obj == :profit
        for (i, m) in enumerate(models)
            #sumscores += farm_profit(m, steps, cprice + shadeprem)
            if i % 25 == 0
                @time sumscores += farm_profit(m, steps, cprice, premiums)
                GC.gc()
            else
                sumscores += farm_profit(m, steps, cprice, premiums)
            end
        end
    else
        for (i, m) in enumerate(models)
            if i % 25 == 0
                @time sumscores += severity(m, steps, cprice, premiums)
                GC.gc()
            else
                sumscores += severity(m, steps, cprice, premiums)
            end
        end
    end
    return sumscores / reps
    # return mapreduce(m -> farm_profit(m, pars.steps, pars.coffee_price), +, models) ./ reps
end

function farm_profit(model::SpatialRustABM, steps::Int, cprice::Float64, premiums::Bool)
    s = 0
    
    if premiums
        fungs = 0
        #accshade = 0.0
        accshade = 1.0
        everyn = 7 # (7*4*13=364)
        while s < steps # && model.current.inbusiness
            s += step_n!(model, everyn)
            accshade = min(accshade, copy(model.current.ind_shade))
            if s % 365 == 364
                # model.current.costs += model.mngpars.other_costs * avsunlight - 0.032
                #if model.current.fung_count > 0
                #    nofung = false
                #end
                fungs += model.current.fung_count
                #accshade = copy(model.current.shadeacc)
                step_model!(model)
                s += 1
            end
        end
        
        prem = 0.0
        #if fungs < 2
        if fungs == 0
            #if ((accshade / 364.0) * mean(model.shade_map)) > 0.4
            if (accshade * mean(model.shade_map)) > 0.4
                prem = 0.2
            #elseif fungs == 0
            else
                prem = 0.1
            end
        end
        
        return (model.current.prod) * (cprice + prem) - model.current.costs
        #pp = model.mngpars.post_prune
        #if pars.shade_d < 13 && (isempty(pp) || all(pp .>= 0.4)) # Farfan & Robledo, 2009
        #    shadeprem = 0.1
        #else
        #    shadeprem = 0.0
        #end
        #shaded = true
        #shadeprem = 0.1
        #fungs = 0
        #fungpremium = 0.1
    else
        #shaded = false
        #shadeprem = 0.0
        #nofung = false
        #fungpremium = 0.0
        
        while s < steps #&& model.current.inbusiness
            step_model!(model)
            s += 1
        end
        
        return (model.current.prod) * cprice - model.current.costs
    end
        
    
    # shade_n = 0
    # while s < 365
    #     s += step_n!(model, 5)
    #     shadetracker += model.current.ind_shade
    #     shade_n += 1
    # end

    # avsunlight = 1.0 -  (shadetracker / shade_n) * mean(model.shade_map)
    # model.current.costs += model.mngpars.other_costs * avsunlight - 0.032



    #if !model.current.inbusiness
    #    score = -1e8 #(model.current.prod) * cprice - model.current.costs
    #else
    #    # y_lost = 1.0 - s * inv(steps)
    #    score = (model.current.prod) * cprice - model.current.costs # -(1.0 + y_lost) * (model.current.prod) * cprice - model.current.costs
    #end
    
    

    #return score
    #return (model.current.prod) * (cprice + ifelse(shaded, shadeprem, 0.0) + ifelse(nofung, fungpremium, 0.0)) - model.current.costs
    #return (model.current.prod) * cprice - model.current.costs
    # return model.current.prod
end

function severity(model::SpatialRustABM, steps::Int, cprice::Float64, premiums::Bool)
    s = 0
    sev = 0.0
    insps = 0
    fungs = 0
    #accshade = 0.0
    accshade = 1.0
    
    ninsp = round(Int, length(model.agents) * 0.1)
    allcofs = model.agents

    everyn = 7 # (7*4*13=364)
    while s < steps
        s += step_n!(model, everyn)
        
        inspected = sample(allcofs, ninsp, replace = false)
        sev += mean(map(c -> sum(visible, c.areas, init = 0.0), inspected))
        insps += 1
        
        accshade = min(accshade, copy(model.current.ind_shade))
        
        if s % 365 == 364
            fungs += model.current.fung_count
            #accshade = copy(model.current.shadeacc)
            step_model!(model)
            s += 1
        end
    end
    
    prem = 0.0
    if premiums
        #if fungs < 2
        if fungs == 0
            #if ((accshade / 364.0) * mean(model.shade_map)) > 0.4
            if (accshade * mean(model.shade_map)) > 0.4
                prem = 0.2
            #elseif fungs == 0
            else
                prem = 0.1
            end
        end
    end

    #return score
    return (model.current.prod) * (cprice + prem) - model.current.costs - 1000 * log(sev / insps)
end

visible(a::Float64) = a > 0.05 ? a : 0.0

# function sanction_profit(model::SpatialRustABM, steps::Int, cprice::Float64, premiums::Bool)

#     s = 0
#     clean = 0
#     visits = 0
    
#     if premiums
#         shaded = true
#         shadeprem = 0.1
#         nofung = true
#         fungpremium = 0.1
#     else
#         shaded = false
#         shadeprem = 0.0
#         nofung = false
#         fungpremium = 0.0
#     end
    
#     everyn = 14
#     while s < steps && model.current.inbusiness
#         s += step_n!(model, everyn)
        
#         clean += nosy_visit(model)
#         visits += 1
        
#         if s % 365 == 364
#             if model.current.fung_count > 0
#                 nofung = false
#             end
#             step_model!(model)
#             s += 1
#         end
#     end
    
#     if ((model.current.shadeacc / 365.0) * mean(model.shade_map)) < 0.4
#         shaded = false
#     end
    
#     return ((model.current.prod) * (cprice + ifelse(shaded, shadeprem, 0.0) + ifelse(nofung, fungpremium, 0.0)) - model.current.costs) * (clean / visits)
# end

# function nosy_visit(model)
#     allcofs = model.agents
#     clean = 1
#     ninsp = round(Int, length(allcofs) * 0.1)
#     inspected = sample(allcofs, ninsp, replace = false)
#     if any(map(c -> c.exh_countdown > 0, allcofs)) || mean(map(c -> sum(c.areas, init = 0.0), allcofs)) > 0.05
#         clean = 0
#     end
#     return clean
# end
