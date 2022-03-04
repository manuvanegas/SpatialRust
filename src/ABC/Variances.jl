## Get variances
function σ2(folder::Symbol)::Vector{Float64}
    files = readdir(string("/scratch/mvanega1/ABC/", folder), join = true, sort = false)
    if folder == :ages
        @inline v_itr(arr) = ((r.ticks, r.age) => (r.area_m, r.spores_m) for r in eachrow(DataFrame(arr)))
        vars = @distributed merge for f in files
            fit!(GroupBy(Tuple, Series(2Variance(), 2Counter())), v_itr(Arrow.Table(f)))
        end
    elseif folder == :cycles
        @inline v_itr(arr) = ((r.ticks, r.cycle) => (r.area_m, r.spores_m, r.fallen) for r in eachrow(DataFrame(arr)))
        vars = @distributed merge for f in files
            fit!(GroupBy(Tuple, Series(3Variance(), 3Counter())), v_itr(Arrow.Table(f)))
        end
    else
        @inline v_itr(arr) = (r.ticks => r.coffee_production for r in eachrow(DataFrame(arr)))
        vars = @distributed merge for f in files
            fit!(GroupBy(Int, Series(Variance(), Counter())), v_itr(Arrow.Table(f)))
        end
    end
    return dfize(vars, folder)
end

function dfize(ostats::GroupBy, folder::Symbol) # "dataframe-ize"
    groups = keys(value(ostats))
    if folder == :ages
        var_df = DataFrame(tick = Int64[],
                            age = Int64[],
                            v_age = Float64[],
                            v_spore = Float64[],
                            n_age = Float64[],
                            n_spore = Float64[])
        for k in keys(value(ostats))
            row::Vector{Union{Int64, Float64}} = collect(k)
            append!(row, collect(value.(value(ostats[k].stats[1]))))
            append!(row, collect(value.(value(ostats[k].stats[2]))))
            push!(var_df, row)
        end
    elseif folder == :cycles
        var_df = DataFrame(tick = Int64[],
                            cycle = Int64[],
                            v_age = Float64[],
                            v_spore = Float64[],
                            v_fallen = Float64[],
                            n_age = Float64[],
                            n_spore = Float64[],
                            n_fallen = Float64[])
        for k in keys(value(ostats))
            row::Vector{Union{Int64, Float64}} = collect(k)
            append!(row, collect(value.(value(ostats[k].stats[1]))))
            append!(row, collect(value.(value(ostats[k].stats[2]))))
            push!(var_df, row)
        end
    else
        var_df = DataFrame(tick = Int64[], v_prod = Float64[], n_prod = Float64[])
        for k in keys(value(ostats))
            row::Vector{Union{Int64, Float64}} = collect(k)
            append!(row, collect(value.(value(ostats[k].stats[1]))))
            append!(row, collect(value.(value(ostats[k].stats[2]))))
            push!(var_df, row)
        end
    end

    return var_df
end
