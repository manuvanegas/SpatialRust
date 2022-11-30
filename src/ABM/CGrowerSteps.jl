function harvest!(model::ABM)
    # model.current.net_rev += (model.pars.coffee_price * harvest) - model.current.costs
    # model.current.gains += model.coffee_price * harvest * model.pars.p_density
    # model.current.prod += harvest
    model.current.prod += sum(getproperty.(allagents(model), :production))
    model.current.fung_count = 0
    new_harvest_cycle!.(allagents(model), model.mngpars.lesion_survive, model.rustpars.max_lesions)
    # possible error, use Ref()
end

function new_harvest_cycle!(c::Coffee, surv_p::Float64, max_nl::Int)
    c.production = 0.0
    c.deposited *= surv_p
    surv_n = c.n_lesions = trunc(Int, c.n_lesions * surv_p)
    if surv_n == 0
        c.ages = zeros(Int, max_nl)
        c.areas = zeros(max_nl)
        c.spores = fill(false, max_nl)
        if c.deposited < 0.1 
            c.deposited == 0.0
            setdiff!(rust.current.rusts, c)
        end
    else
        fill_n = max_nl - surv_n
        surv_sites = sortperm(ifzerothentwo.(c.areas))[1:surv_n]
        c.ages = append!(c.ages[surv_sites], zeros(Int, fill_n))
        c.areas = append!(c.areas[surv_sites], zeros(fill_n))
        c.spores = append!(c.spores[surv_sites], fill(false, fill_n))
    end
end

ifzerothentwo(a::Float64) = a == 0.0 ? 2.0 : a

function prune_shades!(model::ABM)
    # for shade_i in model.current.shade_ids
    #     @inbounds model[shade_i].shade = model.pars.target_shade
    # end
    # model.current.costs += length(model.current.shade_ids) * model.pars.prune_cost


    model.current.ind_shade = model.mngpars.target_shade
    model.current.costs += model.mngpars.tot_prune_cost
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
    n_inspected = trunc(Int,(model.mngpars.inspect_effort * count(model.farm_map .== 1)))
    # only non-exhausted coffees can be counted, so the constant n_cofs cannot be used here
    inspectable = filter!(notexhausted, collect(allagents(model)))
    if n_inspected < length(inspectable)
        inspected = sample(model.rng, inspectable, n_inspected, replace = false)
    else
        inspected = inspectable
    end
    n_infected = 0

    for c in inspected
        # lesion area of 0.1 means a diameter of 0.36 cm, which is taken as a threshold for grower to spot it
        if any(c.areas > 0.1) && rand(model.rng) < maximum(c.areas) 
            n_infected += 1
            spotted = unique!(sample(model.rng, 1:c.n_lesions, weights(visible.(c.areas)), 5))
            fill_n = length(spotted)
            c.n_lesions -= fill_n
            c.ages = append!(c.ages[Not(spotted)], zeros(Int, fill_n))
            c.areas = append!(c.areas[Not(spotted)], zeros(fill_n))
            c.spores = append!(c.spores[Not(spotted)], fill(false, fill_n))
            if c.n_lesions == 0 && c.deposited < 0.1 
                c.deposited == 0.0
                setdiff!(rust.current.rusts, c)
            end
        end
 
        # cof = model[c]
        # if c.hg_id != 0# && rand < model.pars.inspect_effort * (sum(model[hg_id].state[2,]) / 3)
        #     #elimina las que sean > 2.5, * effort
        #     @inbounds rust = model[c.hg_id]
        #     @inbounds areas = rust.state[2, 1:rust.n_lesions]
        #     if rand(model.rng) < maximum(areas)
        #     # if any(areas .> 0.05)
        #         # replace!(a -> ifelse(a .< 0.05, 0.0, a), areas) # areas < 0.05 have 0 chance of being spotted
        #         spotted = unique!(sample(model.rng, 1:rust.n_lesions, weights(areas), 5))
        #         newstate = @inbounds rust.state[:, Not(spotted)]
        #         rust.n_lesions -= length(spotted)
        #         rust.state = hcat(newstate, zeros(4, length(spotted)))
        #         n_infected += 1
        #     end
        #     # rust.n_lesions = round(Int, model[cof.hg_id].n_lesions * 0.1)
        #     # rust.area = round(Int, model[cof.hg_id].area * 0.1)
        # end
    end

    model.current.costs += n_inspected * inspect_cost

    return n_infected / length(inspected)
end

visible(a::Float64) = a > 0.1 ? a : 0.0

function fungicide!(model::ABM)
    model.current.costs += model.mngpars.tot_fung_cost
    model.current.fung_effect = model.mngpars.fung_effect
    model.current.fung_count += 1
end