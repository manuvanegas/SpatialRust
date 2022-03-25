# calculate distances using FileTrees

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
