# Simulations to run the Approx Bayesian Computation approach

export ABCOuts, sim_abc, struct_cat

# using DataFramesMeta, NaNStatistics
using NaNStatistics

include(srcdir("ABC","Metrics.jl"))

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
    restart_after::Int = 231)

    per_age_df, per_cycle_df, plant_df = simulate_fullsun( #, plant_df
    p_row,
    rain_data,
    temp_data,
    when_rust,
    when_prod,
    wind_prob,
    restart_after)

    # per_age_df, per_cycle_df = dewrinkle(rust_df) # "wrinkles" being the nested DataFrames

    # plant_df = extract_prod(per_cycle_df)
    per_age_df.p_row .= p_row[:RowN]
    per_cycle_df.p_row .= p_row[:RowN]
    plant_df.p_row .= p_row[:RowN]

    return ABCOuts(per_age_df, per_cycle_df, plant_df)#
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
        rust_gr = p_row[:rust_gr],
        cof_gr = p_row[:cof_gr],
        spore_pct = p_row[:spore_pct],
        fruit_load = p_row[:fruit_load],
        uv_inact = p_row[:uv_inact],
        rain_washoff = p_row[:rain_washoff],
        rain_distance = p_row[:rain_distance],
        wind_distance = p_row[:wind_distance],
        exhaustion = p_row[:exhaustion]),

        create_fullsun_farm_map(),

        create_weather(rain_data[1:restart_after], wind_prob, temp_data[1:restart_after], restart_after)
        )


    custom_sampling_first!(model1, 0.05)

    per_age_df, per_cycle_df, plant_df = abc_run!( #, plant_df
        model1, step_model!, restart_after;
        when_rust = when_rust,
        when_prod = when_prod,
        rust_data = [ind_data],
        prod_data = [coffee_prod]
        )

    when_rust2 = filter(x -> x > 0, when_rust .- restart_after)
    when_prod2 = filter(x -> x > 0, when_prod .- restart_after)
    model2 = init_spatialrust(Parameters(
        steps = 455 - restart_after,
        start_days_at = 132 + restart_after,
        switch_cycles = when_prod,
        p_rusts = min((model1.current.outpour / length(model1.current.coffee_ids)), 1.0),
        rust_gr = p_row[:rust_gr],
        spore_pct = p_row[:spore_pct],
        cof_gr = p_row[:cof_gr],
        fruit_load = p_row[:fruit_load],
        uv_inact = p_row[:uv_inact],
        rain_washoff = p_row[:rain_washoff],
        rain_distance = p_row[:rain_distance],
        wind_distance = p_row[:wind_distance],
        exhaustion = p_row[:exhaustion]),

        create_fullsun_farm_map(),

        create_weather(rain_data[(restart_after + 1):455], wind_prob, temp_data[(restart_after + 1):455], (455 - restart_after))
        )

    custom_sampling_second!(model2, 0.025) # sampling groups in 2nd half were 1/2 and overlapped with each other

    per_age_df2, per_cycle_df2, plant_df2 = abc_run!( #, plant_df2
    model2, step_model!, (455 - restart_after);
    when_rust = when_rust2,
    when_prod = when_prod2,
    rust_data = [ind_data],
    prod_data = [coffee_prod]
    )

    # plant_df = per_cycle_df[per_cycle_df .∈ Ref(when_prod), [:tick, :coffee_production]]

    per_age_df2[:, :tick] .= per_age_df2.tick .+ restart_after
    per_cycle_df2[:, :tick] .= per_cycle_df2.tick .+ restart_after
    plant_df2[:, :tick] .= plant_df2.tick .+ restart_after

    return vcat(per_age_df, per_age_df2), vcat(per_cycle_df, per_cycle_df2), vcat(plant_df, plant_df2)

end

## Selecting sampled locations for each cycle

function custom_sampling_first!(model::ABM, percent::Float64)
    let n_persample = floor(Int, length(model.current.coffee_ids) * percent),
    first_ids = sample(model.rng, filter(id -> all(5 .< model[id].pos .<= 95),
        model.current.coffee_ids), n_persample, replace = false),
    sampled_coffees = hcat(first_ids, zeros(Int, n_persample, 3)) # 1 half requires 3 neighs, 2 half reqs 5
        for (i, id) in enumerate(first_ids)
            push!(model[id].sample_cycle, 1)
            c = 2
            for neigh in select_s_neighbors(model, sampled_coffees, id)
                push!(model[neigh].sample_cycle, c)
                sampled_coffees[i, c] = neigh
                c += 1
                c > 4 && break # break if # of selected neighs is greater than 4
            end
            if c < 4 # if # of selected neighs was not enough, relax requirements
                for add_neigh in complete_s_neighbors(model, sampled_coffees, id, i, c)
                    push!(model[add_neigh].sample_cycle, c)
                    sampled_coffees[i, c] = add_neigh
                    c += 1
                    c > 4 && break
                end
            end
        end
    end
end


function custom_sampling_second!(model::ABM, percent::Float64)
    let n_persample = floor(Int, length(model.current.coffee_ids) * percent),
    first_ids = sample(model.rng, filter(id -> all(5 .< model[id].pos .<= 95),
        model.current.coffee_ids), n_persample, replace = false),
    sampled_coffees = hcat(first_ids, zeros(Int, n_persample, 5))
        for (i, id) in enumerate(first_ids)
            push!(model[id].sample_cycle, 5) # second half starts with cycle 5
            c = 6
            for neigh in select_s_neighbors(model, sampled_coffees, id)
                push!(model[neigh].sample_cycle, c)
                sampled_coffees[i, (c - 4)] = neigh
                c += 1
                c > 10 && break
            end
            if c < 10
                for add_neigh in complete_s_neighbors(model, sampled_coffees, id, i, (c - 4))
                    push!(model[add_neigh].sample_cycle, c)
                    sampled_coffees[i, (c - 4)] = add_neigh
                    c += 1
                    c > 10 && break
                end
            end
        end
    end
end

function select_s_neighbors(model::ABM, sampled_coffees::Array{Int,2}, c_id::Int)::Vector{Int}
    return shuffle(model.rng, collect(Iterators.filter(x -> model[x] isa Coffee && x ∉ sampled_coffees,
        nearby_ids(model[c_id], model, 2))))
end

function complete_s_neighbors(model::ABM, sampled_coffees::Array{Int,2}, c_id::Int, i::Int, c::Int)
    return shuffle(model.rng, collect(Iterators.filter(x -> model[x] isa Coffee &&
        x ∉ sampled_coffees[i,:] && x ∉ sampled_coffees[:,c], nearby_ids(model[c_id], model, 2))))
end

## Extracting prod data from per_cycle

function extract_prod(cdf::DataFrame)::DataFrame
    return leftjoin(DataFrame(
        tick = [17, 77, 140, 203, 287, 315, 343, 372, 399, 427], cycle = 1:10
        ),
    cdf[!, [:tick, :cycle, :coffee_production]],
    on = [:tick, :cycle])
end

## Custom run

function abc_run!(model::ABM,
    model_step!,
    n;
    when_rust = true,
    when_prod = true,
    rust_data = nothing,
    prod_data = nothing)

    # df_rust = init_model_dataframe(model, rust_data)
    per_age = DataFrame(
        tick = Int[], cycle = Int[],
        age = Int[],
        area_m = Float64[], spores_m = Float64[]
    )

    per_cycle = DataFrame(
        tick = Int[], cycle = Int[],
        area_m = Float64[], spores_m = Float64[],
        fallen = Float64[]
    )

    per_plant = DataFrame(
        tick = Int[], coffee_production = Float64[]
    )

    # df_prod = init_model_dataframe(model, prod_data)
    for c in eachcol(per_age)
        sizehint!(c, (length(when_rust) * 2))
    end
    for c in eachcol(per_cycle)
        sizehint!(c, length(when_rust))
    end
    for c in eachcol(per_plant)
        sizehint!(c, length(when_prod))
    end

    s = 0
    while Agents.until(s, n, model)
        if Agents.should_we_collect(s, model, when_rust)
            # let df = collect_model_data!(DataFrame(step = Int[], ind_data = DataFrame()), model, rust_data, s; obtainer)
            #     update_dfs!(
            #     per_age,
            #     per_cycle,
            #     # per_plant,
            #     df[1, :ind_data][1, :rust],
            #     df[1, :ind_data][1, :prod])
            # end
            collect_rust_data!(per_age, per_cycle, model)
        end
        if Agents.should_we_collect(s, model, when_prod)
            # let df2 = collect_model_data!(DataFrame(step = Int[], coffee_prod = DataFrame()), model, prod_data, s; obtainer)
            #     append!(per_plant, df2[1, :coffee_prod])
            # end
            collect_prod_data!(per_plant, model)
        end
        step!(model, dummystep, model_step!, 1)
        s += 1
    end
    if Agents.should_we_collect(s, model, when_rust)
        # let df = collect_model_data!(DataFrame(step = Int[], ind_data = DataFrame()), model, rust_data, s; obtainer)
        #     update_dfs!(
        #     per_age,
        #     per_cycle,
        #     # per_plant,
        #     df[1, :ind_data][1, :rust],
        #     df[1, :ind_data][1, :prod])
        # end
        collect_rust_data!(per_age, per_cycle, model)
    end
    if should_we_collect(s, model, when_prod)
        # let df2 = collect_model_data!(DataFrame(step = Int[], coffee_prod = DataFrame()), model, prod_data, s; obtainer)
        #     append!(per_plant, df2[1, :coffee_prod])
        # end
        collect_prod_data!(per_plant, model)
    end
    return per_age, per_cycle, per_plant
end

## DataFrame post processing

function dewrinkle(rust_df)

    per_age_df = reduce(vcat, rust_df.d_per_ages)
    per_cycle_df = reduce(vcat, rust_df.d_per_cycles)

    return per_age_df, per_cycle_df
end

## Custom cat for ABCOuts struct

function struct_cat(s1::ABCOuts, s2::ABCOuts)
    return ABCOuts(
    vcat(s1.per_age, s2.per_age),
    vcat(s1.per_cycle, s2.per_cycle),
    # vcat(s1.prod_df, s2.prod_df)
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
