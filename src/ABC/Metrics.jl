## Qualitative patterns

function get_prod_df!(df::DataFrame, allcofs::Vector{Coffee})
    # df[!, :id] = map(c -> c.id, values(model.agents))
    # df[!, :production] = getproperty.(model.agents, :production)
    # df[!, :veg] = getproperty.(model.agents, :veg)
    # select!(df, [:veg, :production] => ByRow(fruittoleaf) => :FtL)
    # df[!, :FtL] = getproperty.(model.agents, :production) ./ max.(getproperty.(model.agents, :veg), 0.001)
    df[!, :FtL] = map(c -> (c.production / max(c.veg, 0.001)), allcofs)
    df[!, :nl_c] = map(c -> c.n_lesions, allcofs)
end

# fruittoleaf(v::Float64, p::Float64) = p / (v + p)

# function add_clr_areas!(df::DataFrame, model::SpatialRustABM)
#     df[!, :clr_area] = map(c -> sum(c.areas), model.agents)
# end

# function meanareas(a)
#     if sum(a.areas) == 0.0
#         return 0.0
#     else
#         return mean(filter(>(0.0), a.areas))
#     end
# end

function prod_clr_corr(df::DataFrame, allcofs::Vector{Coffee})
    df[!, :clr_cat] = map(clr_cat, allcofs)
    subset!(df, :nl_c => ByRow(==(0)), :clr_cat => ByRow(>(0)))
    
    if isempty(df)
        prod_clr_cor = missing
    else
        prod_clr_cor = corkendall(df[!, :FtL], df[!, :clr_cat])
    end

    return prod_clr_cor
end

function clr_cat(c::Coffee)
    if c.exh_countdown > 0
        return 4
    elseif c.n_lesions == 0
        return 0
    elseif (sps = sum(c.spores)) == 0
        return 1
    elseif sps < 3
        return 2
    else
        return 3
    end
end

# function finalrust(c::Coffee)
#     # area = sum(c.areas)
#     # if area == 0.0 
#     #     if c.exh_countdown == 0
#     #         return -10.0
#     #     else
#     #         return 25.0
#     #     end
#     # else
#     #     return area
#     # end
#     # area = sum(c.areas)
#     # if area == 0.0 && c.exh_countdown == 0
#     #     return -10.0
#     # else
#     #     return area
#     # end
#     if c.exh_countdown > 0
#         return 24.0 + (sum(c.areas) / 25.0)
#     else
#         return sum(c.areas)
#     end
# end

# function exh_incid(model::SpatialRustABM)
#     nexh = sum(map(c -> c.exh_countdown > 0, model.agents)) 
#     return nexh, nexh + sum(map(c -> c.n_lesions > 0, model.agents))
# end

## Quantitative patterns

# surveyed_today(c::Coffee, cycle::Vector{Int})::Bool = c.sample_cycle ∈ cycle && c.exh_countdown == 0

function get_weekly_data(model::SpatialRustABM, cycle_n::Vector{Int}, max_age::Int, cycle_last::Bool)
    # survey_cofs = Iterators.filter(c -> surveyed_today(c, cycle_n), model.agents)
    active_sents = filter!(s -> s.active, model.sentinels)
    spore_pct = model.rustpars.spore_pct
    max_les = model.rustpars.max_lesions

    # let df_i = DataFrame(age = Int[], area = Float64[], spore = Float64[], nl = Int[], id = Int[])
    let df_i = DataFrame(age = Int[], area = Float64[], cycle = Int[],
        spore = Float64[], nl = Int[], id = Int[])
        # for cof in survey_cofs
        for cof in active_sents
            # within_age = findall(<=(max_age), cof.ages)
            # for l in within_age
            #     push!(df_i, survey_lesion(cof, l))
            # end
            df_c = DataFrame()
            df_c[!, :age] = div.(cof.ages, 7, RoundNearest)
            df_c[!, :area] = cof.areas
            df_c[!, :spore] = cof.spores .* cof.areas .* spore_pct
            df_c[!, :id] .= cof.id
            df_c[!, :cycle] .= cof.cycle
            df_c[!, :nl] .= cof.n_lesions
            append!(df_i, df_c)
        end

        filter!(:age => <=(max_age), df_i)

        if isempty(df_i)
            return DataFrame(
                age = repeat(0:max_age, length(cycle_n)), 
                cycle = repeat(cycle_n, inner = (max_age + 1)),
                area = missing, spore = missing, nl = missing, occup = missing)
        else
            nlesions_age = combine(groupby(df_i, [:id, :cycle]), :age => maximum => :age, :nl => first => :nl)
            df_nlesions = combine(groupby(nlesions_age, [:age, :cycle]), :nl => median => :nl)

            df_areas = combine(
                groupby(df_i, [:age, :cycle]),
                :area => median => :area,
                :spore => median => :spore,
                nrow => :occup
            )
            if cycle_last
                # avail_sites_wpct = length(collect(survey_cofs)) * max_les * inv(100.0)
                avail_sites_wpct = length(active_sents) * max_les
                df_areas[!, :occup] = df_areas[!, :occup] ./ avail_sites_wpct
                # select!(df_areas, Not(:lcount), :lcount => (n -> n / avail_sites_wpct) => :occup)
            else
                # select!(df_areas, Not(:occup))
                df_areas[!, :occup] .= missing
            end

            df_age = outerjoin(df_areas, df_nlesions, on = [:age, :cycle])
            df_age = leftjoin(DataFrame(
                    age = repeat(0:max_age, length(cycle_n)),
                    cycle = repeat(cycle_n, inner = (max_age + 1))
                ),
                df_age, on = [:age, :cycle]
            )

            return df_age
        end
    end
end

function get_areas_nl(allcofs::Vector{Coffee})
    infected = Iterators.filter(c -> c.n_lesions > 0, allcofs)

    areasums = (sum(c.areas) for c in infected)
    meansumarea = isempty(areasums) ? missing : mean(areasums)

    nlmeans = (c.n_lesions for c in infected)
    meannl = isempty(nlmeans) ? missing : mean(nlmeans)

    return meansumarea, meannl
end

# area_sum(c::Coffee) = c.exh_countdown > 0 ? -1.0 : sum(c.areas)
