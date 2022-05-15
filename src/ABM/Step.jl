export step_model!

function step_model!(model::ABM)
    # if model.current.ticks == 0
    #     sh = model[pop!(model.current.shade_ids)]
    #     delete!(model.agents, sh.id)
    #     deleteat!(model.space.s[sh.pos...], 1)
    # end
    pre_step!(model)

    # for shade_i in model.current.shade_ids
    #     shade_step!(model, model[shade_i])
    # end
    #
    # for cof_i in model.current.coffee_ids
    #     coffee_step!(model, model[cof_i])
    # end

    # for rust_i in shuffle(model.rng, model.current.rust_ids)
    #     rust_step!(model, model[rust_i], model[model[rust_i].hg_id])
    # end
    shade_step!(model)
    coffee_step!(model)
    rust_step!(model)
    farmer_step!(model)
end

## "Step" functions

function pre_step!(model)
    # update day counters
    model.current.days += 1
    model.current.ticks += 1

    # update weather conditions from Weather data
    model.current.rain = model.weather.rain_data[model.current.ticks]
    model.current.wind = model.weather.wind_data[model.current.ticks]
    if model.current.wind
        model.current.wind_h = rand(model.rng) * 360
    end
    model.current.temperature = model.weather.temp_data[model.current.ticks]

    # spore outpour decay, then outpour can return spores to the farm
    model.current.outpour = model.current.outpour * 0.9
    if rand(model.rng) < sqrt(model.current.outpour)/(model.pars.map_side^2)
        outside_spores!(model)
    end

    # update sampling cycle (for ABC)
    # if (model.current.ticks - 1) in model.pars.switch_cycles
    #     # popfirst!(model.pars.switch_cycles)
    #     if model.current.cycle[1] == 5 && !isassigned(model.current.cycle, 2)
    #         push!(model.current.cycle, 6)
    #     else
    #         model.current.cycle .+= 1
    #     end
    # end

    if model.current.fung_effect > 0
        model.current.fung_effect -= 1
    end

    areas = median(rusted_area.((model[id] for id in model.current.rust_ids)))
    if areas > model.current.max_rust
        model.current.max_rust = areas
    end
end

function shade_step!(model::ABM)
    if model.current.days % model.pars.prune_period == 0
        prune_shades!(model)
    else
        grow_shades!(model)
    end
end

function coffee_step!(model::ABM)
    # if model.current.days % model.pars.harvest_cycle == 0
    #     for cof_i in model.current.coffee_ids
    #         coffee_harvest_step!(model, model[cof_i])
    #     end
    # else
        cids = model.current.coffee_ids
        for cof_i in cids
            @inbounds coffee_nh_step!(model, model[cof_i])
        end
    # end
end

function rust_step!(model::ABM)
    rids = shuffle(model.rng, model.current.rust_ids)
    # fung_growth = model.current.fung_effect > 0 ? 0.98 : 1.0
    # fung_germ = model.current.fung_effect > 0 ? : 1.0
    fung = ifelse(model.current.fung_effect > 0, (growth = 0.95, spor = 0.8, germ = 0.9),
        (growth = 1.0, spor = 1.0, germ = 1.0))

    if model.current.wind
        if model.current.rain
            for rust_i in rids
                @inbounds rust_step_r_w!(model, model[rust_i], model[model[rust_i].hg_id], fung)
            end
        else
            for rust_i in rids
                @inbounds rust_step_w!(model, model[rust_i], model[model[rust_i].hg_id], fung)
            end
        end
    elseif model.current.rain
        for rust_i in rids
            @inbounds rust_step_r!(model, model[rust_i], model[model[rust_i].hg_id], fung)
        end
    else
        for rust_i in rids
            @inbounds rust_step_!(model, model[rust_i], model[model[rust_i].hg_id], fung)
            #could just be grow_rust! ?
        end
    end
end

function farmer_step!(model)
    if model.current.days % model.pars.harvest_cycle == 0
        harvest!(model)
    end

    if (model.current.days - fld(model.pars.harvest_cycle, 2)) % model.pars.fungicide_period == 0
        fungicide!(model)
    end

    # if model.current.days % model.pars.inspect_period == 0
    #     inspect!(model)
    # end
end


## Step contents for inds

function coffee_harvest_step!(model::ABM, coffee::Coffee)
    if coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    elseif coffee.exh_countdown == 1
        coffee.area = 1.0
        coffee.exh_countdown = 0
    else
        !isempty(coffee.shade_neighbors) && update_sunlight!(model, coffee)
        grow_coffee!(coffee, model.pars.cof_gr)
        acc_production!(coffee)
    end
    model.current.prod += coffee.production / model.pars.harvest_cycle
    coffee.production = 1.0
end

function coffee_nh_step!(model::ABM, coffee::Coffee)
    if coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    elseif coffee.exh_countdown == 1
        coffee.area = 1.0
        coffee.exh_countdown = 0
    else
        !isempty(coffee.shade_neighbors) && update_sunlight!(model, coffee)
        grow_coffee!(coffee, model.pars.cof_gr)
        acc_production!(coffee)
    end
end


function rust_step_r_w!(model::ABM, rust::Rust, host::Coffee, fung::NamedTuple)

    # host = model[rust.hg_id]

    if host.exh_countdown == 0 # not exhausted
        sunlight = host.sunlight
        # if any(rust.spores .> 0.0)
        #     disperse!(rust, host, model)
        # end
        # parasitize!(rust, host, model)
        grow_rust!(model, rust, sunlight, host.production, fung)
        disperse_rain!(model, rust, sunlight)
        disperse_wind!(model, rust, sunlight)
        parasitize!(model, rust, host)
    end
end

function rust_step_r!(model::ABM, rust::Rust, host::Coffee, fung::NamedTuple)
    if host.exh_countdown == 0 # not exhausted
        sunlight = host.sunlight
        grow_rust!(model, rust, sunlight, host.production, fung)
        disperse_rain!(model, rust, sunlight)
        parasitize!(model, rust, host)
    end
end

function rust_step_w!(model::ABM, rust::Rust, host::Coffee, fung::NamedTuple)
    if host.exh_countdown == 0 # not exhausted
        sunlight = host.sunlight
        grow_rust!(model, rust, sunlight, host.production, fung)
        disperse_wind!(model, rust, sunlight)
        parasitize!(model, rust, host)
    end
end

function rust_step_!(model::ABM, rust::Rust, host::Coffee, fung::NamedTuple)
    if host.exh_countdown == 0 # not exhausted
        sunlight = host.sunlight
        grow_rust!(model, rust, sunlight, host.production, fung)
        parasitize!(model, rust, host)
    end
end

###
## Coffee
###

function update_sunlight!(model::ABM, cof::Coffee)
    # shade = 0.0
    # for sh in cof.shade_neighbors
    #     shade += model[sh].shade
    # end
    # shades::Array{Float64} = getproperty.(model[cof.shade_neighbors],:shade)
    # shade = sum(shades)

    @inbounds cof.sunlight = 1.0 - sum(getproperty.((model[s] for s in cof.shade_neighbors), :shade)) / (((model.pars.shade_r * 2.0) + 1.0)^2.0 - 1.0)
    # cof.sunlight = exp(-(sum(cof.shade_neighbors.shade) / 8))
end

function grow_coffee!(cof::Coffee, cof_gr)
    # coffee plants can recover healthy tissue (dilution effect for sunlit plants)

"This growth function has to change"
    if 0.0 < cof.area < 1.0
        cof.area += cof_gr * (cof.area * cof.sunlight)
    elseif cof.area > 1.0
        cof.area = 1.0
    end

    cof.age += 1
end

function acc_production!(cof::Coffee) # accumulate production
    cof.production += cof.area * cof.sunlight
end

###
## Rust
###

function grow_rust!(model::ABM, rust::Rust, sunlight::Float64, production::Float64, fung::NamedTuple)
    # let (local_temp, growth_modif) = growth_conditions(model, sunlight, production)
    let local_temp = model.current.temperature - (model.pars.temp_cooling * (1.0 - sunlight)),
        growth_modif = (1 + model.pars.fruit_load * production / model.pars.harvest_cycle) *
            (-0.0178 * ((local_temp - model.pars.opt_g_temp) ^ 2.0) + 1.0) * model.pars.rust_gr *
            fung.growth

        # growth_conds(model.pars.fruit_load, production, model.pars.harvest_cycle,
        #     model.pars.opt_g_temp, model.pars.rust_gr, local_temp, model.current.fung_effect)

        @views for lesion in 1:rust.n_lesions
            # rust.n_lesions += grow_each_rust!(rust.state[:, lesion], local_temp, sunlight, production)

            if @inbounds rust.state[1, lesion] == 1.0
                if @inbounds rust.state[3, lesion] == 0.0
                    @inbounds area_growth!(rust.state[:, lesion],local_temp, growth_modif,
                        sporul_conds(rand(model.rng), rust.state[2, lesion], local_temp, fung.spor)
                    )
                else
                    @inbounds area_growth!(rust.state[:, lesion], local_temp, growth_modif, false)
                end
            elseif rand(model.rng) < (sunlight * max(model.pars.uv_inact,
                        (model.current.rain ? model.pars.rain_washoff : 0.0)) )
                        # higher % sunlight means more chances of inactivation by UV or rain
                        if rust.n_lesions > 1
                            rust.n_lesions -= 1
                        else
                            kill_rust!(model, rust)
                        end
            elseif rand(model.rng) < infection_p(local_temp - (model.current.rain ? 6.0 : 0.0), fung.germ)
                @inbounds germinate!(rust.state[:, lesion])
            end
        end
    end

        # for les in 1:rust.n_lesions
        #     if rust.germinated[les]
        #         if rust.age[les] < model.pars.steps
        #             rust.age[les] += 1
        #         end
        #         if 14 < local_temp < 30 # grow and sporulate
        #
        #             #  logistic growth (K=1) * rate due to fruit load * rate due to temperature
        #             rust.area[les] += rust.area[les] * (1 - rust.area[les]) *
        #                 #(model.fruit_load * (1 / (1 + (30 / cof.production))^2)) *
        #                 model.pars.fruit_load * production / model.pars.harvest_cycle *
        #                 (-0.0178 * ((local_temp - model.pars.opt_g_temp) ^ 2.0) + 1.0)
        #
        #             if !rust.spores[les] &&
        #                 rand(model.rng) < (rust.area[les] * (local_temp + 5.0) / 30.0) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
        #                 rust.spores[les] = true
        #             end
        #         end
        #
        #     else # try to germinate + penetrate tissue
        #         let r = rand(model.rng)
        #             if r < (sunlight * model.pars.uv_inact) ||
        #                 r <  (sunlight * (model.current.rain ? model.pars.rain_washoff : 0.0))
        #                 # higher % sunlight means more chances of inactivation by UV or rain
        #                 if rust.n_lesions > 1
        #                     rust.n_lesions -= 1
        #                 else
        #                     kill_rust!(model, rust)
        #                 end
        #             elseif r < calc_wetness_p(local_temp - (model.current.rain ? 6.0 : 0.0))
        #                 # if rand(model.rng) < calc_wetness_p(local_temp - (model.current.rain ? 6.0 : 0.0))
        #                 rust.germinated[les] = true
        #                 rust.area[les] = 0.01
        #                 rust.age[les] = 0
        #             end
        #         end
        #     end
        # end

end

function parasitize!(model::ABM, rust::Rust, cof::Coffee)

    # if any(rust.germinated)
        # bal = rust.area + (rust.n_lesions / 25.0) # between 0.0 and 2.0
    # # cof.progression = 1 / (1 + (0.75 / bal)^4)
    #     prog = 1 / (1 + (0.25 / bal)^4) # Hill function with steep increase
    #     cof.area = 1.0 - prog
        cof.area = 1.0 - (sum(rust.state[2, :]) / model.pars.max_lesions)
        #if rust.area * rust.n_lesions >= model.pars.exhaustion #|| bal >= 2.0
        if (sum(rust.state[2, :]) / model.pars.max_lesions) >= model.pars.exhaustion
            cof.area = 0.0
            cof.exh_countdown = (model.pars.harvest_cycle * 2) + 1
            kill_rust!(model, rust)
        end
    # end
end

## Helper
# function growth_conditions(model::ABM, sunlight::Float64, production::Float64)
#     #arg could be models' parameters (not pars)
#     local_temp = model.current.temperature - (model.pars.temp_cooling * (1.0 - sunlight))
#
#     growth_modif = (1 + model.pars.fruit_load * production / model.pars.harvest_cycle) *
#         (-0.0178 * ((local_temp - model.pars.opt_g_temp) ^ 2.0) + 1.0) * model.pars.rust_gr #*
#         #something about fungicide
#
#
#
#     return local_temp, growth_modif
# end
function growth_conds(fruit_load::Float64, production::Float64, harvest_cycle::Int,
    opt_g_temp::Float64, rust_gr::Float64, local_temp::Float64, fungicide::Int)::Float64
    fung = fungicide > 0 ? 0.98 : 1.0
    return fung * (1 + fruit_load * production / harvest_cycle) *
        (-0.0178 * ((local_temp - opt_g_temp) ^ 2.0) + 1.0) * rust_gr
end
