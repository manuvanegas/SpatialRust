## Qualitative patterns

function get_prod_df!(df::DataFrame, model::ABM)
    # df[!, :id] = map(c -> c.id, values(model.agents))
    df[!, :production] = map(getprod, values(model.agents))
end

getprod(c::Coffee) = c.production

function add_clr_areas!(df::DataFrame, model::ABM)
    df[!, :clr_area] = map(finalrust, values(model.agents))
    # collect(sum(c.areas) for c in values(model.agents))

    # return df
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
    # return sum(c.areas)
end

function calc_exh_perc(model::ABM)
    sum(map(c -> c.exh_countdown > 0, values(model.agents))) / length(model.agents)
end

## Quantitative patterns

surveyed_today(c::Coffee, cycle::Vector{Int})::Bool = c.sample_cycle ∈ cycle && c.exh_countdown == 0

function get_weekly_data(model::ABM, cycle_n::Vector{Int}, max_age::Int, cycle_last::Bool)
    survey_cofs = Iterators.filter(c -> surveyed_today(c, cycle_n), values(model.agents))

    let df_i = DataFrame(age = Int[], area = Float64[], spore = Float64[], nl = Int[], id = Int[])
        for cof in survey_cofs
            # within_age = findall(<=(max_age), cof.ages)
            # for l in within_age
            #     push!(df_i, survey_lesion(cof, l))
            # end
            df_c = DataFrame()
            df_c[!, :age] = cof.ages
            df_c[!, :area] = cof.areas
            df_c[!, :spore] = cof.spores
            df_c[!, :nl] .= cof.n_lesions
            df_c[!, :id] .= cof.id
            append!(df_i, df_c)
        end
        filter!(:age => <=(max_age), df_i)
        if isempty(df_i)
            return DataFrame(age = Int[],
            med_area = Float64[], med_spore = Float64[],
            med_nl = Float64[], occup = Float64[])
            # return DataFrame(age = -10, med_area = missing, med_spore = missing, med_nl = missing, occup = missing)
            # return DataFrame(age = -10, med_area = -10.0, med_spore = -10.0, med_nl = -10.0, occup = -10.0)
            # TODO: maybe NaNs? maybe age = -10 and rest NaNs/missings
        else
            nlesions_age = combine(groupby(df_i, :id), :age => maximum => :age, :nl => first => :nl)
            df_nlesions = combine(groupby(nlesions_age, :age), :nl => median => :med_nl)
            # dfbyage = groupby(df_i, :age)
            df_areas = combine(groupby(df_i, :age),
            :area => median => :med_area,
            :spore => median => :med_spore,
            :nl => first => :nl
            )
            if cycle_last
                ncofs = length(collect(survey_cofs))
                select!(df_areas, Not(:nl), :nl => (n -> n / ncofs) => :occup)
            else
                select!(df_areas, Not(:nl))
                df_areas[!, :occup] .= 0.0
            end
            df = outerjoin(df_areas, df_nlesions, on = :age)
            return df
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

# ## Getting median lesion and spore areas per age + cycle
#
# function age_area_spores!(rust::Rust, cycle::Int, df::DataFrame)
#     let r::Rust = rust, c::Int = cycle
#         for i in 1:r.n_lesions
#             if r.state[4, i] < 53.0
#                 push!(df, c, (div(r.state[4, i], 7.0, RoundNearest), r.state[2, i]))
#             end
#         end
#     end
# end
#
# function d_per_ages(model::ABM)::DataFrame
#     sampled_rusts = Iterators.filter(r -> r isa Rust && !isdisjoint(model.current.cycle, r.sample_cycle) && any(r.age .< 53), allagents(model))
#     # used 53/7 = 7.57, which rounds to 8. We want all ages until 7
#
#     if isempty(sampled_rusts)
#         return DataFrame(cycle = -1, age = -1.0, area_m = -1.0, spores_m = -1.0, tick = model.current.ticks)
#         # return df2
#     else
#         df = DataFrame(cycle = Int[], age = Float64[], area = Float64[])
#
#         for cycle in model.current.cycle
#             foreach(r -> age_area_spores!(r, cycle, df), Iterators.filter(r -> cycle in r.sample_cycle, sampled_rusts))
#             #c_sampled_rusts = Iterators.filter(r -> cycle in r.sample_cycle, sampled_rusts)
#             #if !isempty(c_sampled_rusts)
#             #    foreach(r -> age_area_spores!(r, cycle, df), c_sampled_rusts)
#             #end
#         end
#         if isempty(df)
#             return DataFrame(age = -1, cycle = -1, area_m = -1.0, spores_m = -1.0, tick = model.current.ticks)
#         else
#             df2 = combine(groupby(df, [:age, :cycle]), [:area => median => :area_m])
#             df2.spores_m = df2.area_m * model.pars.spore_pct
#             df2.tick .= model.current.ticks
#         end
#         # if size(df2)[1] == 0
#         #     df2 = DataFrame(age = -1, cycle = -1, area_m = -1.0, spores_m = -1.0, tick = model.current.ticks)
#         # end
#     end
#     return df2
# end
#
# ## Getting median lesion and spore areas and % of exhausted(fallen) coffees per cycle
#
# # med_area(rusts::Base.Iterators.Filter)::Float64 = isempty(rusts) ? -1.0 : median(map(rr -> rr.area * rr.n_lesions, rusts))
# # med_spores(rusts::Base.Iterators.Filter)::Float64 = isempty(rusts) ? -1.0 : median(map(rr -> rr.spores * rr.n_lesions, rusts))
# # rel_area(areas::Vector{Float64}, maxn::Int)::Float64 = sum(areas) / maxn
# rel_area(rust::Rust, maxn::Int) = sum(rust.area) / maxn
# rel_spore(rust::Rust, maxn::Int) = sum(rust.area) / maxn
#
# # function rel_areas(rusts::Base.Iterators.Filter, maxn::Int)::Vector{Float64}
# #     # areas = []
# #     # for r in rusts
# #     #     push!(areas, rel_area(r.area, maxn))
# #     # end
# #     return rel_area.(rusts, maxn)
# # end
#
# # function rel_spores(rusts::Base.Iterators.Filter, maxn::Int)::Vector{Float64}
# #     # spores = zeros(length(rusts))
# #     # for (i, r) in enumerate(rusts)
# #     #     spores[i] = rel_area(r.spores, maxn)
# #     # end
# #     return rel_spore.(rusts, maxn)
# # end
#
# med_area(rusts::Base.Iterators.Filter, maxn::Int)::Float64 = isempty(rusts) ? -1.0 : median(rel_area.(rusts, maxn))
# med_spores(rusts::Base.Iterators.Filter, maxn::Int)::Float64 = isempty(rusts) ? -1.0 : median(rel_spore.(rusts,maxn))
# p_fallen(coffees::Base.Iterators.Filter)::Float64 = count(cc -> cc.exh_countdown > 0, coffees) / length(collect(coffees))
#
# function d_per_cycles(model::ABM)::DataFrame
#     sampled_rusts = Iterators.filter(r -> r isa Rust && !isdisjoint(model.current.cycle, r.sample_cycle), allagents(model))
#
#     if isempty(sampled_rusts)
#         df = DataFrame(cycle = Int[], fallen = Float64[])
#         for cycle in model.current.cycle
#             sampled_cs = Iterators.filter(c -> c isa Coffee && cycle in c.sample_cycle, allagents(model))
#             push!(df, [cycle, count(cc -> cc.exh_countdown > 0, sampled_cs) / length(collect(sampled_cs)) ] )
#         end
#         df.tick .= model.current.ticks
#         df.area_m .= -1.0
#         df.spores_m .= -1.0
#         # return falls
#     else
#         df = DataFrame(cycle = Int[], area_m = Float64[], spores_m = Float64[], fallen = Float64[])
#         for cycle in model.current.cycle
#             c_sampled_rusts = Iterators.filter(r -> cycle in r.sample_cycle, sampled_rusts)
#             sampled_cs = Iterators.filter(c -> c isa Coffee && cycle in c.sample_cycle, allagents(model))
#             push!(df, [cycle,
#                         med_area(c_sampled_rusts, model.pars.max_lesions),
#                         med_spores(c_sampled_rusts, model.pars.max_lesions),
#                         p_fallen(sampled_cs)])
#         end
#         df.tick .= model.current.ticks
#         # return df
#     end
#     return df
# end
#
## Getting median coffee production

# function prod_metrics(model::ABM)::Array{Function}
#     tick(model::ABM)::Int = model.current.ticks
#
#     function coffee_production(model::ABM)::Float64
#         return median(map(cc -> (cc.production / model.pars.harvest_day) , Iterators.filter(c -> c isa Coffee && (maximum(model.current.cycle) + 1) ∈ c.sample_cycle, allagents(model))))
#     end
#     return [tick, coffee_production]
# end

# function coffee_prod(model::ABM)::DataFrame
#     let maxc = maximum(model.current.cycle) + 1
#         return DataFrame(
#             tick = model.current.ticks,
#             coffee_production = median(map(getprod,
#                 Iterators.filter(c -> (maxc ∈ c.sample_cycle), allagents(model))
#                 )) 
#                 )
#     end
# end

# getprod(c::Coffee)::Float64 = c.production

# ## Getting raw lesion area+spore and fallen data

# function get_rust_state(rust::Coffee)::DataFrame
#     let r::Rust = rust
#         # areas = r.state[[2, 4],:][r.state[4,:] .< 53.0]
#         rdf = DataFrame((r.state[2:4, (r.state[4,:] .< 53.0)])', [:area, :spore, :age])
#         rdf[:, :age] .= div.(rdf.age, 7.0, RoundNearest)
#         return rdf
#     end
# end

# function collect_diff_cof(model::ABM)::DataFrame
#     rustdf = DataFrame(tick = Int[], cycle = Int[], id = Int[], age = Int[], area = Float64[], spore = Float64[])
#     cofdf = DataFrame(tick = Int[], cycle = Int[], exh = Bool[], prod = Float64[])

#     let harv = model.pars.harvest_day, cticks = model.current.ticks, sprpct = model.pars.spore_pct
#         for cycle in model.current.cycle
#             for (cof, cof2) in zip(
#                 Iterators.filter(c -> c isa Coffee && cycle in c.sample_cycle, allagents(model)),
#                 Iterators.filter(c -> c isa Coffee && (cycle + 1) in c.sample_cycle, allagents(model))
#                 )
#                 push!(cofdf, (cticks, cycle, (cof.exh_countdown > 0), (cof2.production / harv)))
#                 if cof.hg_id != 0
#                 #     push!(df, (model.current.ticks, cycle, -1, missing, missing, cof.id))
#                 # else
#                     rust_df = get_rust_state(model[cof.hg_id])
#                     # if isempty(rust_df)
#                     #     push!(df, (model.current.ticks, cycle, -1, missing, missing, cof.id))
#                     # else
#                         rust_df[:, :tick] .= cticks
#                         rust_df[:, :cycle] .= cycle
#                         @. rust_df[:, :spore] = rust_df.spore * rust_df.area * sprpct
#                         rust_df[:, :id] .= cof.id
#                         append!(rustdf, rust_df)
#                     # end
#                 end
#             end
#         end
#         if isempty(rustdf)
#             for c in model.current.cycle
#                 push!(rustdf, (cticks, c, 0, -1, NaN, NaN))
#             end
#             # allowmissing!(rustdf, [:area, :spore])
#         end
#     end

#     return DataFrame(rust = rustdf, prod = cofdf)
# end

# function collect_same_cof(model::ABM)::DataFrame
#     rustdf = DataFrame(tick = Int[], cycle = Int[], id = Int[], age = Int[], area = Float64[], spore = Float64[])
#     cofdf = DataFrame(tick = Int[], cycle = Int[], exh = Bool[])

#     let cticks = model.current.ticks, sprpct = model.pars.spore_pct
#         for cycle in model.current.cycle
#             for cof in Iterators.filter(c -> c isa Coffee && cycle in c.sample_cycle, allagents(model))
#                 push!(cofdf, (cticks, cycle, (cof.exh_countdown > 0)))
#                 if cof.hg_id != 0
#                 #     push!(df, (model.current.ticks, cycle, -1, missing, missing, cof.id))
#                 # else
#                     rust_df = get_rust_state(model[cof.hg_id])
#                     # if isempty(rust_df)
#                     #     push!(df, (model.current.ticks, cycle, -1, missing, missing, cof.id))
#                     # else
#                         rust_df[:, :tick] .= cticks
#                         rust_df[:, :cycle] .= cycle
#                         @. rust_df[:, :spore] = rust_df.spore * rust_df.area * sprpct
#                         rust_df[:, :id] .= cof.id
#                         append!(rustdf, rust_df)
#                     # end
#                 end
#             end
#         end
#         if isempty(rustdf)
#             for c in model.current.cycle
#                 push!(rustdf, (cticks, c, 0, -1, NaN, NaN))
#             end
#         end
#     end

#     return DataFrame(rust = rustdf, prod = cofdf)
# end

# function ind_data(model::ABM)::DataFrame
#     # if (length(model.current.cycle) == 1 && # cycle overlapping starts after cycle #5
#     #     model.current.ticks in model.pars.switch_cycles)
#     #     return collect_diff_cof(model)
#     # else
#         return collect_same_cof(model)
#     # end

#     # if all(model.current.cycle .< 6)
#     #     if model.current.ticks in model.pars.switch_cycles
#     #         collect_same_cof(model)
#     #     else
#     #         collect_just_rustd()
#     #     end
#     # else
#     #     if model.current.ticks in model.pars.switch_cycles
#     #         return collect_diff_cof(model)
#     #     else
#     #         return collect_same_cof(model)
#     #     end
#     # end
# end

# ## Process raw data to obtain per_age and per_cycle dfs

# function update_dfs!(
#     per_age::DataFrame,
#     per_cycle::DataFrame,
#     # per_plant::DataFrame,
#     rdata::DataFrame,
#     pdata::DataFrame)

#     append!(
#     per_age,
#     combine(groupby(rdata, [:tick, :cycle, :age]),
#         [:area => nanmedian5 => :area_m, :spore => nanmedian5 => :spores_m] )
#     )


#     # sum_area(col::SubArray) = let nl::Int = max_lesions
#     #     sum(col) / nl
#     # end
#     # rust_cycle = @chain rdata begin
#     #     @by([:tick, :cycle, :id], :s_area = nansum(:area), :s_spore = nansum(:spore))
#     #     @by([:tick, :cycle], :area_m = nanmedian5(:s_area), :spores_m = nanmedian5(:s_spore))
#     # end
#     #
#     # data_cycle = leftjoin(
#     # combine(groupby(pdata, [:tick, :cycle]), [:exh => pct => :fallen]),
#     # rust_cycle,
#     # on = [:tick, :cycle]
#     # )

#     let data_cycle = combine(groupby(rdata, [:tick, :cycle, :id]),
#     [:area => nansum => :s_area, :spore => nansum => :s_spore]) |>
#     x -> combine(groupby(x, [:tick, :cycle]),
#     [:s_area => nanmedian5 => :area_m, :s_spore => nanmedian5 => :spores_m]) |>
#     r -> leftjoin(
#     combine(groupby(pdata, [:tick, :cycle]),
#         [:exh => pct => :fallen]),
#     r,
#     on = [:tick, :cycle]
#     )

#     data_cycle[:, [:area_m, :spores_m]] .= ifelse.(
#         ismissing.(data_cycle[!, [:area_m, :spores_m]]),
#         NaN, data_cycle[!, [:area_m, :spores_m]]
#         )

#     # penalty = -1.0
#     # if any(ismissing.(data_cycle.area_m))
#     #     # transform!(data_cycle, [:area_m => x -> coalesce(x, penalty) => :area_m,
#     #     #     :spore_m => x -> coalesce(x, penalty) => :spore_m])
#     #     allowmissing!(per_cycle, [:area_m, :spores_m])
#     # end

#         # intermediate = combine(groupby(rdata, [:tick, :cycle, :id]),
#         #     [:area => (sum∘skipmissing) => :s_area, :spore => (sum∘skipmissing) => :s_spore]
#         #     )

#         append!(per_cycle, data_cycle)
#     end

#     #     if length(g_pdata) == 1
#     #         append!(per_plant,
#     #         combine(g_pdata, :prod => nanmedian => :coffee_production)
#     #         )
#     #     else # if there are two groups, we just need the later cycle
#     #         append!(per_plant,
#     #         combine(g_pdata[2], :tick, :cycle, :prod => nanmedian => :coffee_production)
#     #         )
#     #     end
# end

# pct(col::SubArray) = count(col) / length(col)
# median5(col::Union{SubArray, Base.SkipMissing}) = ifelse(isempty(col), missing, median(col) * 5)
# # SpatialRust.median5(col::Base.SkipMissing) = median(col) * 5
# nanmedian5(col::SubArray) = nanmedian(col) * 5
