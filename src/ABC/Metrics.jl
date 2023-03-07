## Qualitative patterns

function get_prod_df!(df::DataFrame, model::SpatialRustABM)
    # df[!, :id] = map(c -> c.id, values(model.agents))
    df[!, :production] = getproperty.(model.agents, :production)
    df[!, :veg] = getproperty.(model.agents, :veg)
    select!(df, [:veg, :production] => ByRow(fruittoleaf) => :FtL)
end

fruittoleaf(v::Float64, p::Float64) = p / (v + p)

function add_clr_areas!(df::DataFrame, model::SpatialRustABM)
    df[!, :clr_area] = meanareas.(model.agents)
end

function meanareas(a)
    if sum(a.areas) == 0.0
        return 0.0
    else
        return mean(filter(>(0.0), a.areas))
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

function exh_incid(model::SpatialRustABM)
    nexh = sum(map(c -> c.exh_countdown > 0, model.agents)) 
    return nexh, nexh + sum(getproperty.(model.agents, :n_lesions) .> 0)
end

## Quantitative patterns

# surveyed_today(c::Coffee, cycle::Vector{Int})::Bool = c.sample_cycle ∈ cycle && c.exh_countdown == 0

area_sum(c::Coffee) = c.exh_countdown > 0 ? -1.0 : sum(c.areas)

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

        # pctareas = filter(:area => <=(0.75), combine(groupby(df_i, :id), :area => a -> sum(a)/max_les, renamecols = false))
        # meanpctarea = isempty(pctareas) ? missing : mean(pctareas[!, :area])
        areasums = filter!(>(0.0), area_sum.(model.agents))
        meansumarea = isempty(areasums) ? missing : mean(areasums)

        areameans = filter!(>(0.0), meanareas.(model.agents))
        meanarea = isempty(areameans) ? missing : mean(areameans)

        nlmeans = filter!(>(0), getproperty.(model.agents, :n_lesions))
        meannl = isempty(nlmeans) ? missing : mean(nlmeans)

        filter!(:age => <=(max_age), df_i)
        if isempty(df_i)
            return DataFrame(
                age = repeat(0:max_age, length(cycle_n)), 
                cycle = repeat(cycle_n, inner = (max_age + 1)),
                area = missing, spore = missing, nl = missing, occup = missing,
                ar_sum = meansumarea, ar_mn = meanarea, nl_mn = meannl)
        else
            # nlesions_age = combine(groupby(df_i, :id), :age => maximum => :age, :nl => first => :nl)
            # df_nlesions = combine(groupby(nlesions_age, :age), :nl => median => :nl)
            nlesions_age = combine(groupby(df_i, [:id, :cycle]), :age => maximum => :age, :nl => first => :nl)
            df_nlesions = combine(groupby(nlesions_age, [:age, :cycle]), :nl => median => :nl)

            df_areas = combine(
                # groupby(df_i, :age),
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

            # df_age = outerjoin(df_areas, df_nlesions, on = :age)
            df_age = outerjoin(df_areas, df_nlesions, on = [:age, :cycle])
            df_age.ar_sum .= meansumarea
            df_age.ar_mn .= meanarea
            df_age.nl_mn .= meannl

            return df_age
        end
    end
end

# # prob wont work
# function get_weekly_data_2017_2(model::SpatialRustABM, s::Int)
#     cycle_n, max_age, cycle_last = current_cycle_ages_2017(s)
#     survey_cofs = Iterators.filter(c -> surveyed_today(c, cycle_n), values(model.agents))
#     let df_i = DataFrame()
#         df_i[!, :age] = map(c -> c.ages, survey_cofs)
#         df_i[!, :area] = map(c -> c.areas, survey_cofs)
#         df_i[!, :spore] = map(c -> c.spores, survey_cofs)
#         df_i[!, :nl] .= map(c -> c.n_lesions, survey_cofs)
#         for cof in survey_cofs
#             # within_age = findall(<=(max_age), cof.ages)
#             # for l in within_age
#             #     push!(df_i, survey_lesion(cof, l))
#             # end
#             df_c = DataFrame()
            
#             append!(df_i, df_c)
#             if cycle_last
#             end
#         end
#     end
# end

# function survey_lesion(cof::Coffee, pos::Int)
#     [cof.n_lesions, cof.ages[pos], cof.areas[pos], cof.spores[pos]]
# end

# function testdfcols()
#     df = DataFrame(a = Float64[], b = Float64[], c = Int[])
#     as = collect(1.0:10.0)
#     bs = collect(11.0:20.0)
#     is = collect(1:10)
#     for j in 1:50
#         dd = DataFrame()
#         # ns = rand(is)
#         dd[!, :a] = shuffle(as)
#         dd[!, :b] .= 4.0
#         dd[!, :c] .= 5
#         # for name in [:a,:b]
#         #     # idats = rand(1:10, 5)
#         #     dats = rand(is, ns)
#         #     # push!(df[!, i], d for d in dats[:, i])
#         #     dd[!, name] = shuffle(as)
#         # end
#         # filter!(:a => <(6), dd)
#         append!(df, dd)
#         # for i in 1:5
#         #     push!(df, [as[rand(is)], bs[rand(is)]])
#         # end
#         # push!(df, [1.0, 2.0])
#     end
#     filter!(:a => <(6), df)
#     return df
# end

# function testdfrows()
#     df = DataFrame(a = Float64[], b = Float64[], c = Int[])
#     as = collect(1.0:10.0)
#     bs = collect(11.0:20.0)
#     is = collect(1:10)
#     for j in 1:50
#         # ns = rand(is)
#         poss = findall(<(6), shuffle(as))
#         for i in poss
#             push!(df, [as[i], 4.0, 5])
#         end
#     end
#     return df
# end
