# calculate distances using FileTrees

function calc_l_dists(v_l::DataFrame, compare::Vector{Float64})::DataFrame
    l_file_tree = FileTrees.load(FileTree("/scratch/mvanega1/ABC/sims/quals"); lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end
    lazy_dists = mapvalues(x -> sq_diff_var_quals(x, v_l, compare), l_file_tree)
    dists_l = exec(reducevalues(vcat, lazy_dists))

	# dists = leftjoin(leftjoin(cda, cdc, on = :p_row), cdp, on = :p_row) 
    #dists_mid = leftjoin(exec(dists_a), exec(dists_c), on = :p_row)
    #dists = leftjoin(dists_mid, exec(dists_p), on = :p_row)

    return dists_l #leftjoin(exec(dists_c), exec(dists_p), on = :p_row) #dists
end

function calc_nt_dists(df_nt::DataFrame)::Tuple{DataFrame, DataFrame}
    nt_file_tree = FileTrees.load(FileTree("/scratch/mvanega1/ABC/sims/quants"); lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end
    lazy_dists = mapvalues(x -> sq_diff_var_quants(x, df_nt), nt_file_tree)
    dists_nt = exec(reducevalues(vcat, lazy_dists))
    return select(dists_nt, Not(r"_n")), select(dists_nt, r"_n")
end

function sq_diff_var_quals(sims::DataFrame, vars::DataFrame, comp::Vector{Float64})::DataFrame
    # compare = leftjoin(compare, sims, on = :day_n => :tick)
    dist_df = DataFrame()
    dist_df[!, :p_row] = sims[:, :p_row] 
    dfnames = propertynames(sims)[2:end]
    for c in 1:(ncol(sims)-1)
        dist_df[!, dfnames[c]] .= ((sims[:, c+1] .- comp[c]) .^ 2) / vars[1, c]
    end
    # transform!(sims,
    #         [:coffee_production, :median_relfruits, :v_prod] => ByRow(sq_diff_var) => :p_fruits,
    #         [:coffee_production, :median_relnodes, :v_prod] => ByRow(sq_diff_var) => :p_nodes)
    # dists = combine(groupby(compare, :p_row), :p_fruits => sum => :prod_fruit, :p_nodes => sum => :prod_node)
    return dist_df
end

function sq_diff_var_quants(sims::DataFrame, compare::DataFrame)::DataFrame
    compare = leftjoin(compare, sims, on = [:dayn, :age])
    select!(compare, :p_row,
            [:med_area_sun, :area_sun_dat, :area_sun_var] => ByRow(sq_diff_var) => [:area_sun, :area_sun_n],
            [:med_spore_sun, :spore_sun_dat, :spore_sun_var] => ByRow(sq_diff_var) => [:spore_sun, :spore_sun_n],
            [:med_nl_sun, :nl_sun_dat, :nl_sun_var] => ByRow(sq_diff_var) => [:nl_sun, :nl_sun_n],
            [:occup_sun, :occup_sun_dat, :occup_sun_var] => ByRow(sq_diff_var) => [:occup_sun, :occup_sun_n],
            [:med_area_sun, :area_sh_dat, :area_sh_var] => ByRow(sq_diff_var) => [:area_sh, :area_sh_n],
            [:med_spore_sun, :spore_sh_dat, :spore_sh_var] => ByRow(sq_diff_var) => [:spore_sh, :spore_sh_n],
            [:med_nl_sun, :nl_sh_dat, :nl_sh_var] => ByRow(sq_diff_var) => [:nl_sh, :nl_sh_n],
            [:occup_sun, :occup_sh_dat, :occup_sh_var] => ByRow(sq_diff_var) => [:occup_sh, :occup_sh_n]
    )
    dists = combine(groupby(compare, :p_row), Not(:p_row) .=> sum, renamecols = false)
    # [
    #     :area_sun,
    #     :spore_sun,
    #     :nl_sun,
    #     :occup_sun,
    #     :area_sh,
    #     :spore_sh,
    #     :nl_sh,
    #     :occup_sh
    # ] .=> sqrt ∘ sum, renamecols = false)
    transform!(dists, 
        [:area_sun, :area_sh] => ByRow(+) => :area,
        [:spore_sun, :spore_sh] => ByRow(+) => :spore,
        [:nl_sun, :nl_sh] => ByRow(+) => :nl,
        [:occup_sun, :occup_sh] => ByRow(+) => :occup,
        [:area_sun_n, :area_sh_n] => ByRow(+) => :area_n,
        [:spore_sun_n, :spore_sh_n] => ByRow(+) => :spore_n,
        [:nl_sun_n, :nl_sh_n] => ByRow(+) => :nl_n,
        [:occup_sun_n, :occup_sh_n] => ByRow(+) => :occup_n,
    )
    # transform!(dists, Not(:p_row) .=> ByRow(sqrt), renamecols = false)
    return dists
end

# sq_diff_var(sim::Float64, emp::Float64, norm::Float64)::Float64 = norm == 0 ? 0.0 : ((sim - emp)^2) / norm
sq_diff_var(sim::Float64, emp::Float64, norm::Float64)::Tuple{Float64, Int} = ((sim - emp)^2) / norm, 0
sq_diff_var(sim::Float64, emp::Missing, norm::Float64)::Tuple{Float64, Int} = 0.0, 0
sq_diff_var(sim::Missing, emp::Missing, norm::Float64)::Tuple{Float64, Int} = 0.0, 0
# sq_diff_var(sim::Float64, emp::Missing, norm::Missing)::Float64 = 0.0
sq_diff_var(sim::Missing, emp::Float64, norm::Float64)::Tuple{Float64, Int} = 2.0 * norm, 1

## make sure that cycles correspond to ticks
# function correct_cycles!(df::DataFrame)
#     if any(df.tick .== 350 .&& df.cycle .== 5)
#         transform!(df, AsTable([:tick, :cycle]) => ByRow(tick_cycle) => AsTable)
#     end
# end

# function tick_cycle(r::NamedTuple)
#     # switches only made at 372 and 442
#     if r.tick < 350 || r.tick == 372
#         return (tick = r.tick, cycle = r.cycle)
#     elseif r.tick < 406
#         return (tick = r.tick, cycle =(r.cycle + 1))
#     elseif r.tick == 434
#         return (tick = r.tick, cycle =(r.cycle + 3))
#     else
#         return (tick = r.tick, cycle =(r.cycle + 2))
#     end
# end

# ## sanity check: is there a variance value for each empirical data point?
# function find_missings(df::DataFrame)
#     if "median_spores" in names(df)
#         df = df[:, Not(:median_spores)]
#     end
#     for r in eachrow(df)
#         ismissing(sum(r)) && return true
#     end
#     return false
# end
