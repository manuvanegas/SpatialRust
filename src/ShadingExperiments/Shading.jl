function shading_experiment(conds::DataFrame)
    # combinations = dict_list(conds)
    wp = CachingPool(workers())
    runtime = @elapsed dfs = pmap(run_par_combination, wp, eachrow(conds))
    reducetime = @elapsed df = reduce(vcat, dfs)
    println("Run: $runtime, Reduce: $reducetime")
    df[!, :barriers] .= df[!, :barriers] .== Ref((1,1))
    df[!, :prunes_year] = length.(df[!, :prune_sch])
    return df
end

function run_par_combination(pars::DataFrameRow)
    model = init_spatialrust(; pars...)
    mdf = custom_run!(model, pars[:steps])

    return hcat(
        DataFrame(pars[[:rep, :barriers, :shade_d, :target_shade, :prune_sch, :mean_temp, :rain_prob]]),
        mdf
        )
end

function custom_run!(model::SpatialRustABM, steps::Int)
    allcofs = model.agents

    s = 0
    myaupcA = 0.0
    myaupcS = 0.0
    myaupcI = 0.0
    shadetracker = 0.0
    
    while s < 365
        step_model!(model)
        myaupcA += mean(map(r -> sum(r.areas), allcofs))
        myaupcS += mean(map(r -> sum(r.spores), allcofs))
        myaupcI += mean(map(r -> r.n_lesions > 0, allcofs))
        shadetracker += model.current.ind_shade
        s += 1
        # shadetracker[s] = model.current.ind_shade
    end

    maxareas = myaupcA
    maxspores = myaupcS
    maxinf = myaupcI
    myaupcA = 0.0
    myaupcS = 0.0
    myaupcI = 0.0

    while s < 1461
        step_model!(model)
        myaupcA += mean(map(r -> sum(r.areas), allcofs))
        myaupcS += mean(map(r -> sum(r.spores), allcofs))
        myaupcI += mean(map(r -> r.n_lesions > 0, allcofs))
        if s % 365 == 0
            if myaupcA > maxareas
                maxspores = myaupcS
            end
            if myaupcS > maxspores
                maxspores = myaupcS
            end
            if myaupcI > maxinf
                maxinf = myaupcI
            end
            myaupcA = 0.0
            myaupcS = 0.0
            myaupcI = 0.0
        end
        s += 1
    end


    return DataFrame(
        totprod = model.current.prod,
        maxA = maxareas,
        maxS = maxspores,
        maxI = maxinf,
        shading = (shadetracker / 365) * mean(model.shade_map),
        n_coffees = model.mngpars.n_cofs,
        n_shades = model.mngpars.n_shades
    )
end

