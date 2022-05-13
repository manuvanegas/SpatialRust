
combinations(conds) = DrWatson.dict_list(conds)

function run_par_combination(combination::Dict{Symbol, Any})
    pars = Parameters(
        steps = combination[:steps],
        shade_d = combination[:shade_d],
        barrier_arr = combination[:barrier_arr],
        shade_target = combination[:shade_target],
        pruning_period = combination[:pruning_period],
        fungicide_period = combination[:fungicide_period],
        barrier_rows = combination[:barrier_rows]
    )

    model = init_spatialrust(pars) # farm_map changes for each iteration
    _ , mdf = run!(model, dummystep, step_model!, pars.steps;
        when_model = [pars.steps],
        mdata = [totprod, maxA])
    mdf = vcat(DataFrame(combination), mdf[:, [:totprod, :maxA]])
    return mdf
end

function shading_experiment(conds::Dict{Symbol, Any})
    combinations = combinations(conds)
    dfs = pmap(run_par_combination, combinations)
    df = reduce(vcat, dfs)
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
