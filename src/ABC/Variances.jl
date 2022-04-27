## Get variances
function σ2(folder::String)
    v_a = σ2_a(folder)
    v_c = σ2_c(folder)
    v_p = σ2_p(folder)

    return v_a, v_c, v_p
end

function σ2_a(folder::String)
    files = readdir(string(folder,"ages"), join = true, sort = false)
    @inline v_itr(arr) = ((r.tick, r.cycle, r.age) => (r.area_m, r.spores_m) for r in eachrow(arr))
    vars = @distributed merge for f in files
        fit!(GroupBy(Tuple, Series(2Variance(), 2Counter())), v_itr(DataFrame(Arrow.Table(f))) )
    end

    return dfize(vars, :ages)
end

function σ2_c(folder::String)
    files = readdir(string(folder,"cycles"), join = true, sort = false)
    @inline v_itr(arr) = ((r.tick, r.cycle) => (r.area_m, r.spores_m, r.fallen) for r in eachrow(arr))
    vars = @distributed merge for f in files
        fit!(GroupBy(Tuple, Series(3Variance(), 3Counter())), v_itr(DataFrame(Arrow.Table(f))) )
    end

    return dfize(vars, :cycles)
end

function σ2_p(folder::String)
    files = readdir(string(folder,"prod"), join = true, sort = false)
    @inline v_itr(arr) = (r.tick => r.coffee_production for r in eachrow(arr))
    vars = @distributed merge for f in files
        fit!(GroupBy(Int, Series(Variance(), Counter())), v_itr(DataFrame(Arrow.Table(f))) )
    end

    return dfize(vars, :prod)
end

function dfize(ostats::GroupBy, folder::Symbol) # "dataframe-ize"
    groups = keys(value(ostats))
    if folder == :ages
        var_df = DataFrame(tick = Int64[],
                            cycle = Int64[],
                            age = Int64[],
                            v_area = Float64[],
                            v_spore = Float64[],
                            n_area = Int64[],
                            n_spore = Int64[])
        for k in keys(value(ostats))
            row::Vector{Union{Int64, Float64}} = collect(k)
            append!(row, collect(value.(value(ostats[k].stats[1]))))
            append!(row, collect(value.(value(ostats[k].stats[2]))))
            push!(var_df, row)
        end
    elseif folder == :cycles
        var_df = DataFrame(tick = Int64[],
                            cycle = Int64[],
                            v_area = Float64[],
                            v_spore = Float64[],
                            v_fallen = Float64[],
                            n_area = Int64[],
                            n_spore = Int64[],
                            n_fallen = Int64[])
        for k in keys(value(ostats))
            row::Vector{Union{Int64, Float64}} = collect(k)
            append!(row, collect(value.(value(ostats[k].stats[1]))))
            append!(row, collect(value.(value(ostats[k].stats[2]))))
            push!(var_df, row)
        end
    else
        var_df = DataFrame(tick = Int64[],
                            v_prod = Float64[],
                            n_prod = Int64[])
        for k in keys(value(ostats))
            row::Vector{Union{Int64, Float64}} = [k]
            append!(row, collect(value(ostats[k].stats[1])))
            append!(row, collect(value(ostats[k].stats[2])))
            push!(var_df, row)
        end
    end

    return var_df
end
