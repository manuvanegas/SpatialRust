
# combinations(conds) = DrWatson.dict_list(conds)

function run_par_combination(combination::Dict{Symbol, Any})
    pop!(combination, :reps)
    pars = Parameters(; combination...)
    # if :shade_target in keys(combination)
    # pars = Parameters(
    #     steps = combination[:steps],
    #     shade_d = combination[:shade_d],
    #     barrier_arr = combination[:barrier_arr],
    #     target_shade = combination[:target_shade],
    #     prune_period = combination[:prune_period],
    #     fungicide_period = combination[:fungicide_period],
    #     barrier_rows = combination[:barrier_rows]
    # )
    # else
    # pars = Parameters(
    #     steps = combination[:steps],
    #     shade_d = combination[:shade_d],
    #     barrier_arr = combination[:barrier_arr],
    #     prune_period = combination[:prune_period],
    #     fungicide_period = combination[:fungicide_period],
    #     barrier_rows = combination[:barrier_rows]
    # )
    # end

    model = init_spatialrust(pars) # farm_map may change for each iteration
    _ , mdf = run!(model, dummystep, step_model!, pars.steps;
        when_model = [pars.steps],
        mdata = [totprod, maxA])
    pop!(combination, :barrier_rows)
    pop!(combination, :fungicide_period)
    pop!(combination, :steps)
    mdf = hcat(DataFrame(combination), mdf[:, [:totprod, :maxA]])
    # if :target_shade in propertynames(mdf)
    #     return mdf
    # else
    #     mdf[:, :target_shade] .= 0.0
    #     return mdf
    # end
    return mdf
end

function shading_experiment(conds::Dict{Symbol, Any})
    combinations = DrWatson.dict_list(conds)
    runtime = @elapsed dfs = pmap(run_par_combination, combinations)
    reducetime = @elapsed df = reduce(vcat, dfs)
    println("Run: $runtime, Reduce: $reducetime")
    return df
end

# function dict_to_pars(d::Dict{Symbol, Any})::Parameters
#     for prop in keys(d)
#     end
#     for prop in fieldnames(pars)
#     end
# end
#
# struct A
#     x
#     y
# end
#
# foo((; x, y)::A) = x + y
