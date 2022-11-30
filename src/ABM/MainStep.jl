export step_model!

function step_model!(model::ABM)
    pre_step!(model)
    grow_shades!(model.current, model.mngpars.shade_g_rate)
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
    # TODO add @inbounds after tests
    model.current.rain = model.weather.rain_data[model.current.ticks]
    model.current.wind = model.weather.wind_data[model.current.ticks]
    model.current.temperature = model.weather.temp_data[model.current.ticks]

    # spore outpour decay, then outpour can return spores to the farm if windy
    model.outpour .*= 0.9
    if model.current.wind
        model.current.wind_h = rand(model.rng) * 360.0
    end

    # update sampling cycle (for ABC)
    # if (model.current.ticks - 1) in model.mngpars.switch_cycles #TODO
    #     if model.current.cycle[1] == 5 && !isassigned(model.current.cycle, 2)
    #         push!(model.current.cycle, 6)
    #     else
    #         model.current.cycle .+= 1
    #     end
    # end
end

function coffee_step!(model::ABM)
    let prod_cycle_d = model.current.days % model.mngpars.harvest_day,
    pars = model.coffeepars

    if pars.veg_d < pars.rep_d
        vegd = pars.veg_d
        repd = pars.rep_d
        cycled = prod_cycle_d
    else
        vegd = - pars.veg_d
        repd = - pars.rep_d
        cycled = - prod_cycle_d
    end

    if vegd <= cycled < repd
        for cof in values(model.agents)
            vegetative_step!(cof, pars, model.shade_map, model.current.ind_shade)
        end
    # elseif pars.rep_d < pars.veg_d <= prod_cycle_d
    #     for cof in values(model.agents)
    #         vegetative_step!(model, cof)
    #     end
    elseif cycled == repd
        for cof in values(model.agents)
            vegetative_step!(cof, pars, model.shade_map, model.current.ind_shade)
            cof.production = pars.res_commit * estimate_resources(cof)
            # repr_commitment!(cof, pars)
        end
    else
        for cof in values(model.agents)
            reproductive_step!(cof, pars, model.shade_map, model.current.ind_shade)
        end
    end
    end

    # for cof in values(model.agents)
    #     coffee_ind_step!(model, cof)
    # end
end

function rust_step!(model::ABM)
    # fung = ifelse(model.current.fung_effect > 0, (growth = 0.95, spor = 0.8, germ = 0.9),
    #     (growth = 1.0, spor = 1.0, germ = 1.0))
    # three independent conditions: fugicide in effect? rainy? windy? -> 8 options
    # not the most clean/maintainable implementation, but I was prioritizing min sim time
    if model.current.fung_effect == 0
    # let fung_mods = model.current.fung_effect > 0 ? model.fung_mods : (1.0,1.0,1.0,1.0,1.0)
        if model.current.rain
            if model.current.wind
                rust_step_schedule(model, 1.0, 0, r_germinate!, grow_rust!, disperse_rain!, disperse_wind!)
                outside_spores!(model)
                # r_w_step(model)
            else
                rust_step_schedule(model, 1.0, 0, r_germinate!, grow_rust!, disperse_rain!)
                # r_step(model)
            end
        else
            if model.current.wind
                rust_step_schedule(model, 1.0, 0, nr_germinate!, grow_rust!, disperse_wind!)
                outside_spores!(model)
                # w_step(model)
            else
                rust_step_schedule(model, 1.0, 0, nr_germinate!, grow_rust!)
                # n_step(model)
            end
        end
    else
        let f_day = model.current.fung_effect
            if model.current.rain
                if model.current.wind
                    rust_step_schedule(model, model.fun_inf, f_day, r_germinate!, grow_f_rust!, disperse_rain!, disperse_wind!)
                    outside_spores!(model)
                    # rust_step_schedule(rust, model.rng, local_temp, grow_f_rust!, parasitize!, disperse_rain!, disperse_wind!)
                    # f_r_w_step(model::ABM)
                else
                    rust_step_schedule(model, model.fun_inf, f_day, r_germinate!, grow_f_rust!, disperse_rain!)
                    # f_r_step(model)
                end
            else
                if model.current.wind
                    rust_step_schedule(model, model.fun_inf, f_day, nr_germinate!, grow_f_rust!, disperse_wind!)
                    outside_spores!(model)
                    # f_w_step(model)
                else
                    rust_step_schedule(model, model.fun_inf, f_day, nr_germinate!, grow_f_rust!)
                    # f_step(model)
                end
            end
        end
        
    end
end

function rust_step_schedule(model::ABM, f_inf::Float64, f_day::Int, germinate_f::Function, grow_f::Function,
    # rust::Rust, rng::AbstractRNG, local_temp::Float64,
    # # fung_mods::NTuple{5, Float64}, #put fung_mods within rustpars. reason to keep out was if using same fnc and ones(), but not anymore
    fs::Vararg{Function, N}
    ) where {N}
    # for rust in shuffle!(model.rng, collect(values(model.agents))) # shuffle may not be necessary 
    # for rust in shuffle!(filter!(isinfected, collect(allagents(model)))) # or
    # for rust in shuffle!([model.current.rusts...]) # dispersal pushes, parasitize rm
    # for rust in values(model.agents) #BENCH 
    for rust in model.current.rusts
        let local_temp = model.current.temperature - (model.rustpars.temp_cooling * (1.0 - rust.sunlight))
            germinate_f(rust, model.rng, model.rustpars, local_temp, f_inf)
            grow_f(rust, model.rng, model.rustpars, local_temp, f_day)
        end
        parasitize!(rust, model.rustpars)
        for f in fs
            f(model, rust)
        end
    end
end

# function f_r_w_step(model::ABM)
#     for rust in shuffle(model.rng, values(model.agents))
#         host = model[rust.hg_id]
#         let local_temp = model.current.temperature - (model.pars.temp_cooling * (1.0 - host.sunlight))
#             grow_f_rust!(rust, host, model.rng, model.rustpars, model.fung_mods)
#             parasitize!(model, rust, host)
#             disperse_rain!(model, rust, sunlight)
#             disperse_wind!(model, rust, sunlight)
#         end
#     end
# end

# function f_r_step(model::ABM)
#     for rust in shuffle(model.rng, values(model.agents))
#         host = model[rust.hg_id]
#         grow_f_rust!(rust, host, model.rng, model.rustpars, model.fung_mods)
#         parasitize!(model, rust, host)
#         disperse_rain!(model, rust, sunlight)
#     end
# end

# function f_w_step(model::ABM)
#     for rust in shuffle(model.rng, values(model.agents))
#         host = model[rust.hg_id]
#         grow_f_rust!(rust, host, model.rng, model.rustpars, model.fung_mods)
#         parasitize!(model, rust, host)
#         disperse_wind!(model, rust, sunlight)
#     end
# end

# function f_step(model::ABM)
#     for rust in shuffle(model.rng, values(model.agents))
#         host = model[rust.hg_id]
#         grow_f_rust!(rust, host, model.rng, model.rustpars, model.fung_mods)
#         parasitize!(model, rust, host)
#     end
# end

# function r_w_step(model::ABM)
#     for rust in shuffle(model.rng, values(model.agents))
#         host = model[rust.hg_id]
#         grow_rust!(rust, host, model.rng, model.rustpars)
#         parasitize!(model, rust, host)
#         disperse_rain!(model, rust, sunlight)
#         disperse_wind!(model, rust, sunlight)
#     end
# end

# function r_step(model::ABM)
#     for rust in shuffle(model.rng, values(model.agents))
#         host = model[rust.hg_id]
#         grow_rust!(rust, host, model.rng, model.rustpars)
#         parasitize!(model, rust, host)
#         disperse_rain!(model, rust, sunlight)
#     end
# end

# function w_step(model::ABM)
#     for rust in shuffle(model.rng, values(model.agents))
#         host = model[rust.hg_id]
#         grow_rust!(rust, host, model.rng, model.rustpars)
#         parasitize!(model, rust, host)
#         disperse_wind!(model, rust, sunlight)
#     end
# end

# function n_step(model::ABM)
#     for rust in shuffle(model.rng, values(model.agents))
#         host = model[rust.hg_id]
#         grow_rust!(rust, host, model.rng, model.rustpars)
#         parasitize!(model, rust, host)
#     end
# end

function farmer_step!(model)
    let doy = model.current.days % 365

        if doy in model.mngpars.harvest_day
            harvest!(model)
        end

        if doy in model.mngpars.prune_sch
            prune_shades!(model)
        end

        # the following is commented out for ABC. TODO: uncomment it when calibration is done
        # incidence = 0

        # if model.current.days % model.mngpars.inspect_period == 0
        #     incidence = inspect!(model)
        # end

        # if model.current.fung_effect > 0
        #     model.current.fung_effect -= 1
        # elseif model.mngpars.incidence_as_thr
        #     if model.current.fung_count < 4 && incidence > model.mngpars.incidence_thresh
        #         fungicide!(model)
        #     end
        # elseif doy in model.mngpars.fungicide_sch
        #     fungicide!(model)
        # end
    end
end
