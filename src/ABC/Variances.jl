## Get variances
function σ2(folder::String, firstn::Int)
    # v_a = σ2_a(folder)
    quantfiles = readdir(string(folder,"quants"), join = true, sort = false)[1:firstn]
    qualfiles = readdir(string(folder,"quals"), join = true, sort = false)[1:firstn]
    v_quant, n_quant = σ2_nts(quantfiles)
    v_qual, n_qual = σ2_ls(qualfiles)

    return v_quant, v_qual, n_quant, n_qual
end

function σ2(folder::String)
    # v_a = σ2_a(folder)
    quantfiles = readdir(string(folder,"quants"), join = true, sort = false)
    qualfiles = readdir(string(folder,"quals"), join = true, sort = false)
    v_quant, n_quant = σ2_nts(quantfiles)
    v_qual, n_qual = σ2_ls(qualfiles)

    return v_quant, v_qual, n_quant, n_qual
end

function σ2_nts(files::Vector{String})
    vars = @distributed merge for f in files
        quantseries = Series(8 * FilterTransform(Variance(), Union{Float64, Missing}, filter = nomisnan),
        8 * FilterTransform(Counter(), Union{Float64, Missing}, filter = nomisnan))
        fit!(GroupBy(Tuple, quantseries), quant_itr(DataFrame(Arrow.Table(f))) )
    end
    
    return dfize(vars)
end

function σ2_ls(files::Vector{String})
    vars = @distributed merge for f in files
        # df = DataFrame(Arrow.Table(f))
        # select!(df, Not(:prod_clr_cor), [:prod_clr_sun, :prod_clr_shade] => ByRow(meannan) => :prod_clr_cor)
        qualseries = Series(6 * FilterTransform(Variance(), Union{Float64, Missing}, filter = !isnan),
        6 * FilterTransform(Counter(), Union{Float64, Missing}, filter = !isnan))
        fit!(qualseries, qual_itr(DataFrame(Arrow.Table(f))) )
    end
    
    return dfize(vars)
end

@inline nomisnan(x) = !ismissing(x) && !isnan(x)

@inline quant_itr(df) = ((r.dayn, r.age) => (
        r.med_area_sun, r.med_spore_sun, r.med_nl_sun, r.occup_sun,
        r.med_area_shade, r.med_spore_shade, r.med_nl_shade, r.occup_shade
    ) for r in eachrow(df))


@inline qual_itr(df) = (Tuple(r) for r in eachrow(df[!,2:end]))

function meannan(x::Float64,y::Float64)
    if isnan(x)
        if isnan(y)
            return NaN
        else
            return y
        end
    else
        if isnan(y)
            return x
        else
            return (x + y) / 2.0
        end
    end
end

function dfize(ostats::GroupBy) # "dataframe-ize" quants
        var_df = DataFrame(dayn = Int[],
                        age = Int[],
                        v_med_area_sun = Float64[],
                        v_med_spore_sun = Float64[],
                        v_med_nl_sun = Float64[],
                        v_occup_sun = Float64[],
                        v_med_area_shade = Float64[],
                        v_med_spore_shade = Float64[],
                        v_med_nl_shade = Float64[],
                        v_occup_shade = Float64[])
        n_df = DataFrame(dayn = Int[],
                        age = Int[],
                        n_area_sun = Int[],
                        n_spore_sun = Int[],
                        n_nl_sun = Int[],
                        n_occup_sun = Int[],
                        n_area_shade = Int[],
                        n_spore_shade = Int[],
                        n_nl_shade = Int[],
                        n_occup_shade = Int[])
    
        for k in keys(value(ostats))
            rowv::Vector{Union{Int, Float64}} = collect(k)
            rown::Vector{Int} = collect(k)
            append!(rowv, collect(value.(value(ostats[k].stats[1]))))
            append!(rown, collect(value.(value(ostats[k].stats[2]))))
            push!(var_df, rowv)
            push!(n_df, rown)
        end

    return var_df, n_df
end

function dfize(ostats::Series) # "dataframe-ize" quals
    var_df = DataFrame(v_exh_sun = Float64[],
                        v_prod_clr_sun = Float64[],
                        v_exh_shade = Float64[],
                        v_prod_clr_shade = Float64[],
                        v_exh_spct = Float64[],
                        v_prod_clr_cor = Float64[])
    n_df = DataFrame(n_exh_sun = Int[],
                        n_prod_clr_sun = Int[],
                        n_exh_shade = Int[],
                        n_prod_clr_shade = Int[],
                        n_exh_spct = Int[],
                        n_prod_clr_cor = Int[])
            
    push!(var_df, value.(value(ostats.stats[1])))
    push!(n_df, value.(value(ostats.stats[2])))

    return var_df, n_df
end

# function nonans(t::Tuple)::Tuple
#     t2 = similar(t)
#     for i in eachindex(t)
#         if isnan(t[i])
#             t[i] = 2
#         end
#     end
#     return t
# end
