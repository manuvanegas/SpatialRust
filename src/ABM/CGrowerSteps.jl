function harvest!(model::SpatialRustABM)
    yprod = sum(map(c -> c.production, model.agents))
    model.current.prod += yprod
    cost = model.current.costs += model.mngpars.fixed_costs +
        yprod * (model.mngpars.other_costs * (1.0 -  (model.current.shadeacc / 365.0) * mean(model.shade_map)) + 0.012)
    model.current.shadeacc = 0.0
    
    # if sum(active, model.agents)/length(model.agents) < 0.1
    #     model.current.inbusiness = false
    # #elseif (years = div(model.current.days, model.mngpars.harvest_day)) > 1
    # #    tot_in = model.current.prod * model.mngpars.coffee_price
    # #    if (cost - tot_in) > (0.5 * tot_in * inv(years))
    # #        model.current.inbusiness = false
    # #    end
    # end

    # if (years = div(model.current.days, model.mngpars.harvest_day)) > 1
    #     tot_in = model.current.prod * model.mngpars.coffee_price
    #     if (sum(active.(model.agents))/length(model.agents) < 0.1) || (model.current.costs - tot_in) > (0.5 * tot_in * inv(years)) # if deficit is more than half the av revenue
    #         model.current.inbusiness = false
    #     end
    # end

    model.current.fung_count = 0
    # new_harvest_cycle!.(model.agents, model.mngpars.lesion_survive)
    map(a -> new_harvest_cycle!(a, model.mngpars.lesion_survive), model.agents)
    return nothing
end

function new_harvest_cycle!(c::Coffee, surv_p::Float64)
    c.production = 0.0
    c.deposited *= surv_p
    surv_n = trunc(Int, c.n_lesions * surv_p)
    if surv_n == 0
        c.n_lesions = 0
        empty!(c.ages)
        empty!(c.areas)
        empty!(c.spores)
        if c.deposited < 0.05
            c.deposited = 0.0
            c.rusted = false
        end
    else
        lost = c.n_lesions - surv_n
        c.n_lesions = surv_n
        deleteat!(c.ages, 1:lost)
        deleteat!(c.areas, 1:lost)
        deleteat!(c.spores, 1:lost)
    end
    return nothing
end
# 
# ifzerothentwo(a::Float64) = a == 0.0 ? 2.0 : a

# function prune_shades!(model::SpatialRustABM, prune_i::Int)
#     prune_to = model.mngpars.post_prune[prune_i]
#     if model.current.ind_shade > prune_to
#         model.current.ind_shade = prune_to
#     else
#         model.current.ind_shade *= 0.9
#     end
#     model.current.costs += model.mngpars.tot_prune_cost
# end

function prune_shades!(model::SpatialRustABM, tshade::Float64)
    if model.current.ind_shade > tshade
        model.current.ind_shade = tshade
    else
        model.current.ind_shade *= 0.9
    end
    model.current.costs += model.mngpars.tot_prune_cost
end

# function prune_shades!(model::SpatialRustABM)
#     if model.current.ind_shade > model.mngpars.post_prune
#         model.current.ind_shade = model.mngpars.post_prune
#     else
#         model.current.ind_shade *= 0.9
#     end
#     model.current.costs += model.mngpars.tot_prune_cost
# end


# function prune!(model::SpatialRustABM)
#     # n_pruned = trunc(model.pars.prune_effort * length(model.current.shade_ids))
#     # model.current.costs += n_pruned * model.pars.prune_cost
#     model.current.costs += length(model.current.shade_ids) * model.pars.prune_cost
#     # pruned = partialsort(model.current.shade_ids, 1:n_pruned, rev=true, by = x -> model[x].shade)
#     # for pr in pruned
#     for pr in model.current.shade_ids
#         model[pr].shade = model.pars.post_prune
#     end
# end

function inspect!(model::SpatialRustABM)
    n_infected = 0
    actv = filter(active, model.agents)
    if model.mngpars.n_inspected < length(actv)
        inspected = sample(model.rng, actv, model.mngpars.n_inspected, replace = false)
    else
        inspected = actv
    end

    rmles = model.mngpars.rm_lesions
    for c in inspected
        # lesion area of 0.05 means a diameter of ~0.25 cm, which is taken as minimum so grower can see it
        nvis = sum(>(0.05), c.areas, init = 0.0)
        # area of 0.8 means a diameter of ~1 cm
        if nvis > 0  && (0.8 < maximum(c.areas, init = 0.0) || rand(model.rng) < nvis / 5)
        # if nvis > 0 && rand(model.rng) < sum(visibleup, c.areas) / 25
        # if (1.0 < maximum(c.areas, init = 0.0) || rand(model.rng) < maximum(c.areas, init = 0.0))
            n_infected += 1
            spotted = unique!(sort!(sample(model.rng, 1:c.n_lesions, weights(visible.(c.areas)), rmles)))
            deleteat!(c.ages, spotted)
            deleteat!(c.areas, spotted)
            deleteat!(c.spores, spotted)
            c.n_lesions -= length(spotted)
            if c.n_lesions == 0 && (c.deposited < 0.05)
                c.deposited == 0.0
                c.rusted = false
            end
        end
    end

    model.current.costs += model.mngpars.tot_inspect_cost
    model.current.obs_incidence = n_infected / model.mngpars.n_inspected
end

visible(a::Float64) = a > 0.05 ? a : 0.0

function fungicide!(model::SpatialRustABM)
    model.current.costs += model.mngpars.tot_fung_cost
    model.current.fungicide = 1 # model.mngpars.fung_effect
    model.current.fung_count += 1
end