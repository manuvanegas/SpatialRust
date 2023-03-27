# My merge func
mymerge(t1::NTuple{2,OnlineStatsBase.StatCollection}, t2::NTuple{2,OnlineStatsBase.StatCollection}) = merge(t1[1], t2[1]), merge(t1[2], t2[2])


# "Quantitative"

function σ2_nts(files::Vector{String})
    grouped = @distributed merge for f in files
        globseries = Series(
        4 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
        4 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan)
        )
        fit!(globseries, global_itr(DataFrame(Arrow.Table(f)), 4, 7))
        # run_two_onlines(DataFrame(Arrow.Table(f)))
    end
    
    return dfize2(grouped)
end

# function run_two_onlines(df) # ::NTuple{2,OnlineStatsBase.StatCollection}
#     # df_sun = select(df, 1:6)
#     # df_shade = select(df, [1,2,7,8,9,10])
#     # rename!(df_shade, names(df_sun))
#     # append!(df_sun, df_shade)

#     # groupseries = GroupBy(Tuple, Series(
#     #     4 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
#     #     4 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan)
#     # ))
#     globseries = Series(
#         4 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
#         4 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan)
#     )

#     # fit!(groupseries, grouped_itr(df))
#     fit!(globseries, global_itr(df, 4, 7))

#     # return groupseries, globseries
#     return globseries
# end

@inline nomisnan(x) = !ismissing(x) && !isnan(x)

@inline global_itr(df, fromcol::Int, tocol::Int) = (Tuple(r) for r in Tables.namedtupleiterator(df[!, fromcol:tocol]))

## "DataFrame-ize" OnlineStats outputs
function dfize2(gstats::Series)

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

    push!(gvar_df, value.(value(gstats.stats[1])))
    push!(gn_df, value.(value(gstats.stats[2])))

    return gvar_df, gn_df
end



# "Qualitative"

function σ2_ls(files::Vector{String})
    vars = @distributed mymerge for f in files
        # df = DataFrame(Arrow.Table(f))
        # select!(df, Not(:prod_clr_cor), [:prod_clr_sun, :prod_clr_shade] => ByRow(meannan) => :prod_clr_cor)
        run_two_onlines(DataFrame(Arrow.Table(f)))
    end
    
    return dfize(vars)
end

function run_two_onlines(df) # ::NTuple{2,OnlineStatsBase.StatCollection}
    # # df_sun = select(df, 1:6)
    # # df_shade = select(df, [1,2,7,8,9,10])
    # # rename!(df_shade, names(df_sun))
    # # append!(df_sun, df_shade)

    # # groupseries = GroupBy(Tuple, Series(
    # #     4 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
    # #     4 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan)
    # # ))
    # globseries = Series(
    #     4 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
    #     4 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan)
    # )

    # # fit!(groupseries, grouped_itr(df))
    # fit!(globseries, global_itr(df, 4, 7))

    # # return groupseries, globseries
    # return globseries

    selfseries = Series(3 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
    3 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan))

    diffseries = Series(6 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
    6 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan))

    selfs, diffs = addyieldcalcs(df)

    fit!(selfseries, global_itr(selfs, 1, 3))
    fit!(diffseries, global_itr(diffs, 1, 6))

    return selfseries, diffseries
end

function addyieldcalcs(df::DataFrame)
    df1 = select(df, :p_row, :plot, :incidiff, :cor,
        [:P1att, :P1obs, :P12att, :P12obs] => ByRow(yieldloss) => [:P1loss, :P12loss],
        [:P1att, :P12att] => ByRow(bienniality) => [:P1att, :P12att, :bienniality],
        :areas, :nls
    )
    
    dfsun = subset(df1, :plot => ByRow(==(:sun)))
    dfsh = subset(df1, :plot => ByRow(==(:shade)))

    dfsun[!, :P1att] = dfsun[!, :P1att] .- dfsh[!, :P1att]
    dfsun[!, :bienniality] = dfsun[!, :bienniality] .- dfsh[!, :bienniality]
    dfsun[!, :Pattpct] = 1.0 .- dfsh[!, :P12att] ./ dfsun[!, :P12att]
    dfsun[!, :areas] = dfsun[!, :areas] .- dfsh[!, :areas]
    dfsun[!, :nls] = dfsun[!, :nls] .- dfsh[!, :nls]

    return select!(df1, :P1loss, :P12loss, :incidiff), select!(dfsun, :P1att, :bienniality, :Pattpct, :areas, :nls, :cor)
end

function yieldloss(y1att, y1obs, y12att, y12obs)
    return (y1att - y1obs) / y1att, ((y12att - y12obs) / y12att)
end

function bienniality(Y1, Y12)
    return Y1, Y12, ((2.0 * Y1 - Y12) / Y1)
end

## "DataFrame-ize" OnlineStats outputs
function dfize(statstup::NTuple{2,OnlineStatsBase.StatCollection}) # "dataframe-ize" quals

    selfs_df = DataFrame(
        P1loss = Float64[],
        P12loss = Float64[],
        incidiff = Float64[],
    )
    diffs_df = DataFrame(
        P1att = Float64[],
        bienniality = Float64[],
        Pattpct = Float64[],
        areas = Float64[],
        nls = Float64[],
        cor = Float64[],
    )

    n_selfs_df = DataFrame(
        P1loss = Int[],
        P12loss = Int[],
        incidiff = Int[],
    )
    n_diffs_df = DataFrame(
        P1att = Int[],
        bienniality = Int[],
        Pattpct = Int[],
        areas = Int[],
        nls = Int[],
        cor = Int[],
    )


    selfs = statstup[1]
    diffs = statstup[2]
    
    push!(selfs_df, value.(value(selfs.stats[1])))
    push!(diffs_df, value.(value(diffs.stats[1])))
    
    push!(n_selfs_df, value.(value(selfs.stats[2])))
    push!(n_diffs_df, value.(value(diffs.stats[2])))

    return hcat(selfs_df, diffs_df), hcat(n_selfs_df, n_diffs_df)
end


# @inline grouped_itr(df) = (
#     (r.plot, r.dayn, r.age, r.cycle) => (r.area, r.spore, r.nl, r.occup)
#     for r in Tables.namedtupleiterator(df))

# @inline grouped_itr8(df) = ((r.dayn, r.age) => (
#     r.med_area_sun, r.med_spore_sun, r.med_nl_sun, r.occup_sun,
#     r.med_area_shade, r.med_spore_shade, r.med_nl_shade, r.occup_shade
# ) for r in eachrow(df))

# function dfize(statstup::NTuple{2,OnlineStatsBase.StatCollection}) # "dataframe-ize" quants
#     grouped = statstup[1]
#     globaled = statstup[2]
    
#     var_df = DataFrame(
#         plot = Symbol[],
#         dayn = Int[],
#         age = Int[],
#         cycle = Int[],
#         area_var = Float64[],
#         spore_var = Float64[],
#         nl_var = Float64[],
#         occup_var = Float64[]
#     )
#     n_df = DataFrame(
#         plot = Symbol[],
#         dayn = Int[],
#         age = Int[],
#         cycle = Int[],
#         area_var_n = Int[],
#         spore_var_n = Int[],
#         nl_var_n = Int[],
#         occup_var_n = Int[]
#     )
#     # allowmissing!(var_df, [:dayn, :age])
#     # allowmissing!(n_df, [:dayn, :age])

#     for k in keys(value(grouped))
#         # rowv::Vector{Union{Int, Float64, Symbol}} = collect(k)
#         # rown::Vector{Int} = collect(k)
#         # rowv::Vector{Union{Int, Float64, Missing}} = collect(k)
#         # rown::Vector{Union{Int, Missing}} = collect(k)
#         # append!(rowv, collect(value.(value(grouped[k].stats[1]))))
#         # append!(rown, collect(value.(value(grouped[k].stats[2]))))
#         statsr = grouped[k].stats
#         push!(var_df, [collect(k); collect(value.(value(statsr[1])))])
#         push!(n_df, [collect(k); collect(value.(value(statsr[2])))])
#     end

#     gvar_df = DataFrame(
#         area_var = Float64[],
#         spore_var = Float64[],
#         nl_var = Float64[],
#         occup_var = Float64[]
#     )
#     gn_df = DataFrame(
#         area_var_n = Int[],
#         spore_var_n = Int[],
#         nl_var_n = Int[],
#         occup_var_n = Int[]
#     )

#     push!(gvar_df, value.(value(globaled.stats[1])))
#     push!(gn_df, value.(value(globaled.stats[2])))

#     return var_df, n_df, gvar_df, gn_df
# end

# function dfize(ostats::Series) # "dataframe-ize" quals
#     var_df = DataFrame(
#         incidiff = Float64[],
#         cor = Float64[],
#         P1loss = Float64[],
#         P12loss = Float64[],
#         P1att = Float64[],
#         P12att = Float64[],
#         bienniality = Float64[],
#         areas = Float64[],
#         nls = Float64[]
#     )
#     n_df = DataFrame(
#         incidiff =Int[],
#         cor = Int[],
#         P1loss = Int[],
#         P12loss =  Int[],
#         P1att = Int[],
#         P12att = Int[],
#         bienniality = Int[],
#         areas = Int[],
#         nls = Int[]
#     # )
            
#     push!(var_df, value.(value(ostats.stats[1])))
#     push!(n_df, value.(value(ostats.stats[2])))

#     return var_df, n_df
# end

