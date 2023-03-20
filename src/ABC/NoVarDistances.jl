# Calculate distances using FileTrees

## "Qualitative" variables
function calc_l_dists(qualsdirname::String, dats::DataFrameRow, vars::DataFrameRow)::DataFrame
    ft = FileTree(string("/scratch/mvanega1/ABC/sims/", qualsdirname))
    l_file_tree = FileTrees.load(ft; lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end
    lazy_dists = mapvalues(x -> diff_quals(x, dats, vars), l_file_tree)
    rowdists = exec(reducevalues(vcat, lazy_dists))

    # replace!(dists_l[!, :cor_d]) do cor
    #     isnan(cor) ? 1.0 : cor
    # end
    # rowdists = combine(
    #     groupby(dists_l, :p_row),
    #     # Not(:p_row) .=> sum,
    #     Not(:p_row) .=> missum,
    #     renamecols = false
    # )
    return rowdists
end

function missum(v)
    nmis = sum(ismissing.(v))
    if nmis == 0
        return sum(v)
    elseif nmis == 1
        return sum(skipmissing(v))
    else
        return 2.8
    end
end

# function diff_quals(sims::DataFrame, exh_min::Float64, exh_max::Float64, incidm::Float64, corm::Float64)::DataFrame
function diff_quals(sims::DataFrame, dats::DataFrameRow, vars::DataFrameRow)::DataFrame
    # sims[!, :bienniality] = (2 .* sims[!, :P1att] .- sims[!, :P12att]) ./ sims[!, :P1att]
    # dist_df[!, :exh_d] = accept_range.(sims[!, :exh], exh_min, exh_max)
    # dist_df[!, :incid_d] = max.(incidm .- sims[!, :incid], 0.0)
    # dist_df[!, :cor_d] = cor_diff.(corm, sims[!, :prod_clr])
    # dist_df[!, :frusts] = sims[:, :frusts]
    # dist_df[!, :nanprod] = .!isnan.(sims[!, :P12obs])
    # dist_df[!, :frusts] = sims[!, :anyrusts]
    # dist_df[!, :incidgrowth] = sims[!, :incidiff] .> 0.3

    # diffdists = select(dfsun, :p_row,
    #     :P1att => s -> sqdist() => :P1att_d,
    #     :P12att => s -> sqdist() => :P12att_d,
    #     :bienniality => s -> sqdist() => :bienniality_d,
    #     :areas => s -> sqdist() => :areas_d,
    #     :nls => s -> sqdist() => :nls_d
    # )

    metricsself = [:incidiff, :cor]

    selfmetrics = select(sims, :p_row,
        [:P1att, :P1obs, :P12att, :P12obs] => ByRow(yieldloss) => [:P1loss, :P12loss_diff],
        :incidiff, :cor
    )

    for name in metricsself
        selfmetrics[!, Symbol(name, :_d)] = sqdistmorethantol.(selfmetrics[!, name], dats[name], vars[name])
    end
    selfmetrics[!, :P12loss_diff_d] = sqdistmorethantol.(selfmetrics[!, :P12loss_diff], (selfmetrics[!, :P1loss] .* 1.1), vars[:P12loss])
    selfmetrics[!, :P1loss_d] = sqdistmorethantol.(selfmetrics[!, :P1loss], dats[:P1loss], vars[:P1loss])

    # select!(selfmetrics, :p_row,
    #     :P1loss => s -> sqdist() => :P1loss_d,
    #     :P12loss_diff => s -> sqdist() => :P12loss_diff_d,
    #     :incidiff => s -> sqdist() => :incidiff_d,
    #     :cor => s -> sqdist() => :cor_d
    # )
    
    prowdists = combine(groupby(selfmetrics, :p_row),
    [:incidiff_d, :cor_d, :P1loss_d, :P12loss_diff_d] .=> sum,
    renamecols = false)



    metricsdiff = [:P1att, :P12att, :bienniality, :areas, :nls]

    diffmetrics = select(sims, :p_row, :plot, :areas, :nls,
        [:P1att, :P12att] => ByRow(bienniality) => [:P1att, :P12att, :bienniality]
    )

    dfsun = subset(diffmetrics, :plot => ByRow(==(:sun)))
    dfsh = subset(diffmetrics, :plot => ByRow(==(:shade)))
    dfsun[!, metricsdiff] = dfsun[!, metricsdiff] .- dfsh[!, metricsdiff]

    diffdists = DataFrame(p_row = unique(sims[:, :p_row]))
    for name in [:P1att, :bienniality, :areas]
        diffdists[!, Symbol(name, :_d)] .= sqdistmorethantol.(dfsun[!, name], dats[name], vars[name])
    end
    diffdists[!, :nls_d] = sqdistfromneg.(dfsun[!, :nls], dats[:nls], vars[:nls])
    diffdists[!, :Psumatt_d] = sqdistfromeq.(dfsun[!, :P12att], dats[:P12att], vars[:P12att])

    leftjoin!(prowdists, diffdists, on = :p_row)

    # prowdists[!, :areas_d] = dfsun[!, :areas] .> -0.1
    # prowdists[!, :nls_d] = dfsun[!, :nls] .< 0.1
    # prowdists[!, :P1att_d] = dfsun[!, :P1att] .> -0.1
    # prowdists[!, :bienniality_d] = dfsun[!, :bienniality] .> -0.1

    # P1att diff
    # P12att diff
    # bienniality diff
    # P1loss 2
    # P12loss 2
    # nls diff
    # areas diff
    # incid 2
    # cor 2

    return prowdists
end

function yieldloss(y1att, y1obs, y12att, y12obs)
    y1loss = (y1att - y1obs) / y1att
    return y1loss, ((y12att - y12obs) / y12att) - y1loss
end

function bienniality(Y1, Y12)
    return Y1, Y12, ((2.0 * Y1 - Y12) / Y1)
end

function sqdistmorethantol(sim::Union{Missing, Float64}, tol::Float64, var::Float64)
    if ismissing(sim) || !isfinite(sim)
        return 10e4
    else
        return (max(0.0, tol - sim))^2 / var
    end
end
sqdistmorethantol(sim::Union{Missing, Float64}, tol::Missing, var::Float64) = 0.0

function sqdistfromneg(sim::Union{Missing, Float64}, tol::Float64, var::Float64)
    if ismissing(sim) || !isfinite(sim)
        return 10e4
    else
        return (min(0.0, tol - sim))^2 / var
    end
end
sqdistfromneg(sim::Union{Missing, Float64}, tol::Missing, var::Float64) = 0.0

function sqdistfromeq(sim::Union{Missing, Float64}, tol::Float64, var::Float64)
    if ismissing(sim) || !isfinite(sim)
        return 10e4
    else
        return isapprox(sim, 0.0, atol = tol) ? 0.0 : sim^2 / var
    end
end
sqdistfromeq(sim::Union{Missing, Float64}, tol::Missing, var::Float64) = 0.0

# function accept_range(out::Float64, minv::Float64, maxv::Float64)
#     if out < minv
#         return minv - out
#     elseif out < maxv
#         return 0.0
#     else
#         return out - maxv
#     end
# end

# function cor_diff(corm::Float64, sim::Float64)
#     if isnan(sim)
#         return missing
#     else
#         return max.(corm - sim, 0.0)
#     end
# end

# cor_diff(corm::Float64, sim::Missing) = missing

## Quantitative variables
function calc_nt_dists(quantsdirname::String, empdata::DataFrame, vars::DataFrameRow)::NTuple{2, DataFrame}
    ft = FileTree(string("/scratch/mvanega1/ABC/sims/", quantsdirname))
    nt_file_tree = FileTrees.load(ft; lazy = true) do file
        DataFrame(Arrow.Table(path(file)))
    end
    lazy_dists = mapvalues(x -> abs_norm_dist(x, empdata, vars), nt_file_tree)
    println("starting quants exec...")
    flush(stdout)
    dists_nt = exec(reducevalues(vcat, lazy_dists))
    return select(dists_nt, :p_row, r"_d"), select(dists_nt, :p_row, r"_n")
end

function abs_norm_dist(sims::DataFrame, empdata::DataFrame, vars::DataFrameRow)::DataFrame
    joined = leftjoin(empdata, sims, on = [:plot, :dayn, :age, :cycle])
    # rename!(joined, :med_area => :area, :med_spore => :spore, :med_nl => :nl)
    any(ismissing.(joined.p_row)) && error("missing rows $(first(skipmissing(joined.p_row)))")

    dists = DataFrame(p_row = joined[:, :p_row])
    for name in [:area, :spore, :nl, :occup]
        dists[!, Symbol(name, :_d)] .= absdiff.(joined[!, name], joined[!, Symbol(name, :_dat)], vars[Symbol(name, :_var)])
        dists[!, Symbol(name, :_n)] .= findmissing.(joined[!, name], joined[!, Symbol(name, :_dat)])
    end

    if 1 in sims.p_row
        CSV.write("results/ABC/dists/sents/q7/samplerawjoined.csv", joined)
        CSV.write("results/ABC/dists/sents/q7/samplerawdists.csv", dists)
    end

    sumdists = combine(groupby(dists, :p_row), Not(:p_row) .=> sum, renamecols = false)
    
    # globs = sims[(sims.dayn .== 196) .&& (sims.age .== 0), [:p_row, :plot, :dayn, :ar_sum, :nl_mn]]
    # globsun = subset(globs, :plot => ByRow(==(:sun)))
    # globsh = subset(globs, :plot => ByRow(==(:shade)))
    # globsun[!,[:ar_sum, :nl_mn]] = globsun[!,[:ar_sum, :nl_mn]] .- globsh[!,[:ar_sum, :nl_mn]]
    # globsun[!, :ar_sum_d] = globsun[!, :ar_sum] .> -0.1
    # globsun[!, :nl_mn_d] = globsun[!, :nl_mn] .< 0.1
    # coalesce.(globsun, false)

    # leftjoin!(sumdists, select(globsun, :p_row, :ar_sum_d, :nl_mn_d), on = :p_row)

    return sumdists
end

absdiff(sim::Float64, dat::Float64, var::Float64) = (sim - dat)^2 / var
absdiff(sim::Missing, dat::Float64, var::Float64) = 4.0 * dat^2 / var
absdiff(sim::Float64, dat::Missing, var::Float64) = 0.0
absdiff(sim::Missing, dat::Missing, var::Float64) = 0.0

findmissing(sim::Float64, dat::Float64) = 0
findmissing(sim::Missing, dat::Float64) = 1
findmissing(sim::Float64, dat::Missing) = 0
findmissing(sim::Missing, dat::Missing) = 0

# function tglobs(sims::DataFrame)
#     globs = sims[(sims.dayn .== 196) .&& (sims.age .== 0), [:p_row, :plot, :dayn, :ar_sum, :nl_mn]]
#     globsun = subset(globs, :plot => ByRow(==(:sun)))
#     globsh = subset(globs, :plot => ByRow(==(:shade)))
#     globsun[!,[:ar_sum, :nl_mn]] = globsun[!,[:ar_sum, :nl_mn]] .- globsh[!,[:ar_sum, :nl_mn]]
#     globsun[!, :ar_sum_d] = globsun[!, :ar_sum] .> -0.1
#     globsun[!, :nl_mn_d] = globsun[!, :nl_mn] .< 0.1
#     coalesce.(globsun, false)
#     return globsun
# end

# absdiff(dat::Float64, sim::Float64) = dat == 0.0 ? sim^2 : (sim / dat - 1.0)^2
# absdiff(dat::Float64, sim::Missing) = dat == 0.0 ? 100.0 : (1.0 / dat)^2
# absdiff(dat::Missing, sim::Float64) = 0.0
# absdiff(dat::Missing, sim::Missing) = 0.0

# findmissing(dat::Float64, sim::Float64) = 0
# findmissing(dat::Float64, sim::Missing) = 1
# findmissing(dat::Missing, sim::Float64) = 0
# findmissing(dat::Missing, sim::Missing) = 0

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
