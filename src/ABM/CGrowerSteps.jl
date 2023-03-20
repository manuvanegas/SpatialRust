function harvest!(model::SpatialRustABM)
    model.current.prod += sum(getproperty.(model.agents, :production))

    # if (years = div(model.current.days, model.mngpars.harvest_day)) > 1
    #     tot_in = model.current.prod * model.mngpars.coffee_price
    #     if (sum(active.(model.agents))/length(model.agents) < 0.1) || (model.current.costs - tot_in) > (0.5 * tot_in * inv(years)) # if deficit is more than half the av revenue
    #         model.current.inbusiness = false
    #     end
    # end

    model.current.fung_count = 0
    new_harvest_cycle!.(model.agents, model.mngpars.lesion_survive, model.rustpars.max_lesions, model.rustpars.reset_age)
end

function new_harvest_cycle!(c::Coffee, surv_p::Float64, max_nl::Int, reset_age::Int)
    c.production = 0.0
    c.deposited *= surv_p
    surv_n = c.n_lesions = trunc(Int, c.n_lesions * surv_p)
    if surv_n == 0
        fill!(c.ages, reset_age)
        fill!(c.areas, 0.0)
        fill!(c.spores, false)
        # if c.deposited < 0.1 
        #     c.deposited = 0.0
        #     delete!(rust.rusts, c)
        # end
    else
        fill_n = max_nl - surv_n
        surv_sites = sortperm(ifzerothentwo.(c.areas))[1:surv_n]
        c.ages = append!(c.ages[surv_sites], fill(reset_age, fill_n))
        c.areas = append!(c.areas[surv_sites], zeros(fill_n))
        c.spores = append!(c.spores[surv_sites], fill(false, fill_n))
    end
end

ifzerothentwo(a::Float64) = a == 0.0 ? 2.0 : a

# function prune_shades!(model::SpatialRustABM, prune_i::Int)
#     prune_to = model.mngpars.target_shade[prune_i]
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
#     if model.current.ind_shade > model.mngpars.target_shade
#         model.current.ind_shade = model.mngpars.target_shade
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
#         model[pr].shade = model.pars.target_shade
#     end
# end

function inspect!(model::SpatialRustABM)
    # exhausted coffees can be inspected in this version. They have a 100% chance of being regarded as infected.
    inspected = sample(model.rng, model.agents, model.mngpars.n_inspected, replace = false)
    n_infected = 0

    for c in inspected
        if c.exh_countdown > 0
            n_infected += 1
        # lesion area of 0.1 means a diameter of 0.36 cm, which is taken as a threshold for grower to spot it
        elseif any(c.areas .> 0.1) && (rand(model.rng) < maximum(c.areas))
            n_infected += 1
            spotted = unique!(sample(model.rng, 1:c.n_lesions, weights(visible.(c.areas[1:c.n_lesions])), 5))
            fill_n = length(spotted)
            c.n_lesions -= fill_n
            c.ages = append!(c.ages[Not(spotted)], fill(model.rustpars.reset_age, fill_n))
            c.areas = append!(c.areas[Not(spotted)], zeros(fill_n))
            c.spores = append!(c.spores[Not(spotted)], fill(false, fill_n))
            if c.n_lesions == 0 && (c.deposited < 0.1 )
                c.deposited == 0.0
                delete!(model.rusts, c)
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

    model.current.costs += model.mngpars.tot_inspect_cost
    model.current.obs_incidence = n_infected / model.mngpars.n_inspected
end

# exhausted(c::Coffee)::Bool = c.exh_countdown > 0

visible(a::Float64) = a > 0.1 ? a : 0.0

function fungicide!(model::SpatialRustABM)
    model.current.costs += model.mngpars.tot_fung_cost
    model.current.fungicide = model.mngpars.fung_effect
    model.current.fung_count += 1
end