function coeff_vars(n::Int, mtemp::Float64, rainp::Float64, y::Int,
    pars::DataFrame = DataFrame())

    ns = [25; 50; 75; 100:100:1000]
    # if n == 100
    #    ns = collect(20:20:100)
    # end
    a_ns = filter(x -> x .<= n, ns)

    df = cv_n_sims(a_ns, pars, mtemp, rainp, y)

    # CSV.write("results/Shading/ABCests/CV/raw-$(y)y.csv", df)

    coeff_vars = combine(groupby(df, :n), [:totprod, :maxA, :maxS, :maxI] =>
        ((p, a, s, inc) -> (
            prod = (std(p) / mean(p)),
            area = (std(a) / mean(a)),
            spore = (std(s) / mean(s)),
            incid = (std(inc) / mean(inc)))
        ) => AsTable)

    return coeff_vars
end

function cv_n_sims(a_ns::Vector{Int}, pars::DataFrame, mtemp::Float64, rainp::Float64, y::Int)::DataFrame
    run_ns = reduce(vcat, fill.(a_ns, a_ns))
    fmap = create_farm_map(100, 2, 1, 9, :regular, 1, (0,0))
    ss = y * 365 + 1

    if isempty(pars)
        pars = CSV.read("results/ABC/params/sents/q8/byoccnl_pointestimate.csv", DataFrame)
    end

    # df = DataFrame(run = Int[], totprod = Float64[], maxA = Float64[])
    # for 1:n
    #     push!(df, one_cv_sim(pars, map))
    # end

    rtime = @elapsed begin
        wp = CachingPool(workers())
        dfs = pmap(x -> one_cv_sim(fmap, pars, mtemp, rainp, ss, x), wp, run_ns)
    end

    println("took $rtime to run $(length(run_ns)) (n was $(maximum(a_ns)))")
    flush(stdout)
    
    df = reduce(vcat, dfs)

    # if length(df.totprod) != n
    #     println("need to take steps")
    #     println("df is $(length(df.totprod)) long")
    #     flush(stdout)
    # end

    return df
end

function one_cv_sim(fmap::Array{Int,2}, pars::DataFrame, mtemp::Float64, rainp::Float64, ss::Int, n::Int)::DataFrame
    # ss = 1461 #366
    model = init_spatialrust(
        steps = ss,
        inspect_period = ss,
        fungicide_sch = Int[],
        prune_sch = [15,196,-1], 
        target_shade = [0.2, 0.2, -1],
        shade_g_rate = 0.008,
        farm_map = copy(fmap),
        rain_prob = rainp,
        wind_prob = 0.7,
        mean_temp = mtemp;
        # from ABC
        pars[1,:]...)

    return custom_run!(model, n, ss)
end

function custom_run!(model::SpatialRustABM, n::Int, ss::Int)
    allcofs = model.agents
    maxareas = 0.0
    maxspores = 0.0
    maxinf = 0.0

    s = 0
    myaupcA = 0.0
    myaupcS = 0.0
    myaupcI = 0.0
    while s < ss #1461 #366
        step_model!(model)
        myaupcA += mean(map(r -> sum(r.areas), allcofs))
        myaupcS += mean(map(r -> sum(r.spores), allcofs))
        myaupcI += mean(map(r -> r.n_lesions > 0, allcofs))
        if s % 365 == 0
            if myaupcA > maxareas
                maxareas = myaupcA
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
        n = n
    )
end

