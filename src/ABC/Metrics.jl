function d_per_ages(model::ABM)::DataFrame
    sampled_rusts = Iterators.filter(r -> r isa Rust && !isdisjoint(model.current.cycle, r.sample_cycle), allagents(model))

    if isempty(sampled_rusts)
        df2 = DataFrame(age = -1, cycle = -1, area_m = -1, spores_m = -1.0, tick = model.current.ticks)
        # return df2
    else
        age_area_spores!(rust::Rust, cycle::Int, df::DataFrame) = push!(df, (round(Int, (rust.age / 7)), cycle, rust.area, rust.spores))

        df = DataFrame(age = Int[], cycle = Int[], area = Float64[], spores = Float64[])

        for cycle in model.current.cycle
            c_sampled_rusts = Iterators.filter(r -> cycle in r.sample_cycle && r isa Rust, sampled_rusts)
            map(r -> age_area_spores!(r, cycle, df), c_sampled_rusts)
        end
        df2 = combine(groupby(df, [:age, :cycle]), [:area => median => :area_m, :spores => median => :spores_m])
        df2.tick .= model.current.ticks

        #return seven_weeks(sort!(df2[df2.age .< 8, :], :age))
        # return df2[df2.age .< 8, :]
        df2 = df2[df2.age .< 8, :]
        if size(df2)[1] == 0
            df2 = DataFrame(age = -1, cycle = -1, area_m = -1.0, spores_m = -1.0, tick = model.current.ticks)
        end
    end
    return df2
end

function d_per_cycles(model::ABM)::DataFrame
    sampled_rusts = Iterators.filter(r -> r isa Rust && !isdisjoint(model.current.cycle, r.sample_cycle), allagents(model))

    if isempty(sampled_rusts)
        df = DataFrame(cycle = Int[], fallen = Float64[])
        for cycle in model.current.cycle
            sampled_cs = Iterators.filter(c -> cycle in c.sample_cycle && c isa Coffee, allagents(model))
            push!(df, [cycle, count(cc -> cc.exh_countdown > 0, sampled_cs) / length(collect(sampled_cs)) ] )
        end
        df.tick .= model.current.ticks
        df.area_m .= -1.0
        df.spores_m .= -1.0
        # return falls
    else
        med_area(rusts::Base.Iterators.Filter)::Float64 = isempty(rusts) ? -1.0 : median(map(rr -> rr.area * rr.n_lesions, rusts))
        med_spores(rusts::Base.Iterators.Filter)::Float64 = isempty(rusts) ? -1.0 : median(map(rr -> rr.spores * rr.n_lesions, rusts))
        p_fallen(coffees::Base.Iterators.Filter)::Float64 = count(cc -> cc.exh_countdown > 0, coffees) / length(collect(coffees))
        df = DataFrame(cycle = Int[], area_m = Float64[], spores_m = Float64[], fallen = Float64[])
        for cycle in model.current.cycle
            c_sampled_rusts = Iterators.filter(r -> cycle in r.sample_cycle && r isa Rust, sampled_rusts)
            sampled_cs = Iterators.filter(c -> cycle in c.sample_cycle && c isa Coffee, allagents(model))
            push!(df, [cycle, med_area(c_sampled_rusts), med_spores(c_sampled_rusts), p_fallen(sampled_cs)])
        end
        df.tick .= model.current.ticks
        # return df
    end
    return df
end

function prod_metrics(model::ABM)::Array{Function}
    tick(model::ABM)::Int = model.current.ticks

    function coffee_production(model::ABM)::Float64
        return median(map(cc -> cc.production, Iterators.filter(c -> c isa Coffee && (maximum(model.current.cycle) + 1) ∈ c.sample_cycle, allagents(model))))
    end
    return [tick, coffee_production]
end
