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

    sun_per_age_df, sun_globs_df, sun_cor_df = simulate_single_plot(p_row, :fullsun)

    shade_per_age_df, shade_globs_df, shade_cor_df = simulate_single_plot(p_row, :regshaded)

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

    if any(ismissing.(sun_cor_df[!, 1])) || any(ismissing.(shade_cor_df[!, 1]))
        prod_clr_cor = missing
    else
        append!(sun_cor_df, shade_cor_df)
        if isempty(sun_cor_df)
            prod_clr_cor = missing
        else
            prod_clr_cor = corkendall(sun_cor_df[!, :FtL], sun_cor_df[!, :clr_cat])
        end
    end

    per_age_df = vcat(sun_per_age_df, shade_per_age_df)
    per_age_df[!, :p_row] .= p_row[:p_row]
    globs_df = vcat(sun_globs_df, shade_globs_df)
    globs_df[!, :cor] .= prod_clr_cor
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

    steps = 616
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
        inspect_period = steps,
        fungicide_sch = Int[],
        target_shade = [0.15, 0.2, -1],
        shade_g_rate = 0.008,
        p_row...
    )
    P1a, P12a = abc_att_run!(model1)

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
        inspect_period = steps,
        fungicide_sch = Int[],
        target_shade = [0.15, 0.2, -1],
        shade_g_rate = 0.008,
        p_row...
    )
    setup_plant_sampling!(model2, 9, sampled_blocks)
    per_age, prod_clr_df, areas, nls, P1o, P12o, incidiff, rusts, active = abc_run_2y!(model2, steps, when)
    plot = ifelse(type == :fullsun, :sun, :shade)
    per_age[!, :plot] .= plot
    globdf = DataFrame(
        P1att = P1a,
        P12att = P12a,
        P1obs = P1o,
        P12obs = P12o,
        # cor = prod_clr_cor,
        areas = areas,
        nls = nls,
        incidiff = incidiff,
        rusts = rusts,
        active = active,
        plot = plot
    )

    return per_age, globdf, prod_clr_df
end

function abc_att_run!(model::SpatialRustABM)

    step!(model, dummystep, step_model!, 250)
    P1 = model.current.prod
    step!(model, dummystep, step_model!, 365)
    P12 = model.current.prod

    return P1, P12
end

function abc_run_2y!(model::SpatialRustABM, n::Int, when_weekly::Vector{Int} = Int[])

    ncofs = model.mngpars.n_cofs
    allcofs = model.agents

    per_age = DataFrame(
        dayn = Int[], age = Int[], cycle = Int[],
        area = Float64[], spore = Float64[],
        nl = Float64[], occup = Float64[],
        )
    allowmissing!(per_age, Not([:dayn, :age, :cycle]))
    prod_clr_df = DataFrame()
    # prod_clr_cor = 0.0
    areas = 0.0
    nls = 0.0
    incid_comm = 0.0
    incid_harv = 0.0

    for c in eachcol(per_age)
        sizehint!(c, 612)
    end

    step!(model, dummystep, step_model!, 17)
    s = 17
    while s < 456 && model.current.withinbounds
        newcycles = cycledays(s)
        if !isempty(newcycles)
            if s ∈ when_weekly
                cycle_n, max_age, week8 = current_cycle_ages(s)
                let df = get_weekly_data(model, cycle_n, max_age, week8)
                    df[!, :dayn] .= s
                    append!(per_age, df)
                end
            end
            cycle_sentinels(model, minimum(newcycles) - 1, maximum(newcycles))
        elseif s ∈ when_weekly
            cycle_n, max_age, week8 = current_cycle_ages(s)
            let df = get_weekly_data(model, cycle_n, max_age, week8)
                df[!, :dayn] .= s
                append!(per_age, df)
            end
        elseif s == 20
            get_prod_df!(prod_clr_df, allcofs)
            incid_comm = sum(map(c -> c.n_lesions > 0 ||c.exh_countdown > 0, allcofs)) / ncofs
        elseif s == 185
            areas, nls = get_areas_nl(allcofs)
            
            if sum(map(c -> c.n_lesions > 0, allcofs)) < 3 && sum(map(c -> c.exh_countdown > 0, allcofs)) / ncofs < 0.1
                prod_clr_df = DataFrame(FtL = Float64[], clr_cat = Int[])
            else
                clr_categories!(prod_clr_df, allcofs)
            end
            incid_harv = (sum(map(c -> c.exh_countdown > 0 || c.n_lesions > 0, allcofs))) /ncofs
        end
        step!(model, dummystep, step_model!, 1)
        s += 1
    end

    P1 = model.current.prod

    while s < n && model.current.withinbounds
        step!(model, dummystep, step_model!, 1)
        s += 1
    end

    if !model.current.withinbounds
        per_age = pull_empdates()
        per_age[!, :area] .= missing
        per_age[!, :spore] .= missing
        per_age[!, :nl] .= missing
        per_age[!, :occup] .= missing

        return per_age, DataFrame(FtL = missing, clr_cat = missing), missing, missing, missing, missing, missing, missing, missing
    else
        P12 = model.current.prod
        return per_age, prod_clr_df, areas, nls, P1, P12, (incid_harv - incid_comm), sum(map(c -> c.n_lesions > 0, allcofs)), sum(map(c -> c.exh_countdown == 0, allcofs))
    end
end

function cat_dfs(Ti::Tuple{DataFrame, DataFrame}, Tj::Tuple{DataFrame, DataFrame})
    return vcat(Ti[1], Tj[1]), vcat(Ti[2], Tj[2])
end

## Get cycle #, max relevant age

function cycledays(today::Int)
    if today == 17
        return [1]
    elseif today == 77
        return [2]
    elseif today == 140
        return [3]
    elseif today == 259
        return [4]
    elseif today == 287
        return [4,5]
    elseif today == 315
        return [5,6]
    elseif today == 343
        return [6,7]
    elseif today == 372
        return [7,8]
    elseif today == 399
        return [8,9]
    elseif today == 427
        return [9]
    else
        return Int[]
    end
end

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
    # when_rust = Vector(Arrow.Table("data/exp_pro/input/whentocollect.arrow")[1])
    # when_2017 = filter(d -> d < 200, when_rust)
    # when_2018 = filter(d -> d > 200, when_rust)
    # w_table = Arrow.Table("data/exp_pro/input/weather.arrow")
    # temp_data = Tuple(w_table[2])
    # rain_data = Tuple(w_table[3])
    # wind_data = Tuple(w_table[4]);

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

    touts = map(p -> sim_abc(p), Tables.namedtupleiterator(tdf))
end
