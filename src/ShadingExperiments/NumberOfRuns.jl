## Functions to run parameter space exploration for Chapter 1

function coeff_vars(n::Int, mtemp::Float64, rainp::Float64,
    pars::DataFrame = DataFrame())

    ns = [25; 50; 75; 100:100:1000]
    # if n == 100
    #    ns = collect(20:20:100)
    # end
    a_ns = filter(x -> x .<= n, ns)

    df = cv_n_sims(a_ns, pars, mtemp, rainp)

    coeff_vars = combine(groupby(df, :n), [:totprod, :maxS, :maxI] =>
        ((p, s, inc) -> (
            prod = (std(p) / mean(p)),
            spore = (std(s) / mean(s)),
            incid = (std(inc) / mean(inc)))
        ) => AsTable)

    return coeff_vars
end

function cv_n_sims(a_ns::Vector{Int}, pars::DataFrame, mtemp::Float64, rainp::Float64)::DataFrame
    run_ns = reduce(vcat, fill.(a_ns, a_ns))
    fmap = create_farm_map(100, 2, 1, 9, :regular, 1, (0,0))

    if isempty(pars)
        pars = CSV.read("results/ABC/params/sents/q8/byoccnl_pointestimate.csv", DataFrame)
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
        inspect_period = ss,
        fungicide_sch = Int[],
        prune_sch = [182,-1,-1], 
        target_shade = [0.15, -1, -1],
        shade_g_rate = 0.008,
        farm_map = copy(fmap),
        rain_prob = rainp,
        mean_temp = mtemp;
        # from ABC
        pars[1,:]...)

    return custom_run!(model, ss, n)
end

function custom_run!(model::SpatialRustABM, steps::Int, n::Int)
    # pre_run!(model)
    allcofs = model.agents
    maxspores = 0.0
    maxinf = 0.0

    s = 0
    myaupcS = 0.0
    myaupcI = 0.0
    while s < steps
        step_model!(model)
        myaupcS += sum(map(r -> mean(r.spores), allcofs))
        myaupcI += mean(map(r -> r.n_lesions > 0, allcofs))
        if s % 365 == 0
            if myaupcS > maxspores
                maxspores = myaupcS
            end
            if myaupcI > maxinf
                maxinf = myaupcI
            end
            myaupcS = 0.0
            myaupcI = 0.0
        end
        s += 1
    end

    return DataFrame(totprod = model.current.prod, maxS = maxspores, maxI = maxinf, n = n)
end

