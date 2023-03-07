# Simulations to run the Approx Bayesian Computation approach

export sim_abc, cat_dfs

# using DataFramesMeta, NaNStatistics
# using NaNStatistics
using StatsBase: corspearman

include(srcdir("ABC","Metrics.jl"))
include(srcdir("ABC","PrepforABC.jl"))
include(srcdir("ABC","Sentinels.jl"))

function sim_abc(p_row::DataFrameRow,
    temp_data::NTuple{455, Float64},
    rain_data::NTuple{455, Bool},
    wind_data::NTuple{455, Bool},
    when_2017::Vector{Int},
    when_2018::Vector{Int}
    )

    sun_per_age_df, sun_exh_perc, sun_incid, sun_prod_clr_cor, sun_anyrusts = simulate_plots(
        p_row, temp_data, rain_data, wind_data, when_2017, when_2018, :fullsun
    )

    shade_per_age_df, shade_exh_perc, shade_incid, shade_prod_clr_cor, shade_anyrusts = simulate_plots(
        p_row, temp_data, rain_data, wind_data, when_2017, when_2018, :regshaded
    )

    # if p_row[:p_row] % 200 == 0
    #     println("Row $(p_row[:p_row])")
    #     println("Time $simtime")
    #     println("")
    #     flush(stdout)
    # end

    per_age_df = vcat(sun_per_age_df, shade_per_age_df, source = :plot => [:sun, :shade])
    # if isempty(per_age_df)
    #     push!(per_age_df, [-1; -1; fill(missing, 4); :none])
    # end
    per_age_df[!, :p_row] .= p_row[:p_row]
    qual_patterns_df = DataFrame(
        p_row = fill(p_row[:p_row], 2),
        plot = [:sun, :shade],
        exh = [sun_exh_perc, shade_exh_perc],
        incid = [sun_incid, shade_incid],
        prod_clr = [sun_prod_clr_cor, shade_prod_clr_cor],
        frusts = [sun_anyrusts, shade_anyrusts]
        )

    return per_age_df, qual_patterns_df
end

function simulate_plots(p_row::DataFrameRow,
        temp_data::NTuple{455, Float64},
        rain_data::NTuple{455, Bool},
        wind_data::NTuple{455, Bool},
        when_2017::Vector{Int},
        when_2018::Vector{Int},
        type::Symbol)

    steps_2017 = 231
    steps_2018 = 455
    sampled_blocks = 100


    model1 = init_spatialrust(
        steps = steps_2017,
        start_days_at = 115, 
        common_map = type,
        rain_data = rain_data,
        wind_data = wind_data,
        temp_data = temp_data,
        ini_rusts = 0.02,
        target_shade = 0.15,
        shade_g_rate = 0.008,
        fungicide_sch = Int[];
        p_row[2:end]...

        # temp_cooling = p_row[:temp_cooling],
        # light_inh = p_row[:light_inh],
        # rain_washoff = p_row[:rain_washoff],
        )


    setup_plant_sampling!(model1, 3, sampled_blocks)

    per_age_df, exh_perc, incid, prod_clr_cor = abc_run_2017!(model1, step_model!, steps_2017, when_2017)

    model2 = init_spatialrust(
        steps = steps_2018,
        start_days_at = 115, 
        common_map = type,
        rain_data = rain_data,
        wind_data = wind_data,
        temp_data = temp_data,
        ini_rusts = 0.02,
        target_shade = 0.15,
        shade_g_rate = 0.008,
        fungicide_sch = Int[];
        p_row[2:end]...

        # temp_cooling = p_row[:temp_cooling],
        # light_inh = p_row[:light_inh],
        # rain_washoff = p_row[:rain_washoff],
        )

    setup_plant_sampling!(model2, 6, div(sampled_blocks, 2)) # sampling groups in 2nd half were 1/2 and overlapped with each other

    per_age_df2, anyrusts = abc_run_2018!(model2, step_model!, steps_2018, when_2018)
    
    append!(per_age_df, per_age_df2)
    # per_age_df[!, :p_row] .= p_row[:p_row]
    # per_age_df[!, :shading] .= type

    return per_age_df, exh_perc, incid, prod_clr_cor, anyrusts
end

## Custom runs

function abc_run_2017!(model::SpatialRustABM,
    model_step!,
    n::Int,
    when_weekly::Vector{Int} = [])

    cycledays = DataFrame(day = [17, 77, 140], cycle = [1, 2, 3])

    per_age = DataFrame(
        dayn = Int[], age = Int[], cycle = Int[],
        area = Float64[], spore = Float64[],
        nl = Float64[], occup = Float64[],
        ar_sum = Float64[], ar_mn = Float64[], nl_mn = Float64[]
    )
    allowmissing!(per_age, Not([:dayn, :age, :cycle]))
    prod_clr_df = DataFrame()

    for c in eachcol(per_age)
        sizehint!(c, 110)
    end

    s = 0
    while Agents.until(s, n, model)
        cycleday = filter(:day => ==(s), cycledays)
        if !isempty(cycleday)
            newcycle = cycleday[1, :cycle]
            cycle_sentinels(model, newcycle - 1, newcycle)
        elseif s ∈ when_weekly
            cycle_n, max_age, week8 = current_cycle_ages_2017(s)
            let df = get_weekly_data(model, cycle_n, max_age, week8)
                df[!, :dayn] .= s
                append!(per_age, df)
            end
        end
        if s == 25
            get_prod_df!(prod_clr_df, model)
        end
        step!(model, dummystep, model_step!, 1)
        s += 1
    end
    if s ∈ when_weekly
        cycle_n, max_age, week8 = current_cycle_ages_2017(s)
        if week1
            cycle_sentinels(model, minimum(cycle_n) - 1, maximum(cycle_n))
        end
        let df = get_weekly_data(model, cycle_n, max_age, week8)
            df[!, :dayn] .= s
            append!(per_age, df)
        end
    end

    exh_and_totinc = exh_incid(model)
    exh_incid_percent = exh_and_totinc ./ length(model.agents)

    if length(model.rusts) < 3
        prod_clr_cor = missing
    else
        add_clr_areas!(prod_clr_df, model)
        filter!(:clr_area => >(0.0), prod_clr_df)
        if isempty(prod_clr_df)
            prod_clr_cor = missing
        else
            prod_clr_cor = corspearman(prod_clr_df[!, :FtL], prod_clr_df[!, :clr_area])
        end
    end
    println(prod_clr_cor)

    return per_age, exh_incid_percent..., prod_clr_cor
end

function abc_run_2018!(model::SpatialRustABM,
    model_step!,
    n::Int,
    when_weekly::Vector{Int} = [])

    cycledays = DataFrame(
        day = [259, 287, 315, 343, 372, 399, 427],
        cycle = [[4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10]]
    )

    per_age = DataFrame(
        dayn = Int[], age = Int[], cycle = Int[],
        area = Float64[], spore = Float64[],
        nl = Float64[], occup = Float64[],
        ar_sum = Float64[], ar_mn = Float64[], nl_mn = Float64[]
    )
    allowmissing!(per_age, Not([:dayn, :age, :cycle]))

    for c in eachcol(per_age)
        sizehint!(c, 170)
    end

    s = 0
    while Agents.until(s, n, model)
        cycleday = filter(:day => ==(s), cycledays)
        if !isempty(cycleday)
            newcycles = cycleday[1, :cycle]
            cycle_sentinels(model, minimum(newcycles) - 1, maximum(newcycles))
        end
        if s ∈ when_weekly
            cycle_n, max_age, week8 = current_cycle_ages_2018(s)
            let df = get_weekly_data(model, cycle_n, max_age, week8)
                df[!, :dayn] .= s
                append!(per_age, df)
            end
        end
        step!(model, dummystep, model_step!, 1)
        s += 1
    end
    if s ∈ when_weekly
        cycle_n, max_age, week8 = current_cycle_ages_2018(s)
        let df = get_weekly_data(model, cycle_n, max_age, week8)
            df[!, :dayn] .= s
            append!(per_age, df)
        end
    end

    return per_age, (length(model.rusts) > 0)
end

function cat_dfs(Ti::Tuple{DataFrame, DataFrame}, Tj::Tuple{DataFrame, DataFrame})
    return vcat(Ti[1], Tj[1]), vcat(Ti[2], Tj[2])
end

## Get cycle #, max relevant age

function current_cycle_ages_2017(today::Int)
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
end 

function current_cycle_ages_2018(today::Int)
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

# function get_2017_sample_cycle(today::Int)
#     if today < 77
#         return [1]
#     elseif today < 140
#         return [2]
#     else
#         return [3]
#     end
# end

# function get_2018_sample_cycle(today::Int)
#     if today < 288
#         return [4]
#     elseif today < 316
#         return [4, 5]
#     elseif today < 344
#         return [5, 6]
#     elseif today < 373
#         return [6, 7]
#     elseif today < 400
#         return [7, 8]
#     elseif today < 428
#         return [8, 9]
#     else
#         return [9, 10]
#     end
# end

## Selecting sampled locations for each cycle

# function custom_sampling_first!(model::SpatialRustABM, percent::Float64)
#     let n_persample = floor(Int, length(model.current.coffee_ids) * percent),
#     first_ids = sample(model.rng, filter(id -> all(5 .< model[id].pos .<= 95),
#         model.current.coffee_ids), n_persample, replace = false),
#     sampled_coffees = hcat(first_ids, zeros(Int, n_persample, 3)) # 1 half requires 3 neighs, 2 half reqs 5
#         for (i, id) in enumerate(first_ids)
#             push!(model[id].sample_cycle, 1)
#             c = 2
#             for neigh in select_s_neighbors(model, sampled_coffees, id)
#                 push!(model[neigh].sample_cycle, c)
#                 sampled_coffees[i, c] = neigh
#                 c += 1
#                 c > 4 && break # break if # of selected neighs is greater than 4
#             end
#             if c < 4 # if # of selected neighs was not enough, relax requirements
#                 for add_neigh in complete_s_neighbors(model, sampled_coffees, id, i, c)
#                     push!(model[add_neigh].sample_cycle, c)
#                     sampled_coffees[i, c] = add_neigh
#                     c += 1
#                     c > 4 && break
#                 end
#             end
#         end
#     end
# end


# function custom_sampling_second!(model::SpatialRustABM, percent::Float64)
#     let n_persample = floor(Int, length(model.current.coffee_ids) * percent),
#     first_ids = sample(model.rng, filter(id -> all(5 .< model[id].pos .<= 95),
#         model.current.coffee_ids), n_persample, replace = false),
#     sampled_coffees = hcat(first_ids, zeros(Int, n_persample, 5))
#         for (i, id) in enumerate(first_ids)
#             push!(model[id].sample_cycle, 5) # second half starts with cycle 5
#             c = 6
#             for neigh in select_s_neighbors(model, sampled_coffees, id)
#                 push!(model[neigh].sample_cycle, c)
#                 sampled_coffees[i, (c - 4)] = neigh
#                 c += 1
#                 c > 10 && break
#             end
#             if c < 10
#                 for add_neigh in complete_s_neighbors(model, sampled_coffees, id, i, (c - 4))
#                     push!(model[add_neigh].sample_cycle, c)
#                     sampled_coffees[i, (c - 4)] = add_neigh
#                     c += 1
#                     c > 10 && break
#                 end
#             end
#         end
#     end
# end

# function select_s_neighbors(model::SpatialRustABM, sampled_coffees::Array{Int,2}, c_id::Int)::Vector{Int}
#     return shuffle(model.rng, collect(Iterators.filter(x -> model[x] isa Coffee && x ∉ sampled_coffees,
#         nearby_ids(model[c_id], model, 2))))
# end

# function complete_s_neighbors(model::SpatialRustABM, sampled_coffees::Array{Int,2}, c_id::Int, i::Int, c::Int)
#     return shuffle(model.rng, collect(Iterators.filter(x -> model[x] isa Coffee &&
#         x ∉ sampled_coffees[i,:] && x ∉ sampled_coffees[:,c], nearby_ids(model[c_id], model, 2))))
# end

# ## Extracting prod data from per_cycle

# function extract_prod(cdf::DataFrame)::DataFrame
#     return leftjoin(DataFrame(
#         tick = [17, 77, 140, 203, 287, 315, 343, 372, 399, 427], cycle = 1:10
#         ),
#     cdf[!, [:tick, :cycle, :coffee_production]],
#     on = [:tick, :cycle])
# end

## DataFrame post processing

# function dewrinkle(rust_df)

#     per_age_df = reduce(vcat, rust_df.d_per_ages)
#     per_cycle_df = reduce(vcat, rust_df.d_per_cycles)

#     return per_age_df, per_cycle_df
# end

## ABCOuts Struct

# struct ABCOuts
#     per_age::DataFrame
#     per_cycle::DataFrame
#     prod_df::DataFrame
# end

## Custom cat for ABCOuts struct

# function struct_cat(s1::ABCOuts, s2::ABCOuts)
#     return ABCOuts(
#     vcat(s1.per_age, s2.per_age),
#     vcat(s1.per_cycle, s2.per_cycle),
#     vcat(s1.prod_df, s2.prod_df)
#     )
# end
# Figuring out how to concatenate multiple df outputs
#
# tinput = DataFrame(one=collect(1:10), two=collect(2:2:20))
#
# struct ttTDFstruct
#     df1::DataFrame
#     df2::DataFrame
#     x1::Vector{Int}
#     x2::Vector{Int}
# end
#
# function tstrdf(row::DataFrameRow, x::Int)
#     return ttTDFstruct(
#         DataFrame(aa = fill(row[1],3), ab = fill(row[1] * x, 3)),
#         DataFrame(ba = fill(row[2],5), bb = fill(row[2] * x, 5)),
#         [x],
#         [x ^ 2])
# end
#
# tmystr = tstrdf(tinput[1,:], 2)
#
# ttoutput = map(x -> tstrdf(x, 2), eachrow(tinput))
#
# function tassoc(st1::ttTDFstruct, st2::ttTDFstruct)
#     return ttTDFstruct(
#     vcat(st1.df1, st2.df1),
#     vcat(st1.df2, st2.df2),
#     vcat(st1.x1, st2.x1),
#     vcat(st1.x2, st2.x2)
#     )
# end
#
# tfinal = reduce(tassoc, ttoutput)
#
# #
# #
# # function tdfindf(row::DataFrameRow, x::Int)
# #     df1 = DataFrame(a = DataFrame(aa = fill(row[1],3), ab = fill(row[1] * x, 3)),
# #         b = DataFrame(ba = fill(row[2],5), bb = fill(row[2] * x, 5)) )
# #
# #     return df1
# # end
# #
# # tdf = tdfindf(tinput[1,:],2)
# #
# # function tfn(row::DataFrameRow, x::Int)
# #     df1 = DataFrame(a = DataFrame(aa = fill(row[1],3), ab = fill(row[1] * x, 3)),
# #         b = DataFrame(ba = fill(row[2],5), bb = fill(row[2] * x, 5)) )
# #
# #     df2 = DataFrame(hi = [row[1], row[2]], hello = [row[2], row[1]])
# #     return df1, df2
# # end
# #
# # function tfn(row::DataFrameRow, x::Int)
# #     df1 = DataFrame(aa = fill(row[1],3), ab = fill(row[1] * x, 3))
# #     df2 = DataFrame(ba = fill(row[2],5), bb = fill(row[2] * x, 5))
# #
# #     df3 = DataFrame(hi = [row[1], row[2]], hello = [row[2], row[1]])
# #     return df1, df2, df3
# # end
# #
# # toutput1, toutput2
# #
# # ttoutput = map(x -> tfn(x, 2), eachrow(tinput))
# #
# # typeof(tinput[1,:])
# #
# # function tfn2(tout::Vector)
# #     df1 = reduce(vcat, tup[1].a for tup in tout)
# #     df2 = reduce(vcat, tup[1].b for tup in tout)
# #     df3 = reduce(vcat, tup[2] for tup in tout)
# #
# #     return df1, df2, df3
# # end


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
        target_shade = [0.15, 0.15, 0.15]
    )

    touts = map(p -> sim_abc(p, temp_data, rain_data, wind_data, when_2017, when_2018), eachrow(tdf))
end