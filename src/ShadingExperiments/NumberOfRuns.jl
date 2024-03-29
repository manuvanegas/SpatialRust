function coeff_vars(n::Int, mtemp::Float64, rainp::Float64, windp::Float64, y::Int)

    ns = [10; 25; 50:50:500; 600:100:1000]
    # if n == 100
    #    ns = collect(20:20:100)
    # end
    # a_ns = n == 450 ? [10, 125, 150, 250, 350, 450] : filter(x -> x .<= n, ns)
    a_ns = filter(x -> x .<= n, ns)

    df = cv_n_sims(a_ns, mtemp, rainp, windp, y)

    # CSV.write("results/Shading/ABCests/CV/raw-$(y)y.csv", df)
    transform!(df, [:obsprod, :attprod] => ByRow((o, e) -> (1.0 - o / e)) => :loss)

    coeff_vars = combine(groupby(df, :n), [:obsprod, :loss, :maxA, :maxS, :maxN, :maxE] =>
        ((p, l, a, s, n, e) -> (
            prod = (std(p) / mean(p)),
            loss = (std(l) / mean(l)),
            area = (std(a) / mean(a)),
            spore = (std(s) / mean(s)),
            nls = (std(n) / mean(n)),
            exh = (std(e) / mean(e)),
            mprod = mean(p),
            mloss = mean(l),
            mspore = mean(s))
        ) => AsTable,
        nrow)

    return coeff_vars
end

function cv_n_sims(a_ns::Vector{Int}, mtemp::Float64, rainp::Float64, windp::Float64, y::Int)::DataFrame
    run_ns = reduce(vcat, fill.(a_ns, a_ns))
    fmap = create_farm_map(100, 2, 1, 9, :regular, 2, (0,0))
    ss = y * 365
    w = createweather(rainp, windp, mtemp, ss, Xoshiro(22))
    wrain = w.rain_data
    wwind = w.wind_data
    wtemp = w.temp_data

    rtime = @elapsed begin
        wp = CachingPool(workers())
        dfs = pmap(x -> one_cv_sim(fmap, wtemp, wrain, wwind, ss, x), wp, run_ns)
    end
    # rtime = @elapsed dfs = map(x -> one_cv_sim(fmap, wtemp, wrain, wwind, ss, x), run_ns)

    println("took $rtime to run $(length(run_ns)) (n was $(maximum(a_ns)))")
    flush(stdout)
    
    df = reduce(vcat, dfs)

    return df
end

function one_cv_sim(fmap::Array{Int,2}, tempd::Vector{Float64}, raind::Vector{Bool}, windd::Vector{Bool}, ss::Int, n::Int)::DataFrame
    model = init_spatialrust(
        steps = ss,
        inspect_period = ss,
        fungicide_sch = Int[],
        prune_sch = [74, 227, -1], 
        post_prune = [0.4, 0.4, -1],
        shade_g_rate = 0.008,
        farm_map = copy(fmap),
        rain_data = copy(raind),
        wind_data = copy(windd),
        temp_data = copy(tempd))
        
    attmodel = init_spatialrust(
        p_rusts = 0.0,
        steps = ss,
        inspect_period = ss,
        fungicide_sch = Int[],
        prune_sch = [74, 227, -1], 
        post_prune = [0.4, 0.4, -1],
        shade_g_rate = 0.008,
        farm_map = copy(fmap),
        rain_data = copy(raind),
        wind_data = copy(windd),
        temp_data = copy(tempd))

    return hcat(custom_run!(model, n, ss), att_run!(attmodel, ss))
end

function custom_run!(model::SpatialRustABM, n::Int, ss::Int)
    allcofs = model.agents
    ncofs = length(allcofs)
    maxareas = 0.0
    maxspores = 0.0
    maxnl = 0.0
    maxexh = 0.0

    s = 0
    myaudpcA = 0.0
    myaudpcS = 0.0
    myaudpcN = 0.0
    myaudpcE = 0.0
    while s < ss
        s += step_n!(model, 5)
        active = Iterators.filter(c -> c.exh_countdown == 0, allcofs)
        myaudpcA += mean(map(r -> sum(r.areas), active))
        myaudpcS += mean(map(inoculum, active))
        myaudpcN += mean(map(r -> r.n_lesions, active))
        myaudpcE += 1.0 - sum(allof, active) / ncofs
        if s % 365 == 0
            if myaudpcA > maxareas
                maxareas = myaudpcA
            end
            if myaudpcS > maxspores
                maxspores = myaudpcS
            end
            if myaudpcN > maxnl
                maxnl = myaudpcN
            end
            if myaudpcE > maxexh
                maxexh = myaudpcE
            end
            myaudpcA = 0.0
            myaudpcS = 0.0
            myaudpcN = 0.0
            myaudpcE = 0.0
        end
    end

    return DataFrame(
        obsprod = model.current.prod,
        maxA = maxareas,
        maxS = maxspores,
        maxN = maxnl,
        maxE = maxexh,
        n = n
    )
end

allof(c::Coffee) = true

function inoculum(r::Coffee)
    if isempty(r.areas)
        return 0.0
    else
        return sum(a * s for (a,s) in zip(r.areas, r.spores)) * (1.0 + r.sunlight) * 0.3836
    end
end

function att_run!(model::SpatialRustABM, ss::Int)
    step_n!(model, ss)
    return DataFrame(attprod = model.current.prod)
end
