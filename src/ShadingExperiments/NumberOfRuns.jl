## Functions to run parameter space exploration for Chapter 1

function coeff_vars(n::Int, mtemp::Float64, rainp::Float64)
    ns = collect(100:100:1000)
    if n == 100
        ns = collect(10:10:100)
    end
    actual_ns = filter(x -> x .<= n, ns)
    coeff_vars = DataFrame(n = Int[], prod = Float64[], area = Float64[])
    df = cv_n_sims(n, mtemp, rainp)

    for samples in actual_ns
        rows = sample(1:n, samples, replace = false)
        thisdf = df[rows, :]
        sds_means = combine(thisdf, All() .=> std, All() .=> mean)
        push!(coeff_vars, (samples, (sds_means[1, :totprod_std] / sds_means[1, :totprod_mean]),
        (sds_means[1, :maxA_std] / sds_means[1, :maxA_mean])))
        # append!(coeff_vars, sds_means)
    end

    return coeff_vars
end

function cv_n_sims(n::Int, mtemp::Float64, rainp::Float64)::DataFrame
    pars = Parameters(
        steps = 1460,
        prune_period = 365,
        target_shade = 0.4,
        shade_d = 10,
        barrier_arr = (0,0,0,0),
        rain_prob = rainp,
        mean_temp = mtemp,
        # from ABC
        rust_gr = 1.63738,
        cof_gr = 0.393961,
        spore_pct = 0.821479,
        fruit_load = 0.597133,
        uv_inact = 0.166768,
        rain_washoff = 0.23116,
        rain_distance = 0.80621,
        wind_distance = 3.29275,
        exhaustion = 0.17458)

    fmap = SpatialRust.create_farm_map(pars)

    # df = DataFrame(run = Int[], totprod = Float64[], maxA = Float64[])
    # for 1:n
    #     push!(df, one_cv_sim(pars, map))
    # end

    dfs = pmap(x -> wrapper_one_cv(pars, fmap, x), 1:n)

    df = reduce(vcat, dfs)

    if length(df.totprod) != n
        println("need to take steps")
        println("df is $(length(df.totprod)) long")
        flush(stdout)
    end

    return df
end

function wrapper_one_cv(pars::Parameters, farm_map::Array{Int,2}, x::Int)::DataFrame
    return one_cv_sim(pars, farm_map)
end

function one_cv_sim(pars::Parameters, farm_map::Array{Int,2})::DataFrame
    # one_sim for par has to create its own farm_map each time
    model = init_spatialrust(pars, farm_map)
    _ , mdf = run!(model, dummystep, SpatialRust.step_model!, pars.steps;
        when_model = [pars.steps],
        mdata = [totprod, maxA])
    return mdf[:, [:totprod, :maxA]]
end

totprod(model::ABM) = model.current.prod
maxA(model::ABM) = model.current.max_rust
