function coeff_vars(n::Int, mtemp::Float64, rainp::Float64, windp::Float64, y::Int)

    ns = [25; 50; 75; 100:100:1000]
    # if n == 100
    #    ns = collect(20:20:100)
    # end
    a_ns = filter(x -> x .<= n, ns)

    df = cv_n_sims(a_ns, mtemp, rainp, windp, y)

    # CSV.write("results/Shading/ABCests/CV/raw-$(y)y.csv", df)

    coeff_vars = combine(groupby(df, :n), [:totprod, :maxA, :maxS, :maxE] =>
        ((p, a, s, e) -> (
            prod = (std(p) / mean(p)),
            area = (std(a) / mean(a)),
            spore = (std(s) / mean(s)),
            exh = (std(e) / mean(e)))
        ) => AsTable)

    return coeff_vars
end

function cv_n_sims(a_ns::Vector{Int}, mtemp::Float64, rainp::Float64, windp::Float64, y::Int)::DataFrame
    run_ns = reduce(vcat, fill.(a_ns, a_ns))
    fmap = create_farm_map(100, 2, 1, 9, :regular, 1, (0,0))
    ss = y * 365
    w = createweather(rainp, windp, mtemp, ss, Xoshiro(22))
    wrain = w.rain_data
    wwind = w.wind_data
    wtemp = w.temp_data

    # if isempty(pars)
    #     pars = CSV.read("results/ABC/params/sents/q8/byoccnl_pointestimate.csv", DataFrame)
    # end

    # df = DataFrame(run = Int[], totprod = Float64[], maxA = Float64[])
    # for 1:n
    #     push!(df, one_cv_sim(pars, map))
    # end

    rtime = @elapsed begin
        wp = CachingPool(workers())
        dfs = pmap(x -> one_cv_sim(fmap, wtemp, wrain, wwind, ss, x), wp, run_ns)
    end
    # rtime = @elapsed dfs = map(x -> one_cv_sim(fmap, wtemp, wrain, wwind, ss, x), run_ns)

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

function one_cv_sim(fmap::Array{Int,2}, tempd::Vector{Float64}, raind::Vector{Bool}, windd::Vector{Bool}, ss::Int, n::Int)::DataFrame
    model = init_spatialrust(
        steps = ss,
        inspect_period = ss,
        fungicide_sch = Int[],
        prune_sch = [74,227,-1], 
        post_prune = [0.4, 0.4, -1],
        shade_g_rate = 0.008,
        farm_map = copy(fmap),
        rain_data = copy(raind),
        wind_data = copy(windd),
        temp_data = copy(tempd))

    return custom_run!(model, n, ss)
end

function custom_run!(model::SpatialRustABM, n::Int, ss::Int)
    allcofs = model.agents
    maxareas = 0.0
    maxspores = 0.0
    maxexh = 0.0

    s = 0
    myaupcA = 0.0
    myaupcS = 0.0
    myaupcE = 0.0
    while s < ss
        s += step_n!(model, 5)
        myaupcA += mean(map(r -> sum(r.areas), allcofs))
        myaupcS += mean(map(r -> sum(r.spores), allcofs))
        myaupcE += mean(map(r -> r.exh_countdown > 0, allcofs))
        if s % 365 == 0
            if myaupcA > maxareas
                maxareas = myaupcA
            end
            if myaupcS > maxspores
                maxspores = myaupcS
            end
            if myaupcE > maxexh
                maxexh = myaupcE
            end
            myaupcA = 0.0
            myaupcS = 0.0
            myaupcE = 0.0
        end
    end

    return DataFrame(
        totprod = model.current.prod,
        maxA = maxareas,
        maxS = maxspores,
        maxE = maxexh,
        n = n
    )
end

