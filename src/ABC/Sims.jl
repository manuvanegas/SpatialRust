# Simulations to run the Approx Bayesian Computation approach

export sim_abc, cat_dfs, abc_pmap, tempdata, raindata, winddata, collect_days

using StatsBase: corkendall, proportions
using Statistics: quantile
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

function sim_abc(p_row::NamedTuple)

    if p_row[:p_row] % 500 > 496
        GC.gc()
    end

    temp_data = tempdata()
    rain_data = raindata()
    wind_data = winddata()
    rn = p_row[:p_row]

    _, sun_cor_df, sun_globs = simulate_plot(p_row, temp_data, rain_data, wind_data, :fullsun)

    if ismissing(first(sun_globs))

        cyc_df = pull_empdates()
        cyc_df[!, :nlpct] .= missing
        cyc_df[!, :sporepct] .= missing
        cyc_df[!, :latentpct] .= missing
        cyc_df[!, :p_row] .= rn
        # cyc_df = DataFrame()

        # globs_df = DataFrame(#)
        #     # P1att = [missing, missing],
        #     # P12att = [missing, missing],
        #     # P1obs = [missing, missing],
        #     P12loss = [missing, missing],
        #     meandeps = [missing, missing],
        #     meanlatent = [missing, missing],
        #     LP = [missing, missing],
        #     incid = [missing, missing],
        #     rusts = [missing, missing],
        #     # active = [missing, missing],
        #     cor = [missing, missing],
        #     # plot = [:sun, :shade],
        #     p_row = [rn, rn]
        # )
        globs_df = DataFrame(
            p_row = rn,
            P12loss = missing,
            LP = missing,
            incid = missing,
            rusts = missing,
            meandeps = missing,
            meanlatent = missing,
            cor = missing,
        )
    else
        cyc_df, sh_cor_df, sh_globs = simulate_plot(p_row, temp_data, rain_data, wind_data,:regshaded)

        if isempty(cyc_df)
            
            cyc_df = pull_empdates()
            cyc_df[!, :nlpct] .= missing
            cyc_df[!, :sporepct] .= missing
            cyc_df[!, :latentpct] .= missing
            cyc_df[!, :p_row] .= rn
            # cyc_df = DataFrame()

            # globs_df = DataFrame(#)
            #     # P1att = [missing, missing],
            #     # P12att = [missing, missing],
            #     # P1obs = [missing, missing],
            #     P12loss = [missing, missing],
            #     meandeps = [missing, missing],
            #     meanlatent = [missing, missing],
            #     LP = [missing, missing],
            #     incid = [missing, missing],
            #     rusts = [missing, missing],
            #     # active = [missing, missing],
            #     cor = [missing, missing],
            #     # plot = [:sun, :shade],
            #     p_row = [rn, rn]
            # )
            globs_df = DataFrame(
                p_row = rn,
                P12loss = missing,
                LP = missing,
                incid = missing,
                rusts = missing,
                meandeps = missing,
                meanlatent = missing,
                cor = missing,
            )
        else
            cyc_df[!, :p_row] .= rn

            append!(sun_cor_df, sh_cor_df)
            if nrow(sh_cor_df) < 10
                prod_clr_cor = missing
            else
                qs = quantile(sun_cor_df[!, :areas], [0.0,0.2,0.4,0.6,0.8]) # leave 1.0 out so max(areas) doesn't get its own cat
                transform!(sun_cor_df,
                [:exh, :areas] => ByRow((e,a) -> clrcat(e,a,qs)) => :clr_cat
                )
                prod_clr_cor = corkendall(sun_cor_df[!, :FtL], sun_cor_df[!, :clr_cat])
            end

            # if length(unique(cyc_df.dayn)) == 9

            #     predf = DataFrame([sun_globs, sh_globs])
            #     rename!(predf, [:P12loss, :LP, :incid, :rusts, :meandeps, :meanlatent])
            #     globs_df = DataFrame(
            #         P12loss = sum(0.3 .< predf.P12loss .< 0.85),
            #         # LP = mean(predf.LP),
            #         LP = sum(25 .< predf.LP .< 65),
            #         # LP = sum(25 .< mean(predf.LP) .< 65) == 2,
            #         incid = sum(predf.incid .> 0.7),
            #         rusts = sum(predf.rusts .> 10),
            #         meandeps = predf[1, :meandeps] < predf[2, :meandeps],
            #         meanlatent = predf[1, :meanlatent] > predf[2, :meanlatent],
            #         cor = prod_clr_cor > 0.2,
            #         p_row = rn
            #     )
            #     # globs_df = predf
            #     # globs_df[!, :cor] .= prod_clr_cor
            #     # globs_df[!, :plot] .= [:sun, :shade]
            #     # globs_df[!, :p_row] .= rn
            # else
            #     globs_df = DataFrame()
            #     cyc_df = DataFrame()
            # end
            # if length(unique(cyc_df.dayn)) < 9
            #     cyc_df = DataFrame()
            # end
            # if sun_globs[6] < 0.35 && sh_globs[6] < 0.35
            #     println("$rn did it")
            # end

            # predf = DataFrame([sun_globs, sh_globs])
            # rename!(predf, [:P12loss, :LP, :incid, :rusts, :meandeps, :meanlatent])
            # middf = DataFrame(
            #     P12loss = sum(0.3 .< predf.P12loss .< 0.85),
            #     # LP = mean(predf.LP),
            #     LP = sum(25 .< predf.LP .< 65),
            #     # LP = sum(25 .< mean(predf.LP) .< 65) == 2,
            #     incid = sum(predf.incid .> 0.7),
            #     rusts = sum(predf.rusts .> 10),
            #     meandeps = predf[1, :meandeps] < predf[2, :meandeps],
            #     meanlatent = predf[1, :meanlatent] > predf[2, :meanlatent],
            #     cor = prod_clr_cor > 0.2,
            #     p_row = rn
            # )
            # if all(values(middf[1,1:6]) .== [2,2,2,2,true,true])
            #     globs_df = predf
            #     globs_df[!, :cor] .= prod_clr_cor
            #     globs_df[!, :p_row] .= rn
            # else
            #     globs_df = DataFrame()
            # end

            predf = DataFrame([sun_globs, sh_globs])
            globs_df = DataFrame(
                p_row = rn,
                P12loss = [predf[!, 1]],
                LP = [predf[!, 2]],
                incid = [predf[!, 3]],
                rusts = [predf[!, 4]],
                meandeps = predf[1, 5] - predf[2, 5],
                meanlatent = predf[1, 6] - predf[2, 6],
                cor = prod_clr_cor,
            )
        end
    end

    return cyc_df, globs_df
end

function simulate_plot(
    p_row::NamedTuple,
    temp_data::Vector{Float64},
    rain_data::Vector{Bool},
    wind_data::Vector{Bool},
    type::Symbol
)

    steps = 615
    iday = 115
    sampled_blocks = 125

    model1 = init_spatialrust(;
        steps = steps,
        start_days_at = iday, 
        common_map = type,
        rain_data = rain_data,
        wind_data = wind_data,
        temp_data = temp_data,
        # ini_rusts = 0.0,
        p_rusts = 0.0,
        prune_sch = [15,166,-1],
        inspect_period = steps,
        fungicide_sch = Int[],
        post_prune = [0.15, 0.2, -1],
        shade_g_rate = 0.008,
        shade_d = 6,
        barriers = (0,0),
        p_row...
    )
    P12a = abc_att_run!(model1)

    model2 = init_spatialrust(;
        steps = steps,
        start_days_at = iday, 
        common_map = type,
        rain_data = rain_data,
        wind_data = wind_data,
        temp_data = temp_data,
        # ini_rusts = 0.02,
        p_rusts = 0.02,
        prune_sch = [15, 166, -1],
        inspect_period = steps,
        fungicide_sch = Int[],
        post_prune = [0.15, 0.2, -1],
        shade_g_rate = 0.008,
        shade_d = 6,
        barriers = (0,0),
        p_row...
    )
    setup_plant_sampling!(model2, 9, sampled_blocks)
    if type == :regshaded
        cyc_df, prod_clr_df, P12o, LP, incid, rusts, meandeps, meanlatent = abc_run_shade!(model2)
    else
        cyc_df, prod_clr_df, P12o, LP, incid, rusts, meandeps, meanlatent = abc_run_sun!(model2)
    end

    P12loss = 1.0 - (P12o / P12a)

    return cyc_df, prod_clr_df, (P12loss, LP, incid, rusts, meandeps, meanlatent)
end

function abc_att_run!(model::SpatialRustABM)

    # step_n!(model, 250)
    # P1 = model.current.prod
    # step_n!(model, 365)
    step_n!(model, 615)
    P12 = model.current.prod

    return P12
end

function abc_run_sun!(model::SpatialRustABM)
    ncofs = model.mngpars.n_cofs
    allcofs = model.agents
    prod_clr_df = DataFrame()
    les_df = DataFrame(latent = Float64[], nl = Float64[], deps = Float64[], lp = Int[])

    s = step_while!(model, 0, 20)
    get_prod_df!(prod_clr_df, allcofs)

    s = step_while!(model, 20, 71)
    append!(les_df, latent_and_dep(allcofs))

    s = step_while!(model, s, 133)
    append!(les_df, latent_and_dep(allcofs))

    s = step_while!(model, s, 196)
    append!(les_df, latent_and_dep(allcofs))
    clr_areas!(prod_clr_df, allcofs)
    incid = sum(map(c -> c.n_lesions > 0 ||c.exh_countdown > 0, allcofs)) / ncofs

    s = step_while!(model, s, 615)

    infected = filter(:nl => >(0), les_df)
    if !model.current.withinbounds || isempty(infected)
        return DataFrame(), DataFrame(), missing, missing, missing, missing, missing, missing
    else
        P12 = model.current.prod 

        meandeps = mean(les_df[!, :deps])
        totles = sum(infected[!, :nl])
        meanlatent = sum(infected[!, :latent]) / totles
        LP = sum(infected[!, :lp]) / totles

        return DataFrame(), prod_clr_df, P12, LP, incid, sum(Float64, map(c -> c.n_lesions > 0, allcofs)), meandeps, meanlatent
    end
end

function abc_run_shade!(model::SpatialRustABM)

    ncofs = model.mngpars.n_cofs
    allcofs = model.agents

    cyc_df = DataFrame(
        dayn = Int[], category = Int[],
        nlpct = Float64[], sporepct = Float64[], latentpct = Float64[],
    )
    les_df = DataFrame(latent = Float64[], nl = Float64[], deps = Float64[], lp = Int[])
    prod_clr_df = DataFrame()

    for c in eachcol(cyc_df)
        sizehint!(c, 54)
    end
    allowmissing!(cyc_df, [:nlpct, :sporepct, :latentpct])

    step_n!(model, 17)
    cycle_sentinels(model, 0, 1)
    step_n!(model, 3)
    get_prod_df!(prod_clr_df, allcofs)
    s = step_while!(model, 20, 71)
    append!(cyc_df, cycle_data(model, 1, s))
    append!(les_df, latent_and_dep(allcofs))
    step_n!(model, 6)
    s += 6

    cycle_sentinels(model, 1, 2)
    s = step_while!(model, s, 133)
    append!(cyc_df, cycle_data(model, 2, s))
    append!(les_df, latent_and_dep(allcofs))
    step_n!(model, 7)
    s += 7

    cycle_sentinels(model, 2, 3)
    s = step_while!(model, s, 196)
    append!(cyc_df, cycle_data(model, 3, s))
    append!(les_df, latent_and_dep(allcofs))
    clr_areas!(prod_clr_df, allcofs)
    # areas, deps
    incid = sum(map(c -> c.n_lesions > 0 ||c.exh_countdown > 0, allcofs)) / ncofs

    # s = step_while!(model, s, 250)
    # # prod individual?
    # P1 = model.current.prod #individual?

    s = step_while!(model, s, 259)
    cycle_sentinels(model, 3, 4)
    s = step_while!(model, s, 287)
    cycle_sentinels(model, 3, 5)

    s = step_while!(model, s, 315)
    append!(cyc_df, cycle_data(model, 4, s))
    cycle_sentinels(model, 4, 6)

    s = step_while!(model, s, 343)
    append!(cyc_df, cycle_data(model, 5, s))
    cycle_sentinels(model, 5, 7)

    s = step_while!(model, s, 372)
    append!(cyc_df, cycle_data(model, 6, s))
    cycle_sentinels(model, 6, 8)

    s = step_while!(model, s, 399)
    append!(cyc_df, cycle_data(model, 7, s))
    cycle_sentinels(model, 7, 9)

    s = step_while!(model, s, 427)
    append!(cyc_df, cycle_data(model, 8, s))
    cycle_sentinels(model, 8, 0)

    s = step_while!(model, s, 455)
    append!(cyc_df, cycle_data(model, 9, s))

    s = step_while!(model, s, 615)

    infected = filter(:nl => >(0), les_df)
    if !model.current.withinbounds || isempty(infected)
        return DataFrame(), DataFrame(), missing, missing, missing, missing, missing, missing
    else
        P12 = model.current.prod 
        
        meandeps = mean(les_df[!, :deps])
        totles = sum(infected[!, :nl])
        meanlatent = sum(infected[!, :latent]) / totles
        LP = sum(infected[!, :lp]) / totles

        return cyc_df, prod_clr_df, P12, LP, incid, sum(Float64, map(c -> c.n_lesions > 0, allcofs)), meandeps, meanlatent
    end
end

function cat_dfs(Ti::Tuple{DataFrame, DataFrame}, Tj::Tuple{DataFrame, DataFrame})
    return vcat(Ti[1], Tj[1]), vcat(Ti[2], Tj[2])
end


# function sim_abc(p_row::NamedTuple)

#     if p_row[:p_row] % 500 > 496
#         GC.gc()
#     end

#     sun_per_age_df, sun_cor_df, sun_globs  = simulate_single_plot(p_row, :fullsun)

#     if isempty(sun_per_age_df)

#         per_age_df = pull_empdates()
#         per_age_df[!, :area] .= missing
#         per_age_df[!, :spore] .= missing
#         per_age_df[!, :nl] .= missing
#         per_age_df[!, :occup] .= missing
#         per_age_df[!, :p_row] .= p_row[:p_row]

#         globs_df = DataFrame(
#             P1att = [sun_globs[1], missing],
#             P12att = [missing, missing],
#             P1obs = [missing, missing],
#             P12obs = [missing, missing],
#             areas = [missing, missing],
#             nls = [missing, missing],
#             incidiff = [missing, missing],
#             rusts = [missing, missing],
#             active = [missing, missing],
#             cor = [missing, missing],
#             plot = [:sun, :shade],
#             p_row = [p_row[:p_row], p_row[:p_row]]
#         )

#     else

#         shade_per_age_df, shade_cor_df, shade_globs = simulate_single_plot(p_row, :regshaded)

#         if isempty(shade_per_age_df)

#             per_age_df = pull_empdates()
#             per_age_df[!, :area] .= missing
#             per_age_df[!, :spore] .= missing
#             per_age_df[!, :nl] .= missing
#             per_age_df[!, :occup] .= missing
#             per_age_df[!, :p_row] .= p_row[:p_row]

#             globs_df = DataFrame(
#                 P1att = [sun_globs[1], missing],
#                 P12att = [missing, missing],
#                 P1obs = [missing, missing],
#                 P12obs = [missing, missing],
#                 areas = [missing, missing],
#                 nls = [missing, missing],
#                 incidiff = [missing, missing],
#                 rusts = [missing, missing],
#                 active = [missing, missing],
#                 cor = [missing, missing],
#                 plot = [:sun, :shade],
#                 p_row = [p_row[:p_row], p_row[:p_row]]
#             )
#         else
#             sun_per_age_df[!, :plot] .= :sun
#             shade_per_age_df[!, :plot] .= :shade

#             per_age_df = vcat(sun_per_age_df, shade_per_age_df)
#             per_age_df[!, :p_row] .= p_row[:p_row]

#             if any(ismissing.(sun_cor_df[!, 1])) || any(ismissing.(shade_cor_df[!, 1]))
#                 prod_clr_cor = missing
#             else
#                 append!(sun_cor_df, shade_cor_df)
#                 if isempty(sun_cor_df)
#                     prod_clr_cor = missing
#                 else
#                     prod_clr_cor = corkendall(sun_cor_df[!, :FtL], sun_cor_df[!, :clr_cat])
#                 end
#             end

#             globs_df = DataFrame([sun_globs, shade_globs])
#             rename!(globs_df, [:P1att, :P12att, :P1obs, :P12obs, :areas, :nls, :incidiff, :rusts, :active])            
#             # globs_df = vcat(sun_globs_df, shade_globs_df)
#             globs_df[!, :cor] .= prod_clr_cor
#             globs_df[!, :plot] .= [:sun, :shade]
#             globs_df[!, :p_row] .= p_row[:p_row]
#         end
#     end

#     # sun_per_age_df, sun_globs_df = simulate_single_plot(
#     #     p_row, w, when, :fullsun
#     # )

#     # shade_per_age_df, shade_globs_df = simulate_single_plot(
#     #     p_row, w, when, :regshaded
#     # )

#     return per_age_df, globs_df
# end

# function simulate_single_plot(
#     p_row::NamedTuple,
#     type::Symbol
# )
#     temp_data = tempdata()
#     rain_data = raindata()
#     wind_data = winddata()
#     when = collect_days()

#     steps = 616
#     iday = 115
#     sampled_blocks = 100

#     model1 = init_spatialrust(;
#         steps = steps,
#         start_days_at = iday, 
#         common_map = type,
#         rain_data = rain_data,
#         wind_data = wind_data,
#         temp_data = temp_data,
#         ini_rusts = 0.0,
#         prune_sch = [15,166,-1],
#         inspect_period = steps,
#         fungicide_sch = Int[],
#         post_prune = [0.15, 0.2, -1],
#         shade_g_rate = 0.008,
#         p_row...
#     )
#     P1a, P12a = abc_att_run!(model1)

#     model2 = init_spatialrust(;
#         steps = steps,
#         start_days_at = iday, 
#         common_map = type,
#         rain_data = rain_data,
#         wind_data = wind_data,
#         temp_data = temp_data,
#         ini_rusts = 0.02,
#         prune_sch = [15, 166, -1],
#         inspect_period = steps,
#         fungicide_sch = Int[],
#         post_prune = [0.15, 0.2, -1],
#         shade_g_rate = 0.008,
#         p_row...
#     )
#     setup_plant_sampling!(model2, 9, sampled_blocks)
#     per_age, prod_clr_df, areas, nls, P1o, P12o, incidiff, rusts, active = abc_run_2y!(model2, steps, when)
#     # plot = ifelse(type == :fullsun, :sun, :shade)
#     # per_age[!, :plot] .= plot
#     # globdf = DataFrame(
#     #     P1att = P1a,
#     #     P12att = P12a,
#     #     P1obs = P1o,
#     #     P12obs = P12o,
#     #     # cor = prod_clr_cor,
#     #     areas = areas,
#     #     nls = nls,
#     #     incidiff = incidiff,
#     #     rusts = rusts,
#     #     active = active,
#     #     # plot = plot
#     # )

#     # return per_age, globdf, prod_clr_df
#     return per_age, prod_clr_df, (P1a, P12a, P1o, P12o, areas, nls, incidiff, rusts, active)
# end

# function abc_att_run!(model::SpatialRustABM)

#     step!(model, dummystep, step_model!, 250)
#     P1 = model.current.prod
#     step!(model, dummystep, step_model!, 365)
#     P12 = model.current.prod

#     return P1, P12
# end

# function abc_run_2y!(model::SpatialRustABM, n::Int, when_weekly::Vector{Int} = Int[])

#     ncofs = model.mngpars.n_cofs
#     allcofs = model.agents

#     per_age = DataFrame(
#         dayn = Int[], age = Int[], cycle = Int[],
#         area = Float64[], spore = Float64[],
#         nl = Float64[], occup = Float64[],
#         )
#     allowmissing!(per_age, Not([:dayn, :age, :cycle]))
#     prod_clr_df = DataFrame()
#     # prod_clr_cor = 0.0
#     areas = 0.0
#     nls = 0.0
#     incid_comm = 0.0
#     incid_harv = 0.0

#     for c in eachcol(per_age)
#         sizehint!(c, 612)
#     end

#     step!(model, dummystep, step_model!, 17)
#     s = 17
#     while s < 456 && model.current.withinbounds
#         newcycles = cycledays(s)
#         if !isempty(newcycles)
#             if s ∈ when_weekly
#                 cycle_n, max_age, week8 = current_cycle_ages(s)
#                 let df = get_weekly_data(model, cycle_n, max_age, week8)
#                     df[!, :dayn] .= s
#                     append!(per_age, df)
#                 end
#             end
#             cycle_sentinels(model, minimum(newcycles) - 1, maximum(newcycles))
#         elseif s ∈ when_weekly
#             cycle_n, max_age, week8 = current_cycle_ages(s)
#             let df = get_weekly_data(model, cycle_n, max_age, week8)
#                 df[!, :dayn] .= s
#                 append!(per_age, df)
#             end
#         elseif s == 20
#             get_prod_df!(prod_clr_df, allcofs)
#             incid_comm = sum(map(c -> c.n_lesions > 0 ||c.exh_countdown > 0, allcofs)) / ncofs
#         elseif s == 185
#             areas, nls = get_areas_nl(allcofs)
            
#             if sum(map(c -> c.n_lesions > 0, allcofs)) < 3 && sum(map(c -> c.exh_countdown > 0, allcofs)) / ncofs < 0.1
#                 prod_clr_df = DataFrame(FtL = Float64[], clr_cat = Int[])
#             else
#                 clr_categories!(prod_clr_df, allcofs)
#             end
#             incid_harv = (sum(map(c -> c.exh_countdown > 0 || c.n_lesions > 0, allcofs))) /ncofs
#         end
#         step!(model, dummystep, step_model!, 1)
#         s += 1
#     end

#     P1 = model.current.prod

#     while s < n && model.current.withinbounds
#         step!(model, dummystep, step_model!, 1)
#         s += 1
#     end

#     if !model.current.withinbounds
#         # per_age = pull_empdates()
#         # per_age[!, :area] .= missing
#         # per_age[!, :spore] .= missing
#         # per_age[!, :nl] .= missing
#         # per_age[!, :occup] .= missing
#         per_age = DataFrame()

#         return per_age, DataFrame(FtL = missing, clr_cat = missing), missing, missing, missing, missing, missing, missing, missing
#     else
#         P12 = model.current.prod
#         return per_age, prod_clr_df, areas, nls, P1, P12, (incid_harv - incid_comm), sum(map(c -> c.n_lesions > 0, allcofs)), sum(map(c -> c.exh_countdown == 0, allcofs))
#     end
# end

## Get cycle #, max relevant age

# function cycledays(today::Int)
#     if today == 17
#         return [1]
#     elseif today == 77
#         return [2]
#     elseif today == 140
#         return [3]
#     elseif today == 259
#         return [4]
#     elseif today == 287
#         return [4,5]
#     elseif today == 315
#         return [5,6]
#     elseif today == 343
#         return [6,7]
#     elseif today == 372
#         return [7,8]
#     elseif today == 399
#         return [8,9]
#     elseif today == 427
#         return [9]
#     else
#         return Int[]
#     end
# end

# function current_cycle_ages(today::Int)
#     if today < 200
#         if today == 23
#             return [1], 0, false
#         elseif today == 29
#             return [1], 1, false
#         elseif today == 36
#             return [1], 2, false
#         elseif today == 42
#             return [1], 3, false
#         elseif today == 50
#             return [1], 4, false
#         elseif today == 57
#             return [1], 5, false
#         elseif today == 64
#             return [1], 6, false
#         elseif today == 71
#             return [1], 7, true
#         elseif today == 84
#             return [2], 0, false
#         elseif today == 91
#             return [2], 1, false
#         elseif today == 98
#             return [2], 2, false
#         elseif today == 105
#             return [2], 3, false
#         elseif today == 112
#             return [2], 4, false
#         elseif today == 119
#             return [2], 5, false
#         elseif today == 126
#             return [2], 6, false
#         elseif today == 133
#             return [2], 7, true
#         elseif today == 147
#             return [3], 0, false
#         elseif today == 154
#             return [3], 1, false
#         elseif today == 161
#             return [3], 2, false
#         elseif today == 168
#             return [3], 3, false
#         elseif today == 175
#             return [3], 4, false
#         elseif today == 182
#             return [3], 5, false
#         elseif today == 189
#             return [3], 6, false
#         elseif today == 196
#             return [3], 7, true
#         end
#     else
#         if today == 266
#             return [4], 0, false
#         elseif today == 273
#             return [4], 1, false
#         elseif today == 280
#             return [4], 2, false
#         elseif today == 287
#             return [4], 3, false
#         elseif today == 294
#             return [4, 5], 4, false
#         elseif today == 301
#             return [4, 5], 5, false
#         elseif today == 308
#             return [4, 5], 6, false
#         elseif today == 315
#             return [4, 5], 7, true
#         elseif today == 322
#             return [5, 6], 3, false
#         elseif today == 329
#             return [5, 6], 4, false
#         elseif today == 336
#             return [5, 6], 5, false
#         elseif today == 343
#             return [5, 6], 6, true
#         elseif today == 350
#             return [6, 7], 4, false
#         elseif today == 357
#             return [6, 7], 5, false
#         elseif today == 364
#             return [6, 7], 6, false
#         elseif today == 372
#             return [6, 7], 7, true
#         elseif today == 378
#             return [7, 8], 4, false
#         elseif today == 385
#             return [7, 8], 5, false
#         elseif today == 392
#             return [7, 8], 6, false
#         elseif today == 399
#             return [7, 8], 6, true
#         elseif today == 406
#             return [8, 9], 4, false
#         elseif today == 413
#             return [8, 9], 5, false
#         elseif today == 420
#             return [8, 9], 6, false
#         elseif today == 427
#             return [8, 9], 6, true
#         elseif today == 434
#             return [9], 4, false
#         elseif today == 442
#             return [9], 5, false
#         elseif today == 448
#             return [9], 5, false
#         elseif today == 455
#             return [9], 6, true
#         end
#     end
# end 


# function dummy_abc()
#     # when_rust = Vector(Arrow.Table("data/exp_pro/input/whentocollect.arrow")[1])
#     # when_2017 = filter(d -> d < 200, when_rust)
#     # when_2018 = filter(d -> d > 200, when_rust)
#     # w_table = Arrow.Table("data/exp_pro/input/weather.arrow")
#     # temp_data = Tuple(w_table[2])
#     # rain_data = Tuple(w_table[3])
#     # wind_data = Tuple(w_table[4]);

#     tdf = DataFrame(
#         p_row = [1,2, 3], 
#         max_inf = [0.5,0.4, 0.044], 
#         host_spo_inh = [5.0, 4.0, 13.11], 
#         opt_g_temp = [23.0, 23.0, 21.93], 
#         max_g_temp = [31.0, 31.0, 29.74], 
#         spore_pct = [0.5, 0.5, 0.875], 
#         rust_paras = [0.05, 0.3, 0.691], 
#         exh_threshold = [0.01,1.5, 1.211], 
#         rain_distance = [5.0, 5.0, 9.282], 
#         tree_block = [0.5, 0.5, 0.291], 
#         wind_distance = [15.0, 15.0, 11.595], 
#         shade_block = [0.5,0.5, 0.316], 
#         lesion_survive =[0.5, 0.5, 0.533],
#         rust_gr = [0.15, 0.9, 0.179],
#         rep_gro = [2.0, 3.0, 1.062],
#         shade_g_rate = [0.008, 0.008, 0.008],
#         post_prune = [[0.15, 0.25], [0.15, 0.25], [0.15, 0.25]]
#     )

#     touts = map(p -> sim_abc(p), Tables.namedtupleiterator(tdf))
# end
