# Simulations to run the Approx Bayesian Computation approach

export sim_abc, abc_pmap, tempdata, raindata, winddata

using StatsBase: corkendall
using Statistics: quantile
using Distributed

include(srcdir("ABC","Metrics.jl"))
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

    sun_cor_df, sun_globs = simulate_plot(p_row, temp_data, rain_data, wind_data, :fullsun)

    if ismissing(first(sun_globs))

        globs_df = DataFrame(
            p_row = rn,
            P12loss = missing,
            LP = missing,
            incid = missing,
            rusts = missing,
            meanlats = missing,
            exh = missing,
            depsdiff = missing,
            latentdiff = missing,
            cor = missing,
        )
    else
        sh_cor_df, sh_globs = simulate_plot(p_row, temp_data, rain_data, wind_data,:regshaded)

        if ismissing(first(sh_globs))
            
            globs_df = DataFrame(
                p_row = rn,
                P12loss = missing,
                LP = missing,
                incid = missing,
                rusts = missing,
                meanlats = missing,
                exh = missing,
                depsdiff = missing,
                latentdiff = missing,
                cor = missing,
            )
        else

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

            predf = DataFrame([sun_globs, sh_globs])
            globs_df = DataFrame(
                p_row = rn,
                P12loss = [predf[!, 1]],
                LP = [predf[!, 2]],
                incid = [predf[!, 3]],
                rusts = [predf[!, 4]],
                meanlats = [predf[!, 6]],
                exh = [predf[!, 7]],
                depsdiff = predf[1, 5] - predf[2, 5],
                latentdiff = predf[1, 6] - predf[2, 6],
                cor = prod_clr_cor,
            )
        end
    end

    return globs_df
end

function simulate_plot(
    p_row::NamedTuple,
    temp_data::Vector{Float64},
    rain_data::Vector{Bool},
    wind_data::Vector{Bool},
    type::Symbol
)
    steps = 730
    iday = 0

    model1 = init_spatialrust(;
        steps = steps,
        start_days_at = iday, 
        common_map = type,
        rain_data = copy(rain_data),
        wind_data = copy(wind_data),
        temp_data = copy(temp_data),
        p_rusts = 0.0,
        prune_sch = [15, 166, -1],
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
        rain_data = copy(rain_data),
        wind_data = copy(wind_data),
        temp_data = copy(temp_data),
        p_rusts = 0.01,
        prune_sch = [15, 166, -1],
        inspect_period = steps,
        fungicide_sch = Int[],
        post_prune = [0.15, 0.2, -1],
        shade_g_rate = 0.008,
        shade_d = 6,
        barriers = (0,0),
        p_row...
    )

    prod_clr_df, P12o, LP, incid, rusts, meandeps, meanlatent, exh = abc_obs_run!(model2)

    P12loss = 1.0 - (P12o / P12a)

    return prod_clr_df, (P12loss, LP, incid, rusts, meandeps, meanlatent, exh)
end

function abc_att_run!(model::SpatialRustABM)
    step_n!(model, 730)
    P12 = model.current.prod
    return P12
end

function abc_obs_run!(model::SpatialRustABM)
    ncofs = model.mngpars.n_cofs
    allcofs = model.agents
    prod_clr_df = DataFrame()
    les_df = DataFrame(latent = Float64[], nl = Float64[], deps = Float64[], lp = Int[])

    s = step_while!(model, 0, 135)
    get_prod_df!(prod_clr_df, allcofs)

    s = step_while!(model, s, 195)
    append!(les_df, latent_and_dep(allcofs))

    s = step_while!(model, s, 255)
    append!(les_df, latent_and_dep(allcofs))

    s = step_while!(model, s, 315)
    append!(les_df, latent_and_dep(allcofs))
    clr_areas!(prod_clr_df, allcofs)
    incid = sum(map(c -> c.n_lesions > 0 ||c.exh_countdown > 0, allcofs)) / ncofs

    s = step_while!(model, s, 365)
    exh = sum(map(c -> c.exh_countdown > 0, allcofs)) / ncofs

    s = step_while!(model, s, 730)

    infected = filter(:nl => >(0), les_df)
    if !model.current.withinbounds || isempty(infected)
        return DataFrame(), missing, missing, missing, missing, missing, missing, missing
    else
        P12 = model.current.prod 

        meandeps = mean(les_df[!, :deps])
        totles = sum(infected[!, :nl])
        meanlatent = sum(infected[!, :latent]) / totles
        LP = sum(infected[!, :lp]) / totles

        return prod_clr_df, P12, LP, incid, sum(Float64, map(c -> c.n_lesions > 0, allcofs)), meandeps, meanlatent, exh
    end
end
