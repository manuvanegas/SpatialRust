function harvest!(model::ABM)
    harvest = 0.0
    # ids = model.current.coffees
    # for c in (model[id] for id in ids)
    for c in model.current.coffees
        harvest += c.production / model.pars.harvest_cycle
        c.production = 0.0
        # if plant.fung_this_cycle
        #     plant.fung_this_cycle = false
        #     plant.productivity = plant.productivity / 0.8
        # end
        # if plant.pruned_this_cycle
        #     plant.pruned_this_cycle = false
        #     plant.productivity = plant.productivity / 0.9
        # end
    end
    # model.current.net_rev += (model.pars.coffee_price * harvest) - model.current.costs
    # model.current.gains += model.coffee_price * harvest * model.pars.p_density
    model.current.prod += harvest
end

function fungicide!(model::ABM)
    model.current.costs += length(model.current.coffees) * 1.0 #model.pars.fung_cost
    model.current.fung_effect = 15
end

# function prune!(model::ABM)
#     # n_pruned = trunc(model.pars.prune_effort * length(model.current.shade_ids))
#     # model.current.costs += n_pruned * model.pars.prune_cost
#     model.current.costs += length(model.current.shade_ids) * model.pars.prune_cost
#     # pruned = partialsort(model.current.shade_ids, 1:n_pruned, rev=true, by = x -> model[x].shade)
#     # for pr in pruned
#     for pr in model.current.shade_ids
#         model[pr].shade = model.pars.target_shade
#     end
# end

function inspect!(model::ABM)
    n_inspected = round(Int,(model.pars.inspect_effort * length(model.current.coffees)), RoundToZero)
    # n_inspected = model.pars.n_inspected
    cofs = sample(model.rng, model.current.coffees, n_inspected, replace = false)

    for c in cofs
        # cof = model[c]
        if c.hg_id != 0# && rand < model.pars.inspect_effort * (sum(model[hg_id].state[2,]) / 3)
            #elimina las que sean > 2.5, * effort
            rust = model[c.hg_id]
            @inbounds areas = rust.state[2, 1:rust.n_lesions]
            if any(areas .> 0.05)
                replace!(a -> a .< 0.05 ? 0.0 : a, areas)
                spotted = sample(model.rng, 1:rust.n_lesions, weights(areas), 5)
                newstate = rust.state[:, Not(spotted)]
                rust.n_lesions = size(newstate)[2]
                rust.state = hcat(newstate, ones(4, 25 - rust.n_lesions))
            end
            # rust.n_lesions = round(Int, model[cof.hg_id].n_lesions * 0.1)
            # rust.area = round(Int, model[cof.hg_id].area * 0.1)
        end
    end
end
