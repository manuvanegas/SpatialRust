function show_cy(model::ABM)
    return collect(1:5)
end

function select_sampled_rusts()
end


function age_and_area(rust::Rust, df::DataFrame)
    push!(df, (round(Int, (rust.age / 7)), rust.area))
end

function age_and_spores(rust::Rust, df::DataFrame)
    push!(df, (round(Int, (rust.age / 7)), rust.spores))
end

function seven_weeks(df::DataFrame)::Array{Float64}
    areas = fill(-1.0, 8)
    for (row, _) in enumerate(df.age)
        areas[row] = df[row, :area_median]
    end
    return areas
end

function areas_per_age(model::ABM)::Array{Float64}
    sampled_rusts = Iterators.filter(r -> r isa Rust && !isdisjoint(model.current.cycle, r.sample_cycle), allagents(model))
    if isempty(sampled_rusts)
        return [-1.0]
    else
        df = DataFrame(age = Int[], area = Float64[])
        map(r -> age_and_area(r, df), sampled_rusts)
        df2 = combine(groupby(df, :age), :area => median)

        return seven_weeks(sort!(df2[df2.age .< 8, :], :age))
    end
end

function spores_per_age(model::ABM)::Array{Float64}
    sampled_rusts = Iterators.filter(r -> r isa Rust && !isdisjoint(model.current.cycle, r.sample_cycle), allagents(model))
    if isempty(sampled_rusts)
        return [-1.0]
    else
        df = DataFrame(age = Int[], area = Float64[])
        map(r -> age_and_spores(r, df), sampled_rusts)
        df2 = combine(groupby(df, :age), :area => median)

        return seven_weeks(df2)
    end
end

function total_lesion_area(model::ABM)::Array{Float64}
    areas = Float64[]
    for cycle in model.current.cycle
        sampled_rusts = Iterators.filter(r -> cycle in r.sample_cycle && r isa Rust, allagents(model))
        if isempty(sampled_rusts)
            push!(areas, -1.0)
        else
            push!(areas, median(map(rr -> rr.area * rr.n_lesions, sampled_rusts)))
        end
    end
    return areas
end

function fallen_coffees(model::ABM)::Array{Float64}
    falls = Float64[]
    for cycle in model.current.cycle
        sampled_cs = Iterators.filter(c -> cycle in c.sample_cycle && c isa Coffee, allagents(model))
        push!(falls, count(cc -> cc.exh_countdown > 0, sampled_cs) / length(collect(sampled_cs)))
    end
    return falls
end

function coffee_production(model::ABM)::Float64
    if model.current.ticks in (model.pars.switch_cycles .+ 1)
        return median(map(cc -> cc.production, Iterators.filter(c -> c isa Coffee && maximum(model.current.cycle) ∈ c.sample_cycle, allagents(model))))
    else
        return -1.0
    end
end

## ABC distance

function ABC_distance(exp_data::Vector{Float64}, model_data)
end
