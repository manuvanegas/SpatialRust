# Simulations to run the Approx Bayesian Computation approach

export sim_abc, cat_dfs, abc_pmap, tempdata, raindata, winddata, collect_days

using StatsBase: corkendall
using Distributed

include(srcdir("ABC","Metrics.jl"))
include(srcdir("ABC","PrepforABC.jl"))
include(srcdir("ABC","Sentinels.jl"))
include(srcdir("ABC","SimData.jl"))

function abc_pmap(par_iterator, wp::CachingPool)
    return pmap(sim_abc,
        wp,
        par_iterator;
        retry_delays = fill(0.1, 3)
    )
end

function sim_abc(p_row::NamedTuple,
    # temp_data::NTuple{455, Float64},
    # rain_data::NTuple{455, Bool},
    # wind_data::NTuple{455, Bool},
    # when::Vector{Int}
    )
# function sim_abc(p_row::NamedTuple,
#     w::Weather{455},
#     when::Vector{Int}
#     )

    # sun_per_age_df, sun_exh_perc, sun_incid, sun_prod_clr_cor, sun_anyrusts = simulate_plots(
    #     p_row, temp_data, rain_data, wind_data, when_2017, when_2018, :fullsun
    # )

    # shade_per_age_df, shade_exh_perc, shade_incid, shade_prod_clr_cor, shade_anyrusts = simulate_plots(
    #     p_row, temp_data, rain_data, wind_data, when_2017, when_2018, :regshaded
    # )

    sun_per_age_df, sun_globs_df = simulate_single_plot(p_row, :fullsun)

    shade_per_age_df, shade_globs_df = simulate_single_plot(p_row, :regshaded)

    # sun_per_age_df, sun_globs_df = simulate_single_plot(
    #     p_row, w, when, :fullsun
    # )

    # shade_per_age_df, shade_globs_df = simulate_single_plot(
    #     p_row, w, when, :regshaded
    # )

    if p_row[:p_row] % 500 > 496
        GC.gc()
        # println("Row $(p_row[:p_row])")
        # println("gc at worker $(myid())")
        # println("Time $simtime")
        # println("")
        # flush(stdout)
    end

    per_age_df = vcat(sun_per_age_df, shade_per_age_df)
    per_age_df[!, :p_row] .= p_row[:p_row]
    globs_df = vcat(sun_globs_df, shade_globs_df)
    globs_df[!, :p_row] .= p_row[:p_row]

    return per_age_df, globs_df
end

# function simulate_single_plot(
#     p_row::NamedTuple,
#     temp_data::NTuple{455, Float64},
#     rain_data::NTuple{455, Bool},
#     wind_data::NTuple{455, Bool},
#     when::Vector{Int},
#     type::Symbol
# )
function simulate_single_plot(
    p_row::NamedTuple,
    type::Symbol
)
# function simulate_single_plot(
#     p_row::NamedTuple,
#     w::Weather{455},
#     when::Vector{Int},
#     type::Symbol
# )
    temp_data = tempdata()
    rain_data = raindata()
    wind_data = winddata()
    when = collect_days()

    steps = 618
    iday = 115
    sampled_blocks = 100

    model1 = init_spatialrust(;
        # w;
        steps = steps,
        start_days_at = iday, 
        common_map = type,
        rain_data = rain_data,
        wind_data = wind_data,
        temp_data = temp_data,
        ini_rusts = 0.0,
        prune_sch = [15,166,-1],
        inspect_period = 460,
        fungicide_sch = Int[],
        target_shade = [0.15, 0.2, -1],
        shade_g_rate = 0.008,
        p_row...
    )
    P1a, P12a = abc_att_run!(model1, steps, iday)

    model2 = init_spatialrust(;
        # w;
        steps = steps,
        start_days_at = iday, 
        common_map = type,
        rain_data = rain_data,
        wind_data = wind_data,
        temp_data = temp_data,
        ini_rusts = 0.02,
        prune_sch = [15, 166, -1],
        inspect_period = 460,
        fungicide_sch = Int[],
        target_shade = [0.15, 0.2, -1],
        shade_g_rate = 0.008,
        p_row...
    )
    setup_plant_sampling!(model2, 9, sampled_blocks)
    per_age, prod_clr_cor, areas, nls, P1o, P12o, incidiff, anyrusts = abc_run_2y!(model2, steps, when)
    per_age[!, :plot] .= ifelse(type == :fullsun, :sun, :shade)
    globdf = DataFrame(
        P1att = P1a,
        P12att = P12a,
        P1obs = P1o,
        P12obs = P12o,
        cor = prod_clr_cor,
        areas = areas,
        nls = nls,
        incidiff = incidiff,
        anyrusts = anyrusts,
        plot = ifelse(type == :fullsun, :sun, :shade)
    )

    return per_age, globdf
end

function abc_att_run!(model::SpatialRustABM, n::Int, d::Int)
    P1 = 0.0
    P12 = 0.0
    s = d
    steps = d + n
    while s < steps
        if s == 366
            P1 = model.current.prod
        elseif s == 731
            P12 = model.current.prod
        end
        step!(model, dummystep, step_model!, 1)
        s += 1
    end
    return P1, P12
end

function abc_run_2y!(model::SpatialRustABM, n::Int, when_weekly::Vector{Int} = Int[])

    ncofs = model.mngpars.n_cofs
    cycledays = DataFrame(
        day = [17, 77, 140, 259, 287, 315, 343, 372, 399, 427],
        cycle = [[1], [2], [3], [4], [4,5], [5,6], [6,7], [7,8], [8,9], [9]]
    )

    per_age = DataFrame(
        dayn = Int[], age = Int[], cycle = Int[],
        area = Float64[], spore = Float64[],
        nl = Float64[], occup = Float64[],
        )
    allowmissing!(per_age, Not([:dayn, :age, :cycle]))
    prod_clr_df = DataFrame()
    prod_clr_cor = 0.0
    areas = 0.0
    nls = 0.0
    P1 = 0.0
    P12 = 0.0
    incid_comm = 0.0
    incid_harv = 0.0
    # incids2 = zeros(2)

    for c in eachcol(per_age)
        sizehint!(c, 110)
    end

    allcofs = model.agents

    s = 0
    while s < n && model.current.withinbounds
        cycleday = filter(:day => ==(s), cycledays)
        if !isempty(cycleday)
            newcycles = cycleday[1, :cycle]
            cycle_sentinels(model, minimum(newcycles) - 1, maximum(newcycles))
            if s ∈ when_weekly
                cycle_n, max_age, week8 = current_cycle_ages(s)
                let df = get_weekly_data(model, cycle_n, max_age, week8)
                    df[!, :dayn] .= s
                    append!(per_age, df)
                end
            end
        elseif s ∈ when_weekly
            cycle_n, max_age, week8 = current_cycle_ages(s)
            let df = get_weekly_data(model, cycle_n, max_age, week8)
                df[!, :dayn] .= s
                append!(per_age, df)
            end
        elseif s == 21
            get_prod_df!(prod_clr_df, allcofs)
            incid_comm = sum(map(c -> c.n_lesions > 0 ||c.exh_countdown > 0, allcofs)) / ncofs
            # incid_comm = sum(getproperty.(model.agents, :n_lesions) .> 0) / ncofs
        elseif s == 135
            areas, nls = get_areas_nl(allcofs)
            
            # if length(model.rusts) < 3 && sum(map(c -> c.exh_countdown > 0, model.agents)) / ncofs < 0.1
            if sum(map(c -> c.n_lesions > 0, allcofs)) < 3 && sum(map(c -> c.exh_countdown > 0, allcofs)) / ncofs < 0.1
                prod_clr_cor = missing
            else
                prod_clr_cor = prod_clr_corr(prod_clr_df, allcofs)
            end
        elseif s == 251
            P1 = model.current.prod
            # incid_harv = (sum(map(c -> c.exh_countdown > 0, model.agents)) + sum(getproperty.(model.agents, :n_lesions) .> 0)) / ncofs
            incid_harv = (sum(map(c -> c.exh_countdown > 0 || c.n_lesions > 0, allcofs))) /ncofs 
            # + sum(map(c -> c.n_lesions > 0, allcofs))) / ncofs
            # elseif s == 501
        #     incids2[1] = sum(getproperty.(model.agents, :n_lesions) .> 0) / ncofs
        elseif s == 617
            P12 = model.current.prod
            # incids2[2] = sum(getproperty.(model.agents, :n_lesions) .> 0) / ncofs
        end
        step!(model, dummystep, step_model!, 1)
        s += 1
    end

    if !model.current.withinbounds
        areas = missing
        nls = missing
        prod_clr_cor = missing
        Ps = [missing, missing]
        incid_harv = missing
        per_age = pull_empdates()
        per_age[!, :area] .= missing
        per_age[!, :spore] .= missing
        per_age[!, :nl] .= missing
        per_age[!, :occup] .= missing
    end

    return per_age, prod_clr_cor, areas, nls, P1, P12, (incid_harv - incid_comm), sum(map(c -> c.n_lesions > 0, allcofs)) > 0 #, sum(map(c -> c.exh_countdown > 0, allcofs))
end

n_infected(cofs::Vector{Coffee}) = map(c -> c.n_lesions > 0, cofs)
infected(c::Coffee) = c.n_lesions > 0

n_lesions(c::Coffee) = c.n_lesions


function cat_dfs(Ti::Tuple{DataFrame, DataFrame}, Tj::Tuple{DataFrame, DataFrame})
    return vcat(Ti[1], Tj[1]), vcat(Ti[2], Tj[2])
end

## Get cycle #, max relevant age

function current_cycle_ages(today::Int)
    if today < 200
        if today == 23
            return [1], 0, false
        elseif today == 29
            return [1], 1, false
        elseif today == 36
            return [1], 2, false
        elseif today == 42
            return [1], 3, false
        elseif today == 50
            return [1], 4, false
        elseif today == 57
            return [1], 5, false
        elseif today == 64
            return [1], 6, false
        elseif today == 71
            return [1], 7, true
        elseif today == 84
            return [2], 0, false
        elseif today == 91
            return [2], 1, false
        elseif today == 98
            return [2], 2, false
        elseif today == 105
            return [2], 3, false
        elseif today == 112
            return [2], 4, false
        elseif today == 119
            return [2], 5, false
        elseif today == 126
            return [2], 6, false
        elseif today == 133
            return [2], 7, true
        elseif today == 147
            return [3], 0, false
        elseif today == 154
            return [3], 1, false
        elseif today == 161
            return [3], 2, false
        elseif today == 168
            return [3], 3, false
        elseif today == 175
            return [3], 4, false
        elseif today == 182
            return [3], 5, false
        elseif today == 189
            return [3], 6, false
        elseif today == 196
            return [3], 7, true
        end
    else
        if today == 266
            return [4], 0, false
        elseif today == 273
            return [4], 1, false
        elseif today == 280
            return [4], 2, false
        elseif today == 287
            return [4], 3, false
        elseif today == 294
            return [4, 5], 4, false
        elseif today == 301
            return [4, 5], 5, false
        elseif today == 308
            return [4, 5], 6, false
        elseif today == 315
            return [4, 5], 7, true
        elseif today == 322
            return [5, 6], 3, false
        elseif today == 329
            return [5, 6], 4, false
        elseif today == 336
            return [5, 6], 5, false
        elseif today == 343
            return [5, 6], 6, true
        elseif today == 350
            return [6, 7], 4, false
        elseif today == 357
            return [6, 7], 5, false
        elseif today == 364
            return [6, 7], 6, false
        elseif today == 372
            return [6, 7], 7, true
        elseif today == 378
            return [7, 8], 4, false
        elseif today == 385
            return [7, 8], 5, false
        elseif today == 392
            return [7, 8], 6, false
        elseif today == 399
            return [7, 8], 6, true
        elseif today == 406
            return [8, 9], 4, false
        elseif today == 413
            return [8, 9], 5, false
        elseif today == 420
            return [8, 9], 6, false
        elseif today == 427
            return [8, 9], 6, true
        elseif today == 434
            return [9, 10], 4, false
        elseif today == 442
            return [9, 10], 5, false
        elseif today == 448
            return [9, 10], 5, false
        elseif today == 455
            return [9, 10], 6, true
        end
    end
end 


function dummy_abc()
    when_rust = Vector(Arrow.Table("data/exp_pro/input/whentocollect.arrow")[1])
    when_2017 = filter(d -> d < 200, when_rust)
    when_2018 = filter(d -> d > 200, when_rust)
    w_table = Arrow.Table("data/exp_pro/input/weather.arrow")
    temp_data = Tuple(w_table[2])
    rain_data = Tuple(w_table[3])
    wind_data = Tuple(w_table[4]);

    tdf = DataFrame(
        p_row = [1,2, 3], 
        max_inf = [0.5,0.4, 0.044], 
        host_spo_inh = [5.0, 4.0, 13.11], 
        opt_g_temp = [23.0, 23.0, 21.93], 
        max_g_temp = [31.0, 31.0, 29.74], 
        spore_pct = [0.5, 0.5, 0.875], 
        rust_paras = [0.05, 0.3, 0.691], 
        exh_threshold = [0.01,1.5, 1.211], 
        rain_distance = [5.0, 5.0, 9.282], 
        tree_block = [0.5, 0.5, 0.291], 
        wind_distance = [15.0, 15.0, 11.595], 
        shade_block = [0.5,0.5, 0.316], 
        lesion_survive =[0.5, 0.5, 0.533],
        rust_gr = [0.15, 0.9, 0.179],
        rep_gro = [2.0, 3.0, 1.062],
        shade_g_rate = [0.008, 0.008, 0.008],
        target_shade = [[0.15, 0.25], [0.15, 0.25], [0.15, 0.25]]
    )

    touts = map(p -> sim_abc(p, temp_data, rain_data, wind_data, when_2017, when_2018), Tables.namedtupleiterator(tdf))
end
