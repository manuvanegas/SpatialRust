function harvest!(model::ABM)
    harvest = 0.0
    # ids = model.current.coffees
    # for c in (model[id] for id in ids)
    for c in model.current.coffees
        harvest += c.production * inv(model.pars.harvest_day)
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

function prune_shades!(model::ABM)
    # for shade_i in model.current.shade_ids
    #     @inbounds model[shade_i].shade = model.pars.target_shade
    # end
    # model.current.costs += length(model.current.shade_ids) * model.pars.prune_cost


    model.current.ind_shade = model.pars.target_shade
    model.current.costs = model.current.n_shades * model.pars.prune_cost
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
    n_infected = 0
    max_l = model.pars.max_lesions

    for c in cofs
        # cof = model[c]
        if c.hg_id != 0# && rand < model.pars.inspect_effort * (sum(model[hg_id].state[2,]) / 3)
            #elimina las que sean > 2.5, * effort
            @inbounds rust = model[c.hg_id]
            @inbounds areas = rust.state[2, 1:rust.n_lesions]
            if rand(model.rng) < maximum(areas)
            # if any(areas .> 0.05)
                # replace!(a -> ifelse(a .< 0.05, 0.0, a), areas) # areas < 0.05 have 0 chance of being spotted
                spotted = unique!(sample(model.rng, 1:rust.n_lesions, weights(areas), 5))
                newstate = @inbounds rust.state[:, Not(spotted)]
                rust.n_lesions -= length(spotted)
                rust.state = hcat(newstate, zeros(4, length(spotted)))
                n_infected += 1
            end
            # rust.n_lesions = round(Int, model[cof.hg_id].n_lesions * 0.1)
            # rust.area = round(Int, model[cof.hg_id].area * 0.1)
        end
    end

    return n_infected / n_inspected
end



function fungicide!(model::ABM)
    model.current.costs += length(model.current.coffees) * model.pars.fung_cost
    model.current.fung_effect = 15
end