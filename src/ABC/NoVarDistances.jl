# Calculate distances using FileTrees

## "Qualitative" variables
function calc_l_dists(qualsdirname::String, dats::DataFrame, vars::DataFrameRow)::DataFrame
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

# function missum(v)
#     nmis = sum(ismissing.(v))
#     if nmis == 0
#         return sum(v)
#     elseif nmis == 1
#         return sum(skipmissing(v))
#     else
#         return 2.8
#     end
# end

# function diff_quals(sims::DataFrame, exh_min::Float64, exh_max::Float64, incidm::Float64, corm::Float64)::DataFrame
function diff_quals(sims::DataFrame, dats::DataFrame, vars::DataFrameRow)::DataFrame

    selfmetrics = select(sims, :p_row,
        [:P1att, :P1obs, :P12att, :P12obs] => ByRow(yieldloss) => [:P1loss, :P12loss],
        :incidiff, :cor
    )
    metricsself = [:P1loss, :incidiff, :cor]
    for name in metricsself
        selfmetrics[!, Symbol(name, :_d)] = toldist.(selfmetrics[!, name], Ref(dats[!, name]), vars[name])
    end
    selfmetrics[!, :P12loss_d] = toldistsep.(selfmetrics[!, :P12loss], selfmetrics[!, :P12loss] .* dats[1, :P12loss], dats[2, :P12loss], vars[:P12loss])
    
    prowdists = combine(groupby(selfmetrics, :p_row),
    [:incidiff_d, :cor_d, :P1loss_d, :P12loss_d] .=> mean,
    renamecols = false)



    diffmetrics = select(sims, :p_row, :plot,
        [:P1att, :P12att] => ByRow(bienniality) => [:P1att, :bienniality, :P12att],
        :areas, :nls
    )

    dfsun = subset(diffmetrics, :plot => ByRow(==(:sun)))
    dfsh = subset(diffmetrics, :plot => ByRow(==(:shade)))

    metricsdiff = [:P1att, :bienniality, :areas, :nls]

    dfsun[!, metricsdiff] = dfsun[!, metricsdiff] .- dfsh[!, metricsdiff]
    dfsun[!, :Pattpct] = 1.0 .- dfsh[!, :P12att] ./ dfsun[!, :P12att]

    diffdists = DataFrame(p_row = unique(sims[:, :p_row]))
    for name in [:Pattpct, :bienniality, :areas, :nls]
        diffdists[!, Symbol(name, :_d)] .= toldist.(dfsun[!, name], Ref(dats[!, name]), vars[name])
    end
    diffdists[!, :P1att_d] = toldistsep.(dfsun[!, :P1att], dats[1, :P1att], dfsun[!, :P1att] .* dats[2, :P1att], vars[:P1att])

    leftjoin!(prowdists, diffdists, on = :p_row)

    return prowdists
end

function yieldloss(y1att, y1obs, y12att, y12obs)
    y1loss = (y1att - y1obs) / y1att
    return y1loss, ((y12att - y12obs) / y12att)
end

function bienniality(Y1, Y12)
    return Y1, (abs(2.0 * Y1 - Y12) / Y1), Y12
end

function toldist(sim::Union{Missing, Float64}, tol::Vector{Float64}, var::Float64)
    tmin, tmax = tol
    if ismissing(sim) || !isfinite(sim)
        return 10e4
    elseif sim > tmax
        return (sim - tmax) ^ 2 / var
    elseif sim < tmin
        return (tmin - sim) ^ 2 / var
    else
        return 0.0
    end
end

function toldistsep(sim::Union{Missing, Float64}, tmin::Union{Missing, Float64}, tmax::Union{Missing, Float64}, var::Float64)
    if ismissing(sim) || !isfinite(sim)
        return 10e4
    elseif sim > tmax
        return (sim - tmax) ^ 2 / var
    elseif sim < tmin
        return (tmin - sim) ^ 2 / var
    else
        return 0.0
    end
end

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

    any(ismissing.(joined.p_row)) && error("missing rows $(first(skipmissing(joined.p_row)))")

    dists = DataFrame(p_row = joined[:, :p_row])
    for name in [:area, :spore, :nl, :occup]
        dists[!, Symbol(name, :_d)] .= absdiff.(joined[!, name], joined[!, Symbol(name, :_dat)], vars[Symbol(name, :_var)])
        dists[!, Symbol(name, :_n)] .= findmissing.(joined[!, name], joined[!, Symbol(name, :_dat)])
    end

    # if 1 in sims.p_row
        # CSV.write("results/ABC/dists/sents/q8/samplerawjoined.csv", joined)
        # CSV.write("results/ABC/dists/sents/q8/samplerawdists.csv", dists)
    # end

    sumdists = combine(groupby(dists, :p_row), Not(:p_row) .=> sum, renamecols = false)

    return sumdists
end

absdiff(sim::Float64, dat::Float64, var::Float64) = (sim - dat)^2 / var
absdiff(sim::Missing, dat::Float64, var::Float64) = dat^2 / var
absdiff(sim::Float64, dat::Missing, var::Float64) = 0.0
absdiff(sim::Missing, dat::Missing, var::Float64) = 0.0

findmissing(sim::Float64, dat::Float64) = 0
findmissing(sim::Missing, dat::Float64) = 1
findmissing(sim::Float64, dat::Missing) = 0
findmissing(sim::Missing, dat::Missing) = 0

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
