# using Agents: init_model_dataframe, until, should_we_collect, collect_model_data!, step!, nearby_ids, ABM
# using StatsBase: sample
# using Random: shuffle

export ABCOuts, sim_abc, custom_sampling!, struct_cat

include(srcdir("ABC","ABCmetrics.jl"))

struct ABCOuts
    per_age::DataFrame
    per_cycle::DataFrame
    prod_df::DataFrame
end

function sim_abc(p_row::DataFrameRow,
    rain_data::Vector{Bool},
    temp_data::Vector{Float64},
    when_rust::Vector{Int},
    when_prod::Vector{Int},
    wind_prob::Float64,
    restart_after::Int = 231#,
    #out_path::String,
    #rust_exp::DataFrame,
    #plant_exp::DataFrame
    )

    rust_df, plant_df = simulate_fullsun(p_row, rain_data, temp_data, when_rust, when_prod, wind_prob, restart_after)

    rust_df.step[end] != 455 && error("last recorded step is $(rust_df.step[end])")

    # calc_diffs(rust_df, plant_df)

    per_age_df, per_cycle_df = dewrinkle(rust_df) # "wrinkles" being the nested DataFrames

    per_age_df.p_row .= p_row[:RowN]
    per_cycle_df.p_row .= p_row[:RowN]
    plant_df.p_row .= p_row[:RowN]
    
    # rename!(plant_df, :c_day => :day)
    plant_df[:, :c_day] .= plant_df.c_day .- 132

    return ABCOuts(per_age_df, per_cycle_df, plant_df)



    # awr(string("/scratch/mvanega1/ABCraw/ages/r" * p_row[:RowN] * ".arrow"), per_age_df)
    # awr(string("/scratch/mvanega1/ABCraw/cycles/r" * p_row[:RowN] * ".arrow"), per_cycle_df)
    # awr(string("/scratch/mvanega1/ABCraw/prod/r" * p_row[:RowN] * ".arrow"), plant_df)

    #return outerjoin(rust_df, plant_df, on = [:step, :cycle])
    #the result of pmap will be a vector of 1-row dataframes
    # return true
end

function simulate_fullsun(p_row::DataFrameRow,
        rain_data::Vector{Bool},
        temp_data::Vector{Float64},
        when_rust::Vector{Int},
        when_prod::Vector{Int},
        wind_prob::Float64,
        restart_after::Int)

    model1 = init_spatialrust(Parameters(
        steps = restart_after,
        start_days_at = 132,
        switch_cycles = when_prod,
        opt_g_temp = p_row[:opt_g_temp],
        spore_pct = p_row[:spore_pct],
        fruit_load = p_row[:fruit_load],
        uv_inact = p_row[:uv_inact],
        rain_washoff = p_row[:rain_washoff],
        rain_distance = p_row[:rain_distance],
        wind_distance = p_row[:wind_distance]),

        create_fullsun_farm_map(),

        Weather(rain_data[1:restart_after], rand(Float64, restart_after) .< wind_prob, temp_data[1:restart_after]))


    custom_sampling!(model1, 0.05, 1)

    rust_df, plant_df = abc_run!(model1, step_model!, restart_after;
        when_rust = when_rust, when_prod = when_prod, rust_data = [d_per_ages, d_per_cycles], prod_data = prod_metrics)

    when_rust2 = filter(x -> x > 0, when_rust .- restart_after)
    when_prod2 = filter(x -> x > 0, when_prod .- restart_after)
    model2 = init_spatialrust(Parameters(
        steps = 455 - restart_after,
        start_days_at = 132 + restart_after,
        switch_cycles = when_prod,
        p_rusts = (model1.current.outpour / length(model1.current.coffee_ids)),
        opt_g_temp = p_row[:opt_g_temp],
        spore_pct = p_row[:spore_pct],
        fruit_load = p_row[:fruit_load],
        uv_inact = p_row[:uv_inact],
        rain_washoff = p_row[:rain_washoff],
        rain_distance = p_row[:rain_distance],
        wind_distance = p_row[:wind_distance]),

        create_fullsun_farm_map(),

        Weather(rain_data[(restart_after + 1):455], rand(Float64, (455 - restart_after)) .< wind_prob, temp_data[(restart_after + 1):455]))

    custom_sampling!(model2, 0.025, 2) # sampling groups in 2nd half were 1/2 and overlapped with each other

    rust_df2, plant_df2 = abc_run!(model2, step_model!, (455 - restart_after);
        when_rust = when_rust, when_prod = when_prod, rust_data = [d_per_ages, d_per_cycles], prod_data = prod_metrics)

    rust_df2.step = rust_df2.step .+ restart_after
    plant_df2.step = plant_df2.step .+ restart_after

    return vcat(rust_df, rust_df2), vcat(plant_df, plant_df2)
end

## selecting sampled locations for each cycle

function custom_sampling!(model::ABM, percent::Float64, half::Int)
    n_persample = floor(Int, length(model.current.coffee_ids) * percent)
    # central_coffees = filter(id -> all(5 .< model[id].pos .<= 95), model.current.coffee_ids)
    first_ids = sample(model.rng, filter(id -> all(5 .< model[id].pos .<= 95), model.current.coffee_ids), n_persample, replace = false)
    sampled_coffees = hcat(first_ids, zeros(Int, n_persample, (3 * half))) # 1 half requires 3 neighs, 2 half reqs 6
    for (i, id) in enumerate(first_ids)
        push!(model[id].sample_cycle, 1)
        c = 2
        for neigh in select_s_neighbors(model, sampled_coffees, id)
            push!(model[neigh].sample_cycle, c)
            sampled_coffees[i, c] = neigh
            c += 1
            c > (3 * half) + 1 && break
        end
        if c < (3 * half) + 1
            for add_neigh in complete_s_neighbors(model, sampled_coffees, id, i, c) #relax requirements
                push!(model[add_neigh].sample_cycle, c)
                sampled_coffees[i, c] = add_neigh
                c += 1
                c > (3 * half) + 1 && break
            end
        end
    end
end

function select_s_neighbors(model::ABM, sampled_coffees::Array{Int,2}, c_id::Int)::Vector{Int}
    return sampled_neighs = shuffle(model.rng, collect(Iterators.filter(x -> model[x] isa Coffee && x ∉ sampled_coffees,
        nearby_ids(model[c_id], model, 2))))
end

function complete_s_neighbors(model::ABM, sampled_coffees::Array{Int,2}, c_id::Int, i::Int, c::Int)
    return shuffle(model.rng, collect(Iterators.filter(x -> model[x] isa Coffee &&
        x ∉ sampled_coffees[i,:] && x ∉ sampled_coffees[:,c], nearby_ids(model[c_id], model, 2))))
end

## custom run

function abc_run!(model::ABM,
    model_step!,
    n;
    when_rust = true,
    when_prod = when_rust,
    rust_data = nothing,
    prod_data = nothing,
    obtainer = identity)

    df_rust = init_model_dataframe(model, rust_data)
    df_prod = init_model_dataframe(model, prod_data)
    for c in eachcol(df_rust)
        sizehint!(c, length(when_rust))
    end
    for c in eachcol(df_prod)
        sizehint!(c, length(when_prod))
    end

    s = 0
    while Agents.until(s, n, model)
        if Agents.should_we_collect(s, model, when_rust)
            collect_model_data!(df_rust, model, rust_data, s; obtainer)
        end
        if Agents.should_we_collect(s, model, when_prod)
            collect_model_data!(df_prod, model, prod_data, s; obtainer)
        end
        step!(model, dummystep, model_step!, 1)
        s += 1
    end
    if Agents.should_we_collect(s, model, when_rust)
        collect_model_data!(df_rust, model, rust_data, s; obtainer)
    end
    if should_we_collect(s, model, when_prod)
        collect_model_data!(df_prod, model, prod_data, s; obtainer)
    end
    return df_rust, df_prod
end

## DataFrame post processing

function calc_diffs(rust_df, plant_df)
    per_age_df, per_cycle_df = dewrinkle(rust_df) # "wrinkles" being the nested DataFrames

    per_age_df.p_row .= p_row[:RowN]
    per_cycle_df.p_row .= p_row[:RowN]
    plant_df.p_row .= p_row[:RowN]
    plant_df.day .= plant_df.day .- 132

    # awr(string("/scratch/mvanega1/ABCraw/ages/r" * p_row[:RowN] * ".arrow"), per_age_df)
    # awr(string("/scratch/mvanega1/ABCraw/cycles/r" * p_row[:RowN] * ".arrow"), per_cycle_df)
    # awr(string("/scratch/mvanega1/ABCraw/prod/r" * p_row[:RowN] * ".arrow"), plant_df)

end

function dewrinkle(rust_df)
    # areas_per_age = reduce(vcat, rust_df.areas_per_age) #age, area, day
    # spores_per_age = reduce(vcat, rust_df.spores_per_age) #age, spores, day
    # outerjoin(areas_per_age, spores_per_age, on = [:day, :age])

    per_age_df = reduce(vcat, rust_df.d_per_ages)
    per_cycle_df = reduce(vcat, rust_df.d_per_cycles)

    per_age_df[:, :day] .= per_age_df.day .- 132
    per_cycle_df[:, :day] .= per_cycle_df.day .- 132

    return per_age_df, per_cycle_df
end

## Custom cat for ABCOuts struct

function struct_cat(s1::ABCOuts, s2::ABCOuts)
    return ABCOuts(
    vcat(s1.per_age, s2.per_age),
    vcat(s1.per_cycle, s2.per_cycle),
    vcat(s1.prod_df, s2.prod_df)
    )
end


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
