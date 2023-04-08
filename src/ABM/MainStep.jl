export step_model!

function step_model!(model::SpatialRustABM)
    pre_step!(model)
    grow_shades!(model.current, model.mngpars.shade_g_rate)
    # agent_step!(model)
    coffee_step!(model)
    rust_step!(model)
    farmer_step!(model)
    # for rust in model.rusts
    #     if any(rust.ages .> model.rustpars.steps * 2 + 1 + model.current.ticks)
    #     # if any(model.rustpars.steps + 1 .> rust.ages .> model.current.ticks)
    #         rids = getproperty.(model.rusts, (:id))
    #         @error "t $(model.current.ticks), rusts $rids, eg $(rust.id)"
    #         break
    #     end
    #     rids = collect(r.id for r in model.rusts)
    #     if !allunique(rids)
    #         @error "t $(model.current.ticks), repeated id within $rids"
    #     end
    # end
    return nothing
end

## "Step" functions

function pre_step!(model::SpatialRustABM)
    # update day counters
    model.current.days += 1
    t = model.current.ticks += 1

    # update weather conditions from Weather data
    model.current.rain = model.weather.rain_data[t]
    @inbounds model.current.wind = model.weather.wind_data[t]
    @inbounds model.current.temperature = model.weather.temp_data[t]

    # spore outpour decay, then outpour can return spores to the farm if windy
    model.outpour .*= 0.9
    if model.current.wind
        model.current.wind_h = rand(model.rng) * 360.0
    end

    # if t % 60 == 0 && sum(map(c -> c.rusted, model.agents)) == 0
    #     if sum(model.outpour) == 0.0
    #         reintroduce_rusts!(model, 10)
    #     else
    #         reintroduce_rusts!(model, 1)
    #     end
    # end
    return nothing
end

function coffee_step!(model::SpatialRustABM)
    prod_cycle_d = mod1(model.current.days, 365)
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

    if cycled != repd
        if vegd <= cycled < repd
            growth = veg_growth!
        else
            growth = rep_growth!
        end
        for cof in model.agents
            if cof.exh_countdown == 0
                sl = update_sunlight!(cof, model.shade_map, model.current.ind_shade)
                growth(cof, pars, sl)
            elseif cof.exh_countdown > 1
                cof.exh_countdown -= 1
            else
                sl = update_sunlight!(cof, model.shade_map, model.current.ind_shade)
                regrow!(cof, sl, model.farm_map)
            end
        end
    else
        commit_dist = Normal(pars.res_commit, 0.01)
        for cof in model.agents
            if cof.exh_countdown == 0
                sl = update_sunlight!(cof, model.shade_map, model.current.ind_shade)
                veg_growth!(cof, pars, sl)
                cof.production = max(0.0, rand(model.rng, commit_dist) * cof.sunlight * cof.veg * cof.storage)
            elseif cof.exh_countdown > 1
                cof.exh_countdown -= 1
            else
                sl = update_sunlight!(cof, model.shade_map, model.current.ind_shade)
                regrow!(cof, sl, model.farm_map)
            end
        end
    end
    return nothing
end

function rust_step!(model::SpatialRustABM)
    # fung = ifelse(model.current.fungicide > 0, (growth = 0.95, spor = 0.8, germ = 0.9),
    #     (growth = 1.0, spor = 1.0, germ = 1.0))
    # three independent conditions: fungicide in effect? rainy? windy? -> 8 options
    # not the most clean/maintainable implementation, but I was prioritizing min sim time
    if model.current.fungicide == 0
    # let fung_mods = model.current.fungicide > 0 ? model.fung_mods : (1.0,1.0,1.0,1.0,1.0)
        if model.current.rain
            if model.current.wind
                rust_step_schedule(model, 1.0, 0, r_germinate!, grow_rust!, disperse_rain!, disperse_wind!)
                outside_spores!(model)
                # r_w_step(model)
            else
                rust_step_schedule(model, 1.0, 0, r_germinate!, grow_rust!, disperse_rain!, dummy_disp)
                # r_step(model)
            end
        else
            if model.current.wind
                rust_step_schedule(model, 1.0, 0, nr_germinate!, grow_rust!, dummy_disp, disperse_wind!)
                outside_spores!(model)
                # w_step(model)
            else
                rust_step_schedule(model, 1.0, 0, nr_germinate!, grow_rust!, dummy_disp, dummy_disp)
                # n_step(model)
            end
        end
    else
        let f_day = model.current.fungicide,
            fung_inf = model.rustpars.fung_inf
            if model.current.rain
                if model.current.wind
                    rust_step_schedule(model, fung_inf, f_day, r_germinate!, grow_f_rust!, disperse_rain!, disperse_wind!)
                    outside_spores!(model)
                    # rust_step_schedule(rust, model.rng, local_temp, grow_f_rust!, parasitize!, disperse_rain!, disperse_wind!)
                    # f_r_w_step(model::SpatialRustABM)
                else
                    rust_step_schedule(model, fung_inf, f_day, r_germinate!, grow_f_rust!, disperse_rain!, dummy_disp)
                    # f_r_step(model)
                end
            else
                if model.current.wind
                    rust_step_schedule(model, fung_inf, f_day, nr_germinate!, grow_f_rust!, dummy_disp, disperse_wind!)
                    outside_spores!(model)
                    # f_w_step(model)
                else
                    rust_step_schedule(model, fung_inf, f_day, nr_germinate!, grow_f_rust!, dummy_disp, dummy_disp)
                    # f_step(model)
                end
            end
        end
    end
    # Update happens in a second loop because first all rusts have had to (try to) disperse
    for rust in Iterators.filter(r -> r.rusted, model.agents)
        update_rusts!(rust)
        # update_deposited!(rust, model.farm_map, model.rustpars)
    end
    return nothing
end

function rust_step_schedule(model::SpatialRustABM, f_inf::Float64, f_day::Int, germinate_f::Function, grow_f::Function,
    rain_dispersal::Function, wind_dispersal::Function)
    # rust::Rust, rng::AbstractRNG, local_temp::Float64,
    # dispersal_fs::Vararg{Function, N}
    # ) where {N}
    for rust in Iterators.filter(r -> r.rusted, model.agents)
        local_temp = model.current.temperature - (model.rustpars.temp_cooling * (1.0 - rust.sunlight))

        if rust.n_lesions > 0
            grow_f(rust, model.rng, model.rustpars, local_temp, f_day)

            germinate_f(rust, model.rng, model.rustpars, local_temp, f_inf)

            parasitize!(rust, model.rustpars, model.farm_map)
            
            if any(rust.spores)
                spore_area = sum(last(p) for p in pairs(rust.areas) if rust.spores[first(p)]) * model.rustpars.spore_pct
                rain_dispersal(model, rust, spore_area)
                wind_dispersal(model, rust, spore_area)
            end
        else
            germinate_f(rust, model.rng, model.rustpars, local_temp, f_inf)
        end
        
        if losttrack(rust.areas) || !isfinite(rust.storage)
            model.current.withinbounds = false
            break
        end
    end
    return nothing
end

function losttrack(as)
    any(a -> (!isfinite(a) || a < -0.1 || a > 25.5), as)
end

function farmer_step!(model)
    doy = mod1(model.current.days, 365)

    if doy == model.mngpars.harvest_day
        harvest!(model)
    end

    prune_i = findfirst(==(doy), model.mngpars.prune_sch)
    if !isnothing(prune_i)
        prune_shades!(model, model.mngpars.target_shade[prune_i])
    end

    # the following is commented out for ABC. TODO: uncomment it when calibration is done

    # if model.current.days % model.mngpars.inspect_period == 0
    #     inspect!(model)
    # end

    # if model.current.fungicide > 0
    #     model.current.fungicide -= 1
    # elseif model.mngpars.incidence_as_thr
    #     if model.current.fung_count < 4 && model.current.obs_incidence > model.mngpars.incidence_thresh
    #         fungicide!(model)
    #     end
    # elseif doy in model.mngpars.fungicide_sch
    #     fungicide!(model)
    # end
    
    return nothing
end
