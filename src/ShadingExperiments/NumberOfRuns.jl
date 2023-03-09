## Functions to run parameter space exploration for Chapter 1

function coeff_vars(n::Int, mtemp::Float64, rainp::Float64,
    pars::DataFrame = DataFrame())

    ns = [25; 50; 75; 100:100:1000]
    # if n == 100
    #    ns = collect(20:20:100)
    # end
    a_ns = filter(x -> x .<= n, ns)
    # coeff_vars = DataFrame(n = Int[], prod = Float64[], area = Float64[])
    df = cv_n_sims(a_ns, pars, mtemp, rainp)

    coeff_vars = combine(groupby(df, :n), [:totprod, :maxA] =>
        ((p, a) -> (
            prod = (std(p) / mean(p)),
            area = (std(a) / mean(a)))
            # corrprod = (std(log10.(p)) / mean(log10.(p))))
        ) => AsTable)

    # for run in run_ns
# "should try sequential instead of samples"
        # df = cv_n_sims(n, mtemp, rainp)
        # rows = sample(1:n, samples, replace = false)
        # thisdf = df[rows, :]
        # sds_means = combine(thisdf, All() .=> std, All() .=> mean)
        # push!(coeff_vars, (samples, (sds_means[1, :totprod_std] / sds_means[1, :totprod_mean]),
        # (sds_means[1, :maxA_std] / sds_means[1, :maxA_mean])))
        # append!(coeff_vars, sds_means)
    # end

    return coeff_vars
end

function cv_n_sims(a_ns::Vector{Int}, pars::DataFrame, mtemp::Float64, rainp::Float64)::DataFrame
    run_ns = reduce(vcat, fill.(a_ns, a_ns))
    fmap = create_farm_map(100, 2, 1, 9, :regular, 1, (0,0))

    if isempty(pars)
        pars = CSV.read("results/ABC/params/sents/novar/byaroccincid_pointestimate.csv", DataFrame)
    end

    # df = DataFrame(run = Int[], totprod = Float64[], maxA = Float64[])
    # for 1:n
    #     push!(df, one_cv_sim(pars, map))
    # end

    rtime = @elapsed begin
        wp = CachingPool(workers())
        dfs = pmap(x -> one_cv_sim(fmap, pars, mtemp, rainp, x), wp, run_ns)
    end

    println("took $rtime to run $(length(run_ns))")
    flush(stdout)
    
    df = reduce(vcat, dfs)

    # if length(df.totprod) != n
    #     println("need to take steps")
    #     println("df is $(length(df.totprod)) long")
    #     flush(stdout)
    # end

    return df
end

function one_cv_sim(fmap::Array{Int,2}, pars::DataFrame, mtemp::Float64, rainp::Float64, n::Int)::DataFrame
    ss = 1461
    model = init_spatialrust(
        steps = ss,
        inspect_period = 460,
        fungicide_sch = Int[],
        prune_sch = [182,-1,-1], 
        target_shade = 0.1,
        shade_g_rate = 0.008,
        farm_map = copy(fmap),
        rain_prob = rainp,
        mean_temp = mtemp;
        # from ABC
        pars[1,:]...)

    return custom_run!(model, ss, n)
end

function custom_run!(model::SpatialRustABM, steps::Int, n::Int)
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

    return DataFrame(totprod = model.current.prod, maxA = max_area, n = n)
end
