## Qualitative patterns

function get_prod_df!(df::DataFrame, model::ABM)
    # df[!, :id] = map(c -> c.id, values(model.agents))
    df[!, :production] = getprod.(model.agents)
end

getprod(c::Coffee) = c.production

function add_clr_areas!(df::DataFrame, model::ABM)
    df[!, :clr_area] = finalrust.(model.agents)
end

function finalrust(c::Coffee)
    # area = sum(c.areas)
    # if area == 0.0 
    #     if c.exh_countdown == 0
    #         return -10.0
    #     else
    #         return 25.0
    #     end
    # else
    #     return area
    # end
    # area = sum(c.areas)
    # if area == 0.0 && c.exh_countdown == 0
    #     return -10.0
    # else
    #     return area
    # end
    if c.exh_countdown > 0
        return 24.0 + (sum(c.areas) / 25.0)
    else
        return sum(c.areas)
    end
end

function calc_exh_perc(model::ABM)
    sum(map(c -> c.exh_countdown > 0, model.agents)) / length(model.agents)
end

## Quantitative patterns

surveyed_today(c::Coffee, cycle::Vector{Int})::Bool = c.sample_cycle ∈ cycle && c.exh_countdown == 0

function get_weekly_data(model::ABM, cycle_n::Vector{Int}, max_age::Int, cycle_last::Bool)
    survey_cofs = Iterators.filter(c -> surveyed_today(c, cycle_n), model.agents)
    spore_pct = model.rustpars.spore_pct
    avail_sites_wpct = length(collect(survey_cofs)) * model.rustpars.max_lesions * inv(100.0)

    let df_i = DataFrame(age = Int[], area = Float64[], spore = Float64[], nl = Int[], id = Int[])
        for cof in survey_cofs
            # within_age = findall(<=(max_age), cof.ages)
            # for l in within_age
            #     push!(df_i, survey_lesion(cof, l))
            # end
            df_c = DataFrame()
            df_c[!, :age] = cof.ages
            df_c[!, :area] = cof.areas .* 7.15 # areas were normalized assuming a max of ~7.15 cm2
            df_c[!, :spore] = cof.spores .* cof.areas .* spore_pct .* 7.15
            df_c[!, :nl] .= cof.n_lesions
            df_c[!, :id] .= cof.id
            append!(df_i, df_c)
        end
        filter!(:age => <=(max_age), df_i)
        if isempty(df_i)
            return DataFrame(age = Int[],
            med_area = Float64[], med_spore = Float64[],
            med_nl = Float64[], occup = Float64[])
        else
            nlesions_age = combine(groupby(df_i, :id), :age => maximum => :age, :nl => first => :nl)
            df_nlesions = combine(groupby(nlesions_age, :age), :nl => median => :med_nl)

            df_areas = combine(
                groupby(df_i, :age),
                :area => median => :med_area,
                :spore => median => :med_spore,
                :nl => sum => :totnl
            )
            if cycle_last
                select!(df_areas, Not(:totnl), :totnl => (n -> n / avail_sites_wpct) => :occup)
            else
                select!(df_areas, Not(:totnl))
                df_areas[!, :occup] .= 0.0
            end

            return outerjoin(df_areas, df_nlesions, on = :age)
        end
    end
end

# # prob wont work
# function get_weekly_data_2017_2(model::ABM, s::Int)
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
