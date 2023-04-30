function shading_experiment(conds::DataFrame, rain::Float64, wind::Float64, temp::Float64)
    # combinations = dict_list(conds)
    w = createweather(rain, wind, temp, conds[1,:steps], Xoshiro(22))
    wp = CachingPool(workers())
    runtime = @elapsed dfs = pmap(r -> run_par_combination(r, w), wp, eachrow(conds))
    reducetime = @elapsed df = reduce(vcat, dfs)
    println("Run: $runtime, Reduce: $reducetime, # Runs: $(length(dfs))")
    df[!, :barriers] .= df[!, :barriers] .== Ref((1,1))
    df[!, :prunes_year] = length.(df[!, :prune_sch])
    return df
end

function run_par_combination(pars::DataFrameRow, w)
    model = init_spatialrust(
        rain_data = copy(w.rain_data),
        wind_data = copy(w.wind_data),
        temp_data = copy(w.temp_data);
        pars...
    )
    mdf = custom_run!(model)

    return hcat(
        DataFrame(pars[[:rep, :barriers, :shade_d, :post_prune, :prune_sch, :mean_temp, :rain_prob]]),
        mdf
    )
end

function custom_run!(model::SpatialRustABM)
    allcofs = model.agents
    ncofs = length(allcofs)

    s = 0
    myaudpcA = 0.0
    myaudpcS = 0.0
    myaudpcN = 0.0
    myaudpcE = 0.0
    shadetracker = 0.0
    
    while s < 365
        s += step_n!(model, 5)
        active = Iterators.filter(c -> c.exh_countdown == 0, allcofs)
        myaudpcA += mean(map(r -> sum(r.areas), active))
        myaudpcS += mean(map(r -> sum(r.spores), active))
        myaudpcN += mean(map(r -> r.n_lesions, active))
        myaudpcE += 1.0 - sum(allof, active) / ncofs
        shadetracker += model.current.ind_shade
    end

    maxareas = myaudpcA
    maxspores = myaudpcS
    maxnl = myaudpcN
    maxexh = myaudpcE
    myaudpcA = 0.0
    myaudpcS = 0.0
    myaudpcN = 0.0
    myaudpcE = 0.0

    while s < 1460 
        s += step_n!(model, 5)
        active = Iterators.filter(c -> c.exh_countdown == 0, allcofs)
        myaudpcA += mean(map(r -> sum(r.areas), active))
        myaudpcS += mean(map(r -> sum(r.spores), active))
        myaudpcN += mean(map(r -> r.n_lesions, active))
        myaudpcE += 1.0 - sum(allof, active) / ncofs
        if s % 365 == 0
            if myaudpcA > maxareas
                maxspores = myaudpcS
            end
            if myaudpcS > maxspores
                maxspores = myaudpcS
            end
            if myaudpcN > maxnl
                maxnl = myaudpcN
            end
            if myaudpcE > maxexh
                maxexh = myaudpcE
            end
            myaudpcA = 0.0
            myaudpcS = 0.0
            myaudpcN = 0.0
            myaudpcE = 0.0
        end
    end

    return DataFrame(
        totprod = model.current.prod,
        maxA = maxareas,
        maxS = maxspores,
        maxN = maxnl,
        maxE = maxexh,
        shading = (shadetracker / 365.0) * mean(model.shade_map),
        n_coffees = model.mngpars.n_cofs,
        n_shades = model.mngpars.n_shades
    )
end

allof(c::Coffee) = true

