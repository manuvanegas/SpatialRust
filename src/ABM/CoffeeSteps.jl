function coffee_ind_step!(model::ABM, coffee::Coffee)
    if coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    elseif coffee.exh_countdown == 1
        coffee.area = 1.0
        coffee.exh_countdown = 0
    else
        # !isempty(coffee.shade_neighbors) &&
        update_sunlight!(coffee, model.current.ind_shade)
        grow_coffee!(coffee, model.pars.cof_gr)
        acc_production!(coffee)
    end
end


function update_sunlight!(cof::Coffee, ind_shade)
    # shade = 0.0
    # for sh in cof.shade_neighbors
    #     shade += model[sh].shade
    # end
    # shades::Array{Float64} = getproperty.(model[cof.shade_neighbors],:shade)
    # shade = sum(shades)

    # @inbounds cof.sunlight = 1.0 - sum(getproperty.((model[s] for s in cof.shade_neighbors), :shade)) / (((model.pars.shade_r * 2.0) + 1.0)^2.0 - 1.0)
    # cof.sunlight = exp(-(sum(cof.shade_neighbors.shade) / 8))

    cof.sunlight = 1.0 - cof.shade_neighbors * ind_shade
end

function grow_coffee!(cof::Coffee, cof_gr)
    # coffee plants can recover healthy tissue (dilution effect for sunlit plants)

# TODO: This growth function
    if 0.0 < cof.area < 1.0
        cof.area += *(cof_gr, cof.area, cof.sunlight)
    elseif cof.area > 1.0
        cof.area = 1.0
    end

    cof.age += 1
end

function acc_production!(cof::Coffee) # accumulate production
    cof.production += cof.area * cof.sunlight
end
