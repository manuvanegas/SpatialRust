
# function vegetative_step!(coffee::Coffee, pars::CoffeePars, shade_map::Matrix{Float64},
#     # ind_shade::Float64, farm_map::Matrix{Int})
#     ind_shade::Float64)
#     # if coffee.exh_countdown == 0
#         sl = update_sunlight!(coffee, shade_map, ind_shade)
#         veg_growth!(coffee, pars, sl)
#     # elseif coffee.exh_countdown > 1
#     #     coffee.exh_countdown -= 1
#     # else
#     #     update_sunlight!(coffee, shade_map, ind_shade)
#     #     coffee.veg = 1.0
#     #     coffee.storage = init_storage(coffee.sunlight)
#     #     coffee.exh_countdown = 0
#     #     farm_map[coffee.pos...] = 1
#     # end
# end

# function commit_step!(coffee::Coffee, pars::CoffeePars, shade_map::Matrix{Float64},
#      ind_shade::Float64, farm_map::Matrix{Int}, commit::Normal, rng::Xoshiro)
#     if coffee.exh_countdown == 0
#         sl = update_sunlight!(coffee, shade_map, ind_shade)
#         veg_growth!(coffee, pars, sl)
#         coffee.production = max(0.0, rand(rng, commit) * sl * coffee.veg * coffee.storage)
#     elseif coffee.exh_countdown > 1
#         coffee.exh_countdown -= 1
#     else
#         update_sunlight!(coffee, shade_map, ind_shade)
#         coffee.veg = 1.0
#         coffee.storage = init_storage(coffee.sunlight)
#         coffee.exh_countdown = 0
#         farm_map[coffee.pos...] = 1
#     end
# end

# function reproductive_step!(coffee::Coffee, pars::CoffeePars, shade_map::Matrix{Float64},
#     # ind_shade::Float64, farm_map::Matrix{Int})
#     ind_shade::Float64)
#     # if coffee.exh_countdown == 0
#         sl = update_sunlight!(coffee, shade_map, ind_shade)
#         rep_growth!(coffee, pars, sl)
#     # elseif coffee.exh_countdown > 1
#     #     coffee.exh_countdown -= 1
#     # else
#     #     update_sunlight!(coffee, shade_map, ind_shade)
#     #     coffee.veg = 1.0
#     #     coffee.storage = init_storage(coffee.sunlight)
#     #     coffee.exh_countdown = 0
#     #     farm_map[coffee.pos...] = 1
#     # end
# end

function update_sunlight!(cof::Coffee, map::Matrix{Float64}, ind_shade::Float64)
    cof.sunlight = 1.0 - @inbounds map[cof.pos...] * ind_shade
end

function veg_growth!(coffee::Coffee, pars::CoffeePars, sl::Float64)
    photo_veg = coffee.veg * pars.photo_frac
    PhS = pars.photo_const * (sl / (pars.k_sl + sl)) * (photo_veg / (pars.k_v + photo_veg))
    
    coffee.veg += pars.phs_veg * PhS - pars.μ_veg * coffee.veg
    if coffee.veg < 0.0
        coffee.veg = 0.0
    end
    coffee.storage += pars.phs_sto * PhS 
end

function rep_growth!(coffee::Coffee, pars::CoffeePars, sl::Float64)
    veg = coffee.veg
    photo_veg = veg * pars.photo_frac
    μ_v = pars.μ_veg * veg
    prod = coffee.production
    
    PhS = pars.photo_const * (sl / (pars.k_sl + sl)) *
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
        coffee.veg = 0.0
    end
    if coffee.production < 0.0
        coffee.production = 0.0
    end
end

function regrow!(cof::Coffee, sl::Float64, map::Matrix{Int})
    cof.veg = 2.0
    cof.storage = init_storage(sl)
    cof.exh_countdown = 0
    @inbounds map[cof.pos...] = 1
end


init_storage(sl::Float64) = 75.5 * exp(-5.5 * sl) + 2.2
# init_veg(sl::Float64) = 0.84 * sl + 1.14
