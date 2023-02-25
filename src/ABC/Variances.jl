function rearrange_datafile()
    compare = CSV.read("data/exp_pro/compare/perdateage_age.csv", DataFrame, missingstring = "NA")
    suncompare = select(compare, 1:6)
    shadecompare = select(compare, [1,2,7,8,9,10])
    rename!(shadecompare, names(suncompare))
    sunovershade = vcat(suncompare,shadecompare, source=:plot => [:sun, :shade])
    rename!(sunovershade, [:dayn, :age, :nl_dat, :area_dat, :spore_dat, :occup_dat, :plot])

    longcompare = stack(sunovershade, Not([:dayn, :age, :plot]))
    dropmissing!(longcompare)
    sunovershade = unstack(longcompare)
    sunovershade = sunovershade[!, [1,2,3,5,6,4,7]]
    sort!(sunovershade, [order(:plot, rev = true), :dayn, :age])
    CSV.write("data/exp_pro/compare/sunovershade.csv", sunovershade)
    return sunovershade
end

function σ2_nts(files::Vector{String})
    grouped = @distributed merge for f in files
        run_two_onlines(DataFrame(Arrow.Table(f)))
    end
    
    return dfize(grouped)
end

function σ2_ls(files::Vector{String})
    vars = @distributed merge for f in files
        # df = DataFrame(Arrow.Table(f))
        # select!(df, Not(:prod_clr_cor), [:prod_clr_sun, :prod_clr_shade] => ByRow(meannan) => :prod_clr_cor)
        qualseries = Series(6 * FilterTransform(Variance(), Union{Float64, Missing}, filter = !isnan),
        6 * FilterTransform(Counter(), Union{Float64, Missing}, filter = !isnan))
        fit!(qualseries, global_itr(DataFrame(Arrow.Table(f)), 2, 7))
    end
    
    return dfize(vars)
end

function run_two_onlines(df)::NTuple{2,OnlineStatsBase.StatCollection}
    # df_sun = select(df, 1:6)
    # df_shade = select(df, [1,2,7,8,9,10])
    # rename!(df_shade, names(df_sun))
    # append!(df_sun, df_shade)

    groupseries = GroupBy(Tuple, Series(
        4 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
        4 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan)
    ))
    globseries = Series(
        4 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
        4 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan)
    )

    fit!(groupseries, grouped_itr(df))
    fit!(globseries, global_itr(df, 3, 6))

    return groupseries, globseries
end

@inline nomisnan(x) = !ismissing(x) && !isnan(x)

@inline grouped_itr(df) = ((r.dayn, r.age) => (
    r.med_area, r.med_spore, r.med_nl, r.occup
) for r in eachrow(df))

# @inline grouped_itr8(df) = ((r.dayn, r.age) => (
#     r.med_area_sun, r.med_spore_sun, r.med_nl_sun, r.occup_sun,
#     r.med_area_shade, r.med_spore_shade, r.med_nl_shade, r.occup_shade
# ) for r in eachrow(df))

@inline global_itr(df, fromcol::Int, tocol::Int) = (Tuple(r) for r in eachrow(df[!, fromcol:tocol]))

Base.merge(t1::NTuple{2,OnlineStatsBase.StatCollection}, t2::NTuple{2,OnlineStatsBase.StatCollection}) = merge(t1[1], t2[1]), merge(t1[2], t2[2])

## "DataFrame-ize" OnlineStats outputs

function dfize(statstup::NTuple{2,OnlineStatsBase.StatCollection}) # "dataframe-ize" quants
    grouped = statstup[1]
    globaled = statstup[2]
    
    var_df = DataFrame(
        dayn = Int[],
        age = Int[],
        area_var = Float64[],
        spore_var = Float64[],
        nl_var = Float64[],
        occup_var = Float64[]
    )
    n_df = DataFrame(
        dayn = Int[],
        age = Int[],
        area_var_n = Int[],
        spore_var_n = Int[],
        nl_var_n = Int[],
        occup_var_n = Int[]
    )
    # allowmissing!(var_df, [:dayn, :age])
    # allowmissing!(n_df, [:dayn, :age])

    for k in keys(value(grouped))
        rowv::Vector{Union{Int, Float64}} = collect(k)
        rown::Vector{Int} = collect(k)
        # rowv::Vector{Union{Int, Float64, Missing}} = collect(k)
        # rown::Vector{Union{Int, Missing}} = collect(k)
        append!(rowv, collect(value.(value(grouped[k].stats[1]))))
        append!(rown, collect(value.(value(grouped[k].stats[2]))))
        push!(var_df, rowv)
        push!(n_df, rown)
    end

    gvar_df = DataFrame(
        area_var = Float64[],
        spore_var = Float64[],
        nl_var = Float64[],
        occup_var = Float64[]
    )
    gn_df = DataFrame(
        area_var_n = Int[],
        spore_var_n = Int[],
        nl_var_n = Int[],
        occup_var_n = Int[]
    )

    push!(gvar_df, value.(value(globaled.stats[1])))
    push!(gn_df, value.(value(globaled.stats[2])))

    return var_df, n_df, gvar_df, gn_df
end

function dfize(ostats::Series) # "dataframe-ize" quals
    var_df = DataFrame(
        exh_sun_var = Float64[],
        prod_clr_sun_var = Float64[],
        exh_shade_var = Float64[],
        prod_clr_shade_var = Float64[],
        exh_spct_var = Float64[],
        prod_clr_cor_var = Float64[]
    )
    n_df = DataFrame(
        exh_sun_n = Int[],
        prod_clr_sun_n = Int[],
        exh_shade_n = Int[],
        prod_clr_shade_n = Int[],
        exh_spct_n = Int[],
        prod_clr_cor_n = Int[]
    )
            
    push!(var_df, value.(value(ostats.stats[1])))
    push!(n_df, value.(value(ostats.stats[2])))

    return var_df, n_df
end

# function dfize(grouped::GroupBy) # "dataframe-ize" quants
#     var_df = DataFrame(
#         dayn = Int[],
#         age = Int[],
#         v_med_area_sun = Float64[],
#         v_med_spore_sun = Float64[],
#         v_med_nl_sun = Float64[],
#         v_occup_sun = Float64[],
#         v_med_area_shade = Float64[],
#         v_med_spore_shade = Float64[],
#         v_med_nl_shade = Float64[],
#         v_occup_shade = Float64[]
#     )
#     n_df = DataFrame(
#         dayn = Int[],
#         age = Int[],
#         n_area_sun = Int[],
#         n_spore_sun = Int[],
#         n_nl_sun = Int[],
#         n_occup_sun = Int[],
#         n_area_shade = Int[],
#         n_spore_shade = Int[],
#         n_nl_shade = Int[],
#         n_occup_shade = Int[]
#     )
#     # allowmissing!(var_df, [:dayn, :age])
#     # allowmissing!(n_df, [:dayn, :age])

#     for k in keys(value(grouped))
#         rowv::Vector{Union{Int, Float64}} = collect(k)
#         rown::Vector{Int} = collect(k)
#         # rowv::Vector{Union{Int, Float64, Missing}} = collect(k)
#         # rown::Vector{Union{Int, Missing}} = collect(k)
#         append!(rowv, collect(value.(value(grouped[k].stats[1]))))
#         append!(rown, collect(value.(value(grouped[k].stats[2]))))
#         push!(var_df, rowv)
#         push!(n_df, rown)
#     end

#     return var_df, n_df
# end

# function nonans(t::Tuple)::Tuple
#     t2 = similar(t)
#     for i in eachindex(t)
#         if isnan(t[i])
#             t[i] = 2
#         end
#     end
#     return t
# end
