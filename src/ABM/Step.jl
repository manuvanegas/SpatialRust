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

    if model.current.fung_effect > 0
        model.current.fung_effect -= 1
    end

    areas = median(rusted_area.(model.current.rusts))
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
    for cof in model.current.coffees
        coffee_step!(model, cof)
    end
end

function rust_step!(model::ABM)
    fung = ifelse(model.current.fung_effect > 0, (growth = 0.95, spor = 0.8, germ = 0.9),
        (growth = 1.0, spor = 1.0, germ = 1.0))

    if model.current.wind
        if model.current.rain
            # for rust_i in rids
            #     @inbounds rust_step_r_w!(model, model[rust_i], model[model[rust_i].hg_id], fung)
            # end
            for rust in shuffle(model.rng, model.current.rusts)
                rust_step_r_w!(model, rust, model[rust.hg_id], fung)
            end
        else
            # for rust_i in rids
            #     @inbounds rust_step_w!(model, model[rust_i], model[model[rust_i].hg_id], fung)
            # end
            for rust in shuffle(model.rng, model.current.rusts)
                rust_step_w!(model, rust, model[rust.hg_id], fung)
            end
        end
    elseif model.current.rain
        # for rust_i in rids
        #     @inbounds rust_step_r!(model, model[rust_i], model[model[rust_i].hg_id], fung)
        # end
        for rust in shuffle(model.rng, model.current.rusts)
            rust_step_r!(model, rust, model[rust.hg_id], fung)
        end
    else
        # for rust_i in rids
        #     @inbounds rust_step_!(model, model[rust_i], model[model[rust_i].hg_id], fung)
        #     #could just be grow_rust! ?
        # end
        for rust in shuffle(model.rng, model.current.rusts)
            rust_step_!(model, rust, model[rust.hg_id], fung)
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

function coffee_step!(model::ABM, coffee::Coffee)
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
