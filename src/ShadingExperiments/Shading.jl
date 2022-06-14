
function run_par_combination(combination::Dict{Symbol, Any})
    pop!(combination, :reps)
    frags = pop!(combination, :fragments)
    combination[:barrier_arr] = ifelse(frags == 1, (0,0,0,0), ifelse(
        frags == 4, (1,1,0,0), (2,2,0,0)))

    pars = Parameters(; combination...)
    model = init_spatialrust(pars) # farm_map may change for each iteration
    _ , mdf = run!(model, dummystep, step_model!, pars.steps;
        when_model = [pars.steps],
        mdata = [totprod, maxA, n_coffees])
    pop!(combination, :steps)
    combination[:fragments] = frags
    mdf = hcat(DataFrame(combination), mdf[:, [:totprod, :maxA, :n_coffees]])

    return mdf
end

function shading_experiment(conds::Dict{Symbol, Any})
    combinations = DrWatson.dict_list(conds)
    runtime = @elapsed dfs = pmap(run_par_combination, combinations)
    reducetime = @elapsed df = reduce(vcat, dfs)
    println("Run: $runtime, Reduce: $reducetime")
    return df
end
