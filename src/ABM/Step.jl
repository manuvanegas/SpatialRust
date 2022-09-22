export step_model!

function step_model!(model::ABM)
    pre_step!(model)
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
        model.current.wind_h = rand(model.rng) * 360.0
        outside_spores!(model)
    end
    model.current.temperature = model.weather.temp_data[model.current.ticks]

    # spore outpour decay, then outpour can return spores to the farm
    # model.current.outpour = model.current.outpour * 0.9
    # if rand(model.rng) < sqrt(model.current.outpour)/(model.pars.map_side^2)
    #     outside_spores!(model)
    # end

    # update sampling cycle (for ABC)
    # if (model.current.ticks - 1) in model.pars.switch_cycles
    #     # popfirst!(model.pars.switch_cycles)
    #     if model.current.cycle[1] == 5 && !isassigned(model.current.cycle, 2)
    #         push!(model.current.cycle, 6)
    #     else
    #         model.current.cycle .+= 1
    #     end
    # end

    areas = median(rusted_area.(model.current.rusts))
    if areas > model.current.max_rust
        model.current.max_rust = areas
    end
end

function shade_step!(model::ABM)
    grow_shades!(model)
end

function coffee_step!(model::ABM)
    let prod_cycle_d = model.current.days % model.pars.harvest_day,
    pars = model.pars.coffee_pars,
    map = model.shade_map,
    ind_shade = model.current.ind_shade

        if pars.veg_d <= prod_cycle_d < pars.rep_d
            for cof in model.current.coffees
                vegetative_step!(cof, pars, map, ind_shade)
            end
        # elseif pars.rep_d < pars.veg_d <= prod_cycle_d
        #     for cof in model.current.coffees
        #         vegetative_step!(model, cof)
        #     end
        elseif prod_cycle_d == pars.rep_d
            for cof in model.current.coffees
                vegetative_step!(cof, pars, map, ind_shade)
                repr_commitment(cof, pars, prod_cycle_d)
            end
        else
            for cof in model.current.coffees
                reproductive_step!(cof, pars, map, ind_shade)
            end
        end
    end

    # for cof in model.current.coffees
    #     coffee_ind_step!(model, cof)
    # end
end

function rust_step!(model::ABM)
    # fung = ifelse(model.current.fung_effect > 0, (growth = 0.95, spor = 0.8, germ = 0.9),
    #     (growth = 1.0, spor = 1.0, germ = 1.0))


    for rust in shuffle(model.rng, model.current.rusts)
        host = model[rust.hg_id]
            let sunlight = host.sunlight
            # sunlight = host.sunlight

                # grow_rust!(model, rust, sunlight, host.production, host.fungicide > 0)
                grow_rust!(model, rust, sunlight, host.production, model.current.fung_effect > 0)
                
                parasitize!(model, rust, host)
                
                if model.current.rain
                    disperse_rain!(model, rust, sunlight)
                end
                if model.current.wind
                    disperse_wind!(model, rust, sunlight)
                end
            end
    end
end

function farmer_step!(model)
    let doy = model.current.days % 365

        if doy in model.pars.harvest_day
            harvest!(model)
        end

        if doy in model.pars.prune_sch
            prune_shades!(model)
        end

        incidence = 0

        if model.current.days % model.pars.inspect_period == 0
            incidence = inspect!(model)
        end

        if model.current.fung_effect > 0
            model.current.fung_effect -= 1
        elseif model.pars.incidence_as_thr
            if incidence > model.pars.incidence_thresh
                fungicide!(model)
            end
        elseif doy in model.pars.fungicide_sch
            fungicide!(model)
        end
    end
end


## Step contents for inds

monomolecular(x) = (1 - exp(-0.3x))

monod(x) = x / (x + 0.7)