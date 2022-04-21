## Getting median lesion and spore areas per age + cycle

function age_area_spores!(rust::Rust, cycle::Int, df::DataFrame)
    let r::Rust = rust, c::Int = cycle
        for i in 1:r.n_lesions
            if r.state[4, i] < 53.0
                push!(df, c, (div(r.state[4, i], 7.0, RoundNearest), r.state[2, i]))
            end
        end
    end
end

function d_per_ages(model::ABM)::DataFrame
    sampled_rusts = Iterators.filter(r -> r isa Rust && !isdisjoint(model.current.cycle, r.sample_cycle) && any(r.age .< 53), allagents(model))
    # used 53/7 = 7.57, which rounds to 8. We want all ages until 7

    if isempty(sampled_rusts)
        return DataFrame(cycle = -1, age = -1.0, area_m = -1.0, spores_m = -1.0, tick = model.current.ticks)
        # return df2
    else
        df = DataFrame(cycle = Int[], age = Float64[], area = Float64[])

        for cycle in model.current.cycle
            foreach(r -> age_area_spores!(r, cycle, df), Iterators.filter(r -> cycle in r.sample_cycle, sampled_rusts))
            #c_sampled_rusts = Iterators.filter(r -> cycle in r.sample_cycle, sampled_rusts)
            #if !isempty(c_sampled_rusts)
            #    foreach(r -> age_area_spores!(r, cycle, df), c_sampled_rusts)
            #end
        end
        if isempty(df)
            return DataFrame(age = -1, cycle = -1, area_m = -1.0, spores_m = -1.0, tick = model.current.ticks)
        else
            df2 = combine(groupby(df, [:age, :cycle]), [:area => median => :area_m])
            df2.spores_m = df2.area_m * model.pars.spore_pct
            df2.tick .= model.current.ticks
        end
        # if size(df2)[1] == 0
        #     df2 = DataFrame(age = -1, cycle = -1, area_m = -1.0, spores_m = -1.0, tick = model.current.ticks)
        # end
    end
    return df2
end

## Getting median lesion and spore areas and % of exhausted(fallen) coffees per cycle

# med_area(rusts::Base.Iterators.Filter)::Float64 = isempty(rusts) ? -1.0 : median(map(rr -> rr.area * rr.n_lesions, rusts))
# med_spores(rusts::Base.Iterators.Filter)::Float64 = isempty(rusts) ? -1.0 : median(map(rr -> rr.spores * rr.n_lesions, rusts))
# rel_area(areas::Vector{Float64}, maxn::Int)::Float64 = sum(areas) / maxn
rel_area(rust::Rust, maxn::Int) = sum(rust.area) / maxn
rel_spore(rust::Rust, maxn::Int) = sum(rust.area) / maxn

# function rel_areas(rusts::Base.Iterators.Filter, maxn::Int)::Vector{Float64}
#     # areas = []
#     # for r in rusts
#     #     push!(areas, rel_area(r.area, maxn))
#     # end
#     return rel_area.(rusts, maxn)
# end

# function rel_spores(rusts::Base.Iterators.Filter, maxn::Int)::Vector{Float64}
#     # spores = zeros(length(rusts))
#     # for (i, r) in enumerate(rusts)
#     #     spores[i] = rel_area(r.spores, maxn)
#     # end
#     return rel_spore.(rusts, maxn)
# end

med_area(rusts::Base.Iterators.Filter, maxn::Int)::Float64 = isempty(rusts) ? -1.0 : median(rel_area.(rusts, maxn))
med_spores(rusts::Base.Iterators.Filter, maxn::Int)::Float64 = isempty(rusts) ? -1.0 : median(rel_spore.(rusts,maxn))
p_fallen(coffees::Base.Iterators.Filter)::Float64 = count(cc -> cc.exh_countdown > 0, coffees) / length(collect(coffees))

function d_per_cycles(model::ABM)::DataFrame
    sampled_rusts = Iterators.filter(r -> r isa Rust && !isdisjoint(model.current.cycle, r.sample_cycle), allagents(model))

    if isempty(sampled_rusts)
        df = DataFrame(cycle = Int[], fallen = Float64[])
        for cycle in model.current.cycle
            sampled_cs = Iterators.filter(c -> c isa Coffee && cycle in c.sample_cycle, allagents(model))
            push!(df, [cycle, count(cc -> cc.exh_countdown > 0, sampled_cs) / length(collect(sampled_cs)) ] )
        end
        df.tick .= model.current.ticks
        df.area_m .= -1.0
        df.spores_m .= -1.0
        # return falls
    else
        df = DataFrame(cycle = Int[], area_m = Float64[], spores_m = Float64[], fallen = Float64[])
        for cycle in model.current.cycle
            c_sampled_rusts = Iterators.filter(r -> cycle in r.sample_cycle, sampled_rusts)
            sampled_cs = Iterators.filter(c -> c isa Coffee && cycle in c.sample_cycle, allagents(model))
            push!(df, [cycle,
                        med_area(c_sampled_rusts, model.pars.max_lesions),
                        med_spores(c_sampled_rusts, model.pars.max_lesions),
                        p_fallen(sampled_cs)])
        end
        df.tick .= model.current.ticks
        # return df
    end
    return df
end

## Getting median coffee production

function prod_metrics(model::ABM)::Array{Function}
    tick(model::ABM)::Int = model.current.ticks

    function coffee_production(model::ABM)::Float64
        return median(map(cc -> (cc.production / model.pars.harvest_cycle) , Iterators.filter(c -> c isa Coffee && (maximum(model.current.cycle) + 1) ∈ c.sample_cycle, allagents(model))))
    end
    return [tick, coffee_production]
end

## Getting raw lesion area+spore and fallen data

function get_rust_state(rust::Rust)
    let r::Rust = rust
        # areas = r.state[[2, 4],:][r.state[4,:] .< 53.0]
        rdf = DataFrame((r.state[2:4, (r.state[4,:] .< 53.0)])', [:area, :spore, :age])
        rdf[:, :age] .= div.(rdf.age, 7.0, RoundNearest)
        return rdf
    end
end

function SpatialRust.ind_data(model::ABM)
    df = DataFrame(tick = Int[], cycle = Int[], age = Int[], area = Float64[], spore = Float64[], exh = Bool[], id = Int[])
    # println(model.current.cycle)
    for cycle in model.current.cycle
        for cof in Iterators.filter(c -> c isa Coffee && cycle in c.sample_cycle, allagents(model))
            if cof.hg_id == 0
                push!(df, (model.current.ticks, cycle, -1, -1.0, -1.0, (cof.exh_countdown > 0), cof.id))
            else
                rust_df = SpatialRust.get_rust_state(model[cof.hg_id])
                rust_df[:, :tick] .= model.current.ticks
                rust_df[:, :cycle] .= cycle
                rust_df[:, :spore] .= @. rust_df.spore * rust_df.area * model.pars.spore_pct
                rust_df[:, :exh].= cof.exh_countdown > 0
                rust_df[:, :id] .= cof.id

                append!(df, rust_df)
            end
        end
    end
    if model.current.cycle == [5, 6] && model.current.ticks >= 84
        println(first(df,5))
        println(collect(Iterators.filter(c -> c isa Coffee && !isdisjoint(model.current.cycle, c.sample_cycle), allagents(model)))[1:3])
    end
    return df
end

## Process raw data to obtain per_age and per_cycle dfs

function update_dfs!(per_age::DataFrame, per_cycle::DataFrame, data::DataFrame, max_lesions::Int)

    append!(
    per_age,
    combine(groupby(data, [:tick, :age, :cycle]),
        [:area => median5 => :area_m, :spore => median5 => :spores_m]
        )
    )

    let nl::Int = max_lesions
        sum_area(col::SubArray) = sum(col) / nl
        x -> count(x) / nrow(x)

        intermediate = combine(groupby(data, [:tick, :cycle, :id]),
            [:area => sum_area => :s_area, :spore => sum_area => :s_spore, :exh => first => :fallen]
            )

        append!(
        per_cycle,
        combine(groupby(intermediate, [:tick, :cycle]),
            [:s_area => median5 => :area_m, :s_spore => median5 => :spores_m, :fallen => pct => :fallen]
            )
        )
    end
end

pct(col::SubArray) = count(col) / length(col)
median5(col::SubArray) = median(col) * 5
