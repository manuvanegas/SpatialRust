
function vegetative_step!(coffee::Coffee, pars::CoffeePars, map::Matrix{Float64}, ind_shade::Float64)
    if coffee.exh_countdown == 0
        update_sunlight!(coffee, map, ind_shade)
        veg_growth!(coffee, pars)
    elseif coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    else
        update_sunlight!(coffee, map, ind_shade)
        coffee.veg = 1.0
        coffee.storage = init_storage(coffee.sunlight)
        coffee.exh_countdown = 0
        fill!(rust.areas, 0.0)
        farm_map[coffee.pos...] = 1
    end
end

function commit_step!(coffee::Coffee, pars::CoffeePars, map::Matrix{Float64}, ind_shade::Float64)
    if coffee.exh_countdown == 0
        update_sunlight!(coffee, map, ind_shade)
        veg_growth!(coffee, pars)
        coffee.production = max(0.0, pars.res_commit * coffee.sunlight * coffee.veg * coffee.storage)
    elseif coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    else
        update_sunlight!(coffee, map, ind_shade)
        coffee.veg = 1.0
        coffee.storage = init_storage(coffee.sunlight)
        coffee.exh_countdown = 0
        fill!(rust.areas, 0.0)
        farm_map[coffee.pos...] = 1
    end
end

function reproductive_step!(coffee::Coffee, pars::CoffeePars, map::Matrix{Float64}, ind_shade::Float64)
    if coffee.exh_countdown == 0
        update_sunlight!(coffee, map, ind_shade)
        rep_growth!(coffee, pars)
    elseif coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    else
        update_sunlight!(coffee, map, ind_shade)
        coffee.veg = 1.0
        coffee.storage = init_storage(coffee.sunlight)
        coffee.exh_countdown = 0
        fill!(rust.areas, 0.0)
        farm_map[coffee.pos...] = 1
    end
end

function update_sunlight!(cof::Coffee, map::Matrix{Float64}, ind_shade::Float64)
    # shade = 0.0
    # for sh in cof.shade_neighbors
    #     shade += model[sh].shade
    # end
    # shades::Array{Float64} = getproperty.(model[cof.shade_neighbors],:shade)
    # shade = sum(shades)

    # @inbounds cof.sunlight = 1.0 - sum(getproperty.((model[s] for s in cof.shade_neighbors), :shade)) / (((model.pars.shade_r * 2.0) + 1.0)^2.0 - 1.0)
    # cof.sunlight = exp(-(sum(cof.shade_neighbors.shade) / 8))

    # cof.sunlight = 1.0 - cof.shade_neighbors * ind_shade
    cof.sunlight = 1.0 - @inbounds map[cof.pos...] * ind_shade

    # # Shift contents of the deposited vector (older spores are lost) 1 space to the "right"
    # @inbounds rust.deposited[2:end] .= rust.deposited[1:end-1]
    # # unsafe_copyto!(rust.deposited, 2, rust.deposited, 1, 4)
    # @inbounds rust.deposited[1] = 0
    # this would actually be better, if I came back to this:
    # rust.deposited = [0; rust.deposited[1:end-1]]
    # cof.deposited *= 0.65 # Nutman et al, 1963 # Moved to update_deposited
end

function veg_growth!(coffee::Coffee, pars::CoffeePars)
    photo_veg = coffee.veg * pars.photo_frac
    PhS = pars.photo_const * (coffee.sunlight / (pars.k_sl + coffee.sunlight)) *
    (photo_veg / (pars.k_v + photo_veg))
    
    coffee.veg += pars.phs_veg * PhS - pars.μ_veg * coffee.veg
    if coffee.veg < 0.0
        coffee.veg = min(0.0001, pars.exh_threshold)
    end
    coffee.storage += pars.phs_sto * PhS 
end

# function commit_growth!(coffee::Coffee, pars::CoffeePars)
#     photo_veg = coffee.veg * pars.photo_frac
#     PhS = pars.photo_const * (coffee.sunlight / (pars.k_sl + coffee.sunlight)) *
#     (photo_veg / (pars.k_v + photo_veg))
    
#     coffee.veg += pars.phs_veg * PhS - pars.μ_veg * coffee.veg
#     coffee.storage += pars.phs_sto * PhS 
#     coffee.production += pars.res_commit * coffee.sunlight * coffee.veg * coffee.storage
# end

# function repr_commitment!(coffee::Coffee, pars::CoffeePars)
#     coffee.production += pars.res_commit * coffee.sunlight * coffee.veg * coffee.storage
# end

# estimate_resources(coffee::Coffee) = coffee.sunlight * coffee.veg * coffee.storage

function rep_growth!(coffee::Coffee, pars::CoffeePars)
    veg = coffee.veg
    photo_veg = veg * pars.photo_frac
    μ_v = pars.μ_veg * veg
    prod = coffee.production
    
    PhS = pars.photo_const * (coffee.sunlight / (pars.k_sl + coffee.sunlight)) *
    (photo_veg / (pars.k_v + photo_veg))

    if coffee.storage < 0.0
        Δprod = PhS - pars.μ_prod * prod
        if Δprod > 0.0
            last = Δprod - μ_v
            coffee.veg += min(last, 0.0)
            coffee.storage += max(last, 0.0)
        else
            coffee.veg -= μ_v
            coffee.production += Δprod
        end
    else
        frac_v = veg / (veg + prod)
        d_prod = (1.0 - frac_v) * PhS - pars.μ_prod * prod
        if d_prod < 0.0
            coffee.veg += pars.phs_veg * frac_v * PhS - μ_v
            coffee.storage += 0.95 * d_prod
            coffee.production += 0.05 * d_prod
        else
            coffee.veg += pars.phs_veg * (d_prod + frac_v * PhS) - μ_v
            # coffee.veg += d_prod + frac_v * pars.phs_veg * PhS - μ_v
        end
    end

    if coffee.veg < 0.0
        coffee.veg = min(0.0001, pars.exh_threshold)
    end
    if coffee.production < 0.0
        coffee.production = 0.0
    end
end


init_storage(sl::Float64) = 100.0 * exp(-6.2 * sl) + 2.5
# new_veg_storage(neighs::Float64, shade::Float64) = 120.0 - 100.0 * neighs * shade
# new_veg_storage(sunlight::Float64) = 120.0 - 100.0 * sunlight

# new_repr_storage(neighs::Float64, shade::Float64) = 120.0 - 100.0 * neighs * shade
# new_repr_storage(sunlight::Float64) = 120.0 - 100.0 * sunlight

# isinfected(c::Coffee)::Bool = c.infected
# isinfected(c::Coffee)::Bool = c.deposited > 0.0 || c.n_lesions > 0
# notexhausted(c::Coffee)::Bool = c.exh_countdown == 0

# function coffee_ind_step!(coffee::Coffee, pars::CoffeePars, map::Matrix{Float64}, ind_shade::Float64)
#     if coffee.exh_countdown > 1
#         coffee.exh_countdown -= 1
#     elseif coffee.exh_countdown == 1
#         coffee.area = 1.0
#         coffee.exh_countdown = 0
#     else
#         # !isempty(coffee.shade_neighbors) &&
#         update_sunlight!(coffee, map, ind_shade)
#         grow_coffee!(coffee, model.pars.cof_gr)
#         acc_production!(coffee)
#     end
# end

# function grow_coffee!(cof::Coffee, cof_gr)
#     # coffee plants can recover healthy tissue (dilution effect for sunlit plants)

#     if 0.0 < cof.area < 1.0
#         cof.area += *(cof_gr, cof.area, cof.sunlight)
#     elseif cof.area > 1.0
#         cof.area = 1.0
#     end

#     cof.age += 1
# end

# function acc_production!(cof::Coffee) # accumulate production
#     cof.production += cof.area * cof.sunlight
# end