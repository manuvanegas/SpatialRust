## calculate distances using OnlineStats

#function calc_diffs_os(df_a::DataFrame, df_c::DataFrame, df_p::DataFrame)
#    diff_a = calc_diffs_age(df_a)
#    diff_c = calc_diffs_cycle(df_c)
#    diff_p = calc_diffs_prod(df_p)
#
#    return dfize(diff_a, diff_c, diff_p)
#end

#function calc_diffs_age(df::DataFrame)
#    files = readdir("/scratch/mvanega1/ABC/ages", join = true, sort = false)
#    @inline d_itr(f) = (r.p_row => ((r.area_m, dfr.median_area, dfr.v_age),
#                                (r.spores_m, dfr.median_spores, dfr.v_spore)) for (r, dfr) in zip(eachrow(f), Iterators.cycle(eachrow(df))) )
#    #diffs = @distributed merge for f in files
#    #    fit!(GroupBy(Int, FTSeries(Tuple, 2Sum(); transform = squarediff_var)), d_itr(DataFrame(Arrow.Table(f))))
#    #end
#    return diffs
#end

#function calc_diffs_cycle(df::DataFrame)
#    files = readdir("/scratch/mvanega1/ABC/cycles", join = true, sort = false)
#    @inline d_itr(f) = r.p_row => ((r.area_m, dfr.med_app_area, dfr.v_age),
#                            (r.spores_m, dfr.med_app_spores, dfr.v_spore),
#                            (r.fallen, dfr.fallen_pct, dfr.v_fallen)) for (r, dfr) in zip(eachrow(f), Iterators.cycle(eachrow(df))) )
#    #diffs = @distributed merge for f in files
#    #    fit!(GroupBy(Int, FTSeries(Tuple, 3Sum(); transform = squarediff_var)), d_itr(DataFrame(Arrow.Table(f))))
#    #end
#    return diffs
#end

#"pero cómo cuadrar linea con linea? si en uno de los dos está missing..."

#function calc_diffs_prod(df::DataFrame)
#    files = readdir("/scratch/mvanega1/ABC/prod", join = true, sort = false)
#    @inline d_itr(f) = (r.p_row => ((r.coffee_production, dfr.median_relfruits, dfr.v_prod),
#                                (r.coffee_production, dfr.median_relnodes, dfr.v_prod)) for (r, dfr) in zip(eachrow(f), Iterators.cycle(eachrow(df))) )
#    #diffs = @distributed merge for f in files
#    #    fit!(GroupBy(Int, FTSeries(Tuple, 2Sum(); transform = squarediff_var)), d_itr(DataFrame(Arrow.Table(f))))
#    #end
#    return diffs
#end

#squarediff_var(row::NTuple{N, NTuple{N, Float64}})::NTuple{N, Float64} where {N} = _squarediff_var.(row)

#_squarediff_var(row::NTuple{N, Float64} where {N})::Float64 = ((row[1] - row[2]) ^ 2 ) / row[3]

#function dfize(a_g::GroupBy, c_g::GroupBy, p_g::GroupBy)
#    @assert all(length(value(a_g)) == length(value(c_g)), length(value(a_g)) == length(value(p_g)) )
#    dists = DataFrame(p_row = Int64[],
#                        ar_age = Float64[],
#                        sp_age = Float64[],
#                        ar_cycle = Float64[],
#                        sp_cycle = Float64[],
#                        fallen_p = Float64[],
#                        prod_fruit = Float64[],
#                        prod_node = Float64[])
#    for k in keys(value(a_g))
#        row::Vector{Union{Int64, Float64}} = collect(k)
#        push!(row, collect(value.(value(a_g[k].stats[1]))))
#        push!(row, collect(value.(value(c_g[k].stats[1]))))
#        push!(row, collect(value.(value(p_g[k].stats[1]))))
#        push!(dists, row)
#    end
#    return "sqrt of dists"
#end

## calculate distances using FileTrees

function calc_dists(df_a::DataFrame, df_c::DataFrame, df_p::DataFrame)::DataFrame
    a_file_tree = FileTrees.load(FileTree("/scratch/mvanega1/ABC/sims/ages"); lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end
    c_file_tree = FileTrees.load(FileTree("/scratch/mvanega1/ABC/sims/cycles"); lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end
    p_file_tree = FileTrees.load(FileTree("/scratch/mvanega1/ABC/sims/prod"); lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end

    dists_a = reducevalues(vcat, mapvalues(x -> sq_diff_var_a(x, df_a), a_file_tree))
    dists_c = reducevalues(vcat, mapvalues(x -> sq_diff_var_c(x, df_c), c_file_tree))
    dists_p = reducevalues(vcat, mapvalues(x -> sq_diff_var_p(x, df_p), p_file_tree))

    dists_mid = leftjoin(exec(dists_a), exec(dists_c), on = :p_row)
    dists = leftjoin(dists_mid, exec(dists_p), on = :p_row)

    return dists #leftjoin(exec(dists_c), exec(dists_p), on = :p_row) #dists
end


function sq_diff_var_a(sims::DataFrame, compare::DataFrame)::DataFrame
    compare = leftjoin(compare, sims, on = [:day_n => :tick, :age_week => :age, :sample_cycle => :cycle])
    transform!(compare,
            [:area_m, :median_area, :v_area] => ByRow(sq_diff_var) => :area_diff,
            [:spores_m, :median_spores, :v_spore] => ByRow(sq_diff_var) => :spore_diff)
    dists = combine(groupby(compare, :p_row), :area_diff => sum => :area_age, :spore_diff => sum => :spore_age)
    return dists
end

function sq_diff_var_c(sims::DataFrame, compare::DataFrame)::DataFrame
    compare = leftjoin(compare, sims, on = [:day_n => :tick, :sample_cycle => :cycle])
    transform!(compare,
            [:area_m, :med_app_area, :v_area] => ByRow(sq_diff_var) => :area_diff,
            [:spores_m, :med_app_spores, :v_spore] => ByRow(sq_diff_var) => :spore_diff,
            [:fallen, :fallen_pct, :v_fallen] => ByRow(sq_diff_var) => :fallen_diff)
    dists = combine(groupby(compare, :p_row),
            :area_diff => sum => :area_cycle,
            :spore_diff => sum => :spore_cycle,
            :fallen_diff => sum => :fallen)
    return dists
end

function sq_diff_var_p(sims::DataFrame, compare::DataFrame)::DataFrame
    compare = leftjoin(compare, sims, on = :day_n => :tick)
    transform!(compare,
            [:coffee_production, :median_relfruits, :v_prod] => ByRow(sq_diff_var) => :p_fruits,
            [:coffee_production, :median_relnodes, :v_prod] => ByRow(sq_diff_var) => :p_nodes)
    dists = combine(groupby(compare, :p_row), :p_fruits => sum => :prod_fruit, :p_nodes => sum => :prod_node)
    return dists
end

# sq_diff_var(sim::Float64, emp::Float64, norm::Float64)::Float64 = norm == 0 ? 0.0 : ((sim - emp)^2) / norm
sq_diff_var(sim::Float64, emp::Float64, norm::Float64)::Float64 = ((sim - emp)^2) / norm
sq_diff_var(sim::Float64, emp::Missing, norm::Float64)::Float64 = 0.0
sq_diff_var(sim::Float64, emp::Missing, norm::Missing)::Float64 = 0.0
sq_diff_var(sim::Missing, emp::Float64, norm::Float64)::Float64 = 1.0
