# Calculate distances using FileTrees

## "Qualitative" variables
function calc_l_dists(qualsdirname::String, exh_min::Float64, exh_max::Float64, incidm::Float64, corm::Float64)::DataFrame
    ft = FileTree(string("/scratch/mvanega1/ABC/sims/", qualsdirname))
    l_file_tree = FileTrees.load(ft; lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end
    lazy_dists = mapvalues(
        x -> sq_diff_var_quals(x, exh_min, exh_max, incidm, corm),
        l_file_tree)
    dists_l = exec(reducevalues(vcat, lazy_dists))

    return dists_l
end

function sq_diff_var_quals(sims::DataFrame, exh_min::Float64, exh_max::Float64, incidm::Float64, corm::Float64)::DataFrame
    dist_df = DataFrame(p_row = sims[:, :p_row])
    dist_df[!, :exh_d] = accept_range.(sims[!, :exh], exh_min, exh_max)
    dist_df[!, :incid_d] = min.(sims[!, :incid] .- incidm, 0.0)
    dist_df[!, :cor_d] = min.(sims[!, :prod_clr] .- corm, 0.0) ./ 2.0 # cor is in [-1,1], while exh and incid are [0,1]
    dist_df[!, :frusts] = sims[:, :frusts]

    return dist_df
end

function accept_range(out::Float64, minv::Float64, maxv::Float64)
    if out < minv
        return minv - out
    elseif out < maxv
        return 0.0
    else
        return out - maxv
    end
end

## Quantitative variables
function calc_nt_dists(quantsdirname::String, empdata::DataFrame)::NTuple{2, DataFrame}
    ft = FileTree(string("/scratch/mvanega1/ABC/sims/", quantsdirname))
    nt_file_tree = FileTrees.load(ft; lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end
    lazy_dists = mapvalues(x -> abs_norm_dist(x, empdata), nt_file_tree)
    println("starting quants exec...")
    flush(stdout)
    dists_nt = exec(reducevalues(vcat, lazy_dists))
    return select(dists_nt, :p_row, r"_d"), select(dists_nt, :p_row, r"_n")
end

function abs_norm_dist(sims::DataFrame, empdata::DataFrame)::DataFrame
    joined = leftjoin(quantv, sims, on = [:plot, :cycle, :dayn, :age])
    # rename!(joined, :med_area => :area, :med_spore => :spore, :med_nl => :nl)

    dists = DataFrame(p_row = joined[:, :p_row])
    for name in [:area, :spore, :nl, :occup]
        dists[!, Symbol(name, :_d)] .= absdiff.(joined[!, Symbol(name, :_dat)], joined[!, name])
        dists[!, Symbol(name, :_n)] .= findmissing.(joined[!, Symbol(name, :_dat)], joined[!, name])
    end
    # if 1 in joined.p_row
    #     CSV.write("results/ABC/dists/samplerawjoined.csv", joined)
    #     CSV.write("results/ABC/dists/samplerawdists.csv", dists)
    # end
    sumdists = combine(groupby(dists, :p_row), Not(:p_row) .=> sum, renamecols = false)

    return sumdists
end

absdiff(dat::Float64, sim::Float64) = abs(sim / dat - 1.0)
absdiff(dat::Float64, sim::Missing) = 1.0
absdiff(dat::Missing, sim::Float64) = 0.0
absdiff(dat::Missing, sim::Missing) = 0.0

findmissing(dat::Float64, sim::Float64) = 0
findmissing(dat::Float64, sim::Missing) = 1
findmissing(dat::Missing, sim::Float64) = 0
findmissing(dat::Missing, sim::Missing) = 0

# sqdiff(dat::Float64, sim::Float64)::Float64 = (dat - sim) ^ 2
# sqdiff(dat::Float64, sim::Missing)::Missing = missing
# sqdiff(dat::Missing, sim::Float64)::Float64 = 0.0
# sqdiff(dat::Missing, sim::Missing)::Float64 = 0.0

# scale_sqdiff(diff::Float64, var::Float64)::Float64 = diff / ifelse(var == 0.0, 1.0, var)
# function scale_sqdiff(diff::Missing, var::Float64)::Float64
#     if var == 0.0
#         return 1.0
#     elseif var < 1e-8
#         return 1000.0
#     elseif var < 1e-4
#         return 100.0
#     else
#         return 1.0 / var
#     end
# end


# 1.0 / ifelse(var == 0.0, 1.0, ifelse)

# # sq_diff_var(sim::Float64, emp::Float64, norm::Float64)::Float64 = norm == 0 ? 0.0 : ((sim - emp)^2) / norm
# sq_diff_var(sim::Float64, emp::Float64, norm::Float64)::Tuple{Float64, Int} = ((filtereach(sim, emp) - emp)^2) / ifelse(norm > 0.0, norm, 1.0), 0
# sq_diff_var(sim::Float64, emp::Missing, norm::Float64)::Tuple{Float64, Int} = 0.0, 0
# sq_diff_var(sim::Missing, emp::Missing, norm::Float64)::Tuple{Float64, Int} = 0.0, 0
# # sq_diff_var(sim::Float64, emp::Missing, norm::Missing)::Float64 = 0.0
# sq_diff_var(sim::Missing, emp::Float64, norm::Float64)::Tuple{Float64, Int} = 2.0 * ifelse(norm > 0.0, norm, 1.0), 1

# naninfplus(x::Float64, y::Float64) = +(filtereach.(x,y))

# filtereach(x::Float64, emp::Float64) = ifelse(isnan(x), 6.0 * emp, ifelse(x == Inf, 10e9, x))
# filtereach(x::Float64) = ifelse(isnan(x), 100.0, ifelse(x == Inf, 10e10, x))

## Utils

function count_obs(df::DataFrame)
    missingscount = describe(df)[5:8,[:variable,:nmissing]]
    return nrow(df) .- unstack(missingscount, :variable, :nmissing)
end

function scale_dists!(dists::DataFrame, counts::DataFrame)
    # df = copy(dists)
    # df[!, :p_row] .= dists[:, :p_row]
    # for c in names(counts)
        # df[!, Regex(c)] .= dists[!, Regex(c)] ./ counts[1, c]
    for c in 1:ncol(counts)
        dists[!, c+1] .= dists[!, c+1] ./ counts[1, c]
    end
    return dists
end
