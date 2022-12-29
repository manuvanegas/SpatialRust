export step_model!

function step_model!(model::ABM)
    pre_step!(model)
    grow_shades!(model.current, model.mngpars.shade_g_rate)
    # agent_step!(model)
    coffee_step!(model)
    rust_step!(model)
    farmer_step!(model)
    # for rust in model.current.rusts
    #     if any(rust.ages .> model.rustpars.steps * 2 + 1 + model.current.ticks)
    #     # if any(model.rustpars.steps + 1 .> rust.ages .> model.current.ticks)
    #         rids = getproperty.(model.current.rusts, (:id))
    #         @error "t $(model.current.ticks), rusts $rids, eg $(rust.id)"
    #         break
    #     end
    #     rids = collect(r.id for r in model.current.rusts)
    #     if !allunique(rids)
    #         @error "t $(model.current.ticks), repeated id within $rids"
    #     end
    # end
end

# Testing "one pass" approach, but it was slower

# function growth_phase(cg::GrowthPhase)
#     if cg.next_in == 1
#         cg.ix = mod1(cg.ix + 1, 3)
#         cg.next_in = cg.phase_ds[cg.ix]
#     else
#         cg.next_in -= 1
#     end
#     #TODO @inbounds
#     return cg.phase_fs[cg.ix]
# end

function agent_step!(model::ABM)
    let vegd = model.coffeepars.veg_d,
        repd = model.coffeepars.rep_d,
        cycled = mod1(model.current.days, 365)
        # dayconds = (),
        # doy = mod1(model.current.days, 365)


        if vegd < repd
            # vegd = pars.veg_d
            # repd = pars.rep_d
            # cycled = prod_cycle_d
            if vegd <= cycled < repd
                growth_phase = veg_growth!
            elseif cycled == repd
                growth_phase = commit_growth!
            else
                growth_phase = rep_growth!
            end
        else
            # vegd = - pars.veg_d
            # repd = - pars.rep_d
            # cycled = - prod_cycle_d
            if - vegd <= - cycled < - repd
                growth_phase = veg_growth!
            elseif cycled == repd
                growth_phase = commit_growth!
            else
                growth_phase = rep_growth!
            end
        end

        if model.current.fung_effect == 0
            # let fung_mods = model.current.fung_effect > 0 ? model.fung_mods : (1.0,1.0,1.0,1.0,1.0)
            if model.current.rain
                if model.current.wind
                    daily_schedule!(model, growth_phase, r_germinate!, grow_rust!, 1.0, 0, disperse_rain!, disperse_wind!)
                    outside_spores!(model)
                    # r_w_step(model)
                else
                    daily_schedule!(model, growth_phase, r_germinate!, grow_rust!, 1.0, 0, disperse_rain!)
                    # r_step(model)
                end
            else
                if model.current.wind
                    daily_schedule!(model, growth_phase, nr_germinate!, grow_rust!, 1.0, 0, disperse_wind!)
                    outside_spores!(model)
                    # w_step(model)
                else
                    daily_schedule!(model, growth_phase, nr_germinate!, grow_rust!, 1.0, 0)
                    # n_step(model)
                end
            end
        else
            let f_day = model.current.fung_effect,
                fung_inf = model.rustpars.fung_inf
                if model.current.rain
                    if model.current.wind
                        daily_schedule!(model, growth_phase, r_germinate!, grow_f_rust!, fung_inf, f_day, disperse_rain!, disperse_wind!)
                        outside_spores!(model)
                        # rust_step_schedule(rust, model.rng, local_temp, grow_f_rust!, parasitize!, disperse_rain!, disperse_wind!)
                        # f_r_w_step(model::ABM)
                    else
                        daily_schedule!(model, growth_phase, r_germinate!, grow_f_rust!, fung_inf, f_day, disperse_rain!)
                        # f_r_step(model)
                    end
                else
                    if model.current.wind
                        daily_schedule!(model, growth_phase, nr_germinate!, grow_f_rust!, fung_inf, f_day, disperse_wind!)
                        outside_spores!(model)
                        # f_w_step(model)
                    else
                        daily_schedule!(model, growth_phase, nr_germinate!, grow_f_rust!, fung_inf, f_day)
                        # f_step(model)
                    end
                end
            end
        end
    end
end

function daily_schedule!(model::ABM, cof_growth::Function, germinate_f::Function, grow_f::Function,
    f_inf::Float64, f_day::Int, dispersal_fs::Vararg{Function, N}
    ) where {N}
    let cpars = model.coffeepars,
        rpars = model.rustpars,
        shade = model.current.ind_shade,
        farm_map = model.farm_map,
        shade_map = model.shade_map
        
        for coffee in values(model.agents)
            # cof_growth(coffee, cpars, shade_map, shade)
            if coffee.exh_countdown == 0
                update_sunlight!(coffee, shade_map, shade)
                cof_growth(coffee, cpars)
                let local_temp = model.current.temperature - (rpars.temp_cooling * (1.0 - coffee.sunlight))
                    germinate_f(coffee, model.rng, rpars, local_temp, f_inf)
                    if coffee.n_lesions > 0
                        grow_f(coffee, model.rng, rpars, local_temp, f_day)
                        parasitize!(coffee, rpars)
                        for f in dispersal_fs
                            f(model, coffee)
                        end
                    end
                    if 0.0 < coffee.deposited < 0.1 #DELETE 0.0 <
                        coffee.deposited = 0.0
                        if coffee.n_lesions == 0
                            delete!(model.current.rusts, coffee)
                        end
                    end
                end
                if any(rpars.steps * 2 .>= coffee.ages .> model.current.ticks)
                    @error "t $(model.current.ticks), r $(coffee.id), $(coffee.n_lesions), $(coffee.ages), $(coffee.deposited)"
                end
            elseif coffee.exh_countdown > 1
                coffee.exh_countdown -= 1
            else
                update_sunlight!(coffee, shade_map, ind_shade)
                coffee.veg = 1.0
                coffee.storage = init_storage(coffee.sunlight)
                coffee.exh_countdown = 0
                @inbounds farm_map[coffee.pos...] = 1
            end
        end
    end
end

## "Step" functions

function pre_step!(model::ABM)
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
    let prod_cycle_d = mod1(model.current.days, 365),
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
        elseif cycled == repd
            for cof in values(model.agents)
                commit_step!(cof, pars, model.shade_map, model.current.ind_shade)
            end
        else
            for cof in values(model.agents)
                reproductive_step!(cof, pars, model.shade_map, model.current.ind_shade)
            end
        end
    end
end

function rust_step!(model::ABM)
    # fung = ifelse(model.current.fung_effect > 0, (growth = 0.95, spor = 0.8, germ = 0.9),
    #     (growth = 1.0, spor = 1.0, germ = 1.0))
    # three independent conditions: fungicide in effect? rainy? windy? -> 8 options
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
        let f_day = model.current.fung_effect,
            fung_inf = model.rustpars.fung_inf
            if model.current.rain
                if model.current.wind
                    rust_step_schedule(model, fung_inf, f_day, r_germinate!, grow_f_rust!, disperse_rain!, disperse_wind!)
                    outside_spores!(model)
                    # rust_step_schedule(rust, model.rng, local_temp, grow_f_rust!, parasitize!, disperse_rain!, disperse_wind!)
                    # f_r_w_step(model::ABM)
                else
                    rust_step_schedule(model, fung_inf, f_day, r_germinate!, grow_f_rust!, disperse_rain!)
                    # f_r_step(model)
                end
            else
                if model.current.wind
                    rust_step_schedule(model, fung_inf, f_day, nr_germinate!, grow_f_rust!, disperse_wind!)
                    outside_spores!(model)
                    # f_w_step(model)
                else
                    rust_step_schedule(model, fung_inf, f_day, nr_germinate!, grow_f_rust!)
                    # f_step(model)
                end
            end
        end
    end
    # Update happens in a second loop because first all rusts have had to (try to) disperse
    for rust in model.current.rusts
        update_deposited!(rust, model.current.rusts)
    end
end

function rust_step_schedule(model::ABM, f_inf::Float64, f_day::Int, germinate_f::Function, grow_f::Function,
    # rust::Rust, rng::AbstractRNG, local_temp::Float64,
    # # fung_mods::NTuple{5, Float64}, #put fung_mods within rustpars. reason to keep out was if using same fnc and ones(), but not anymore
    dispersal_fs::Vararg{Function, N}
    ) where {N}
    # for rust in shuffle!(model.rng, collect(values(model.agents))) # shuffle may not be necessary 
    # for rust in shuffle!(filter!(isinfected, collect(allagents(model)))) # or
    # for rust in shuffle!([model.current.rusts...]) # dispersal pushes, parasitize rm
    # for rust in values(model.agents) #BENCH 
    for rust in shuffle!(model.rng, collect(model.current.rusts)) # using Rust set is faster than looping through agents
        let local_temp = model.current.temperature - (model.rustpars.temp_cooling * (1.0 - rust.sunlight))
            germinate_f(rust, model.rng, model.rustpars, local_temp, f_inf)
            grow_f(rust, model.rng, model.rustpars, local_temp, f_day)
        end
        # if any(model.rustpars.steps * 2 .>= rust.ages .> model.current.ticks)
        #     @error "t $(model.current.ticks), r $(rust.id), $(rust.n_lesions), $(rust.ages), $(rust.deposited)"
        # end
        # parasitize!(rust, model.rustpars, model.current.rusts)
        parasitize!(rust, model.rustpars)
        for f in dispersal_fs
            f(model, rust)
        end
        # if rust.deposited < 0.1
        #     rust.deposited = 0.0
        #     if rust.n_lesions == 0
        #         delete!(model.current.rusts, rust)
        #     end
        # end
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
    let doy = mod1(model.current.days, 365)

        if doy == model.mngpars.harvest_day
            harvest!(model)
        end

        if doy in model.mngpars.prune_sch
            prune_shades!(model)
        end

        # the following is commented out for ABC. TODO: uncomment it when calibration is done

        if model.current.days % model.mngpars.inspect_period == 0
            inspect!(model)
        end

        if model.current.fung_effect > 0
            model.current.fung_effect -= 1
        elseif model.mngpars.incidence_as_thr
            if model.current.fung_count < 4 && model.current.obs_incidence > model.mngpars.incidence_thresh
                fungicide!(model)
            end
        elseif doy in model.mngpars.fungicide_sch
            fungicide!(model)
        end
    end
end
