function custom_run!(model::SpatialRustABM, steps::Int)
    max_area = 0

    s = 0
    while Agents.until(s, steps, model)
        step!(model, dummystep, step_model!, 1)
        sumareas = filter(>(0.0), sum.(getproperty.(model.agents, :areas)))
        if !isempty(sumareas)
            if (currentarea = mean(sumareas)) > max_area
                max_area = currentarea
            end
        end
        s += 1
    end

    return DataFrame(
        totprod = model.current.prod,
        maxA = max_area,
        n_coffees = model.mngpars.n_cofs,
        n_shades = model.mngpars.n_shades
    )
end

function run_par_combination(pars::DataFrameRow)
    pars[:target_shade] = fill(pars[:target_shade], 3)
    model = init_spatialrust(; pars...) # farm_map may change for each iteration
    mdf = custom_run!(model, pars[:steps])

    return hcat(
        DataFrame(pars[[:rep, :barriers, :shade_d, :target_shade, :prune_sch, :mean_temp, :rain_prob]]),
        mdf
        )
end

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
