function scale_params(params::DataFrame, medians::DataFrame)
    df = similar(params)
    df[!, :p_row] .= params[:, :p_row]
    for c in 2:ncol(params)
        df[!, c] .= params[!, c] ./ medians[1, c]
    end
    return df
end

function metric_combination(idx::Vector{Int})
    quants = [:area_d, :spore_d, :nl_d, :occup_d]
    quals = [:exh_d, :incid_d, :cor_d]
    qntsid = filter(i -> i < 5, idx)
    qlsid = filter(i -> i > 4, idx) .- 4
    return quals[qlsid], quants[qntsid]
end

function gmetric_combination(idx::Vector{Int})
    quants = [:area_gd, :spore_gd, :nl_gd, :occup_gd]
    quals = [
        :exh_sun, :prod_clr_sun, :exh_shade, :prod_clr_shade,
        :exh_spct, :prod_clr_cor
    ]
    qntsid = filter(i -> i < 5, idx)
    qlsid = filter(i -> i > 4, idx) .- 4
    return quals[qlsid], quants[qntsid]
end

# this version is outdated
function metric_combination(quantop::Symbol, qualop::Symbol)
    quants = if quantop == :nl
        [:area_d, :spore_d, :nl_d]
    elseif quantop == :occup
        [:area_d, :spore_d, :occup_d]
    else
        [:area_d, :spore_d, :nl_d, :occup_d]
    end
    
    quals = if qualop == :sum
        [:exh_sun, :prod_clr_sun, :exh_shade, :prod_clr_shade]
    else
        [:exh_spct, :prod_clr_cor]
    end

    return [quants; quals]
end

function rm_toomanymissings(dists::DataFrame, ns::DataFrame, cut::Int, extranl::Int)
    anymorethan(nmis::Vararg{Int}) = any(n > cut for n in nmis)
    anymorethannl(nmis::Vararg{Int}) = any(n > (cut + extranl) for n in nmis)
    df = transform(ns, Not([:p_row, :nl_n]) => ByRow(anymorethan) => :sel)
    transform!(df, :nl_n => ByRow(anymorethannl) => :selnl)
    subset!(df, [:sel, :selnl] => max)
    return antijoin(dists, df, on = :p_row)
end

function replacenans(df::DataFrame, regex::Regex, val::Float64)
    nantoval(x) = ifelse.(isnan.(x), val, x)
    df2 = copy(df)
    df2[!, regex] = nantoval.(df[:, regex])
    return df2
end

function fromquantile(dists::DataFrame, n::Int, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol})
    d1 = sum_cols(dists, qualmetrics, :qual_dist)
    d1 = sum_cols(d1, quantmetrics, :quant_dist)
    sort!(d1, :qual_dist)
    
    apxq = 1.5 * n / nrow(dists)
    thr = quantile(d1.qual_dist, apxq)
    println(thr)

    subset!(d1, :qual_dist => ByRow(<=(thr)))
    return sort!(d1, :quant_dist)[1:n,:]
end

function best_100(dists::DataFrame, qualsfirst::Bool, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol})
    return best_n(dists, qualsfirst, 100, qualmetrics, quantmetrics)
end

function best_n(dists::DataFrame, qualsfirst::Bool, n::Int, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol})
    if isempty(quantmetrics)
        d1 = transform(
        dists, :p_row,
        AsTable(qualmetrics) => ByRow(sqrt ∘ sum) => :qual_dist
        )
        sort!(d1, :qual_dist)
    elseif isempty(qualmetrics)
        d1 = transform(
        dists, :p_row,
        AsTable(quantmetrics) => ByRow(sqrt ∘ sum) => :quant_dist
        )
        sort!(d1, :qual_dist)
    elseif qualsfirst
        # println(qualmetrics)
        # println(quantmetrics)
        # println("$quantmetrics but $(quantmetrics[2]) later")
        d1 = sum_cols(dists, qualmetrics, :qual_dist)
        d1 = sum_cols(d1, quantmetrics, :quant_dist)
        # d1 = sum_these(d1, quantmetrics[Not(2)], :quant_dist)
        # d1 = sum_these(d1, [quantmetrics[2]], :spores)
        sort!(d1, [:qual_dist, :quant_dist])
        # sort!(d1, [:qual_dist, :quant_dist, :spores])
    else
        d1 = transform(
            dists, :p_row,
            AsTable(qualmetrics) => ByRow(sum) => :qual_dist,
            AsTable(quantmetrics) => ByRow(sum) => :quant_dist,
            )
        sort!(d1, [:quant_dist, :qual_dist])
    end
    return d1[1:n, :]
end

function sum_cols(dists::DataFrame, ms::Vector{Symbol}, name::Symbol)
    return transform(dists, AsTable(ms) => ByRow(sum) => name)
end

function best_100ranked(dists::DataFrame,qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol})
    best_ranked(dists, 100, qualmetrics, quantmetrics)
end

function best_ranked(dists::DataFrame, n::Int, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol})
    d1 = transform(
        dists, :p_row,
        AsTable(qualmetrics) => ByRow(sqrt ∘ sum) => :qual_dist,
        quantmetrics .=> denserank
    )
    select!(
        d1, names(dists), :qual_dist,
        AsTable(r"denserank") => ByRow(sum) => :quant_ranksum
    )
    sort!(d1, [:qual_dist, :quant_ranksum])
    return d1[1:n, :]
end

best_100hierar(dists::DataFrame, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol}) = best_hierar(dists, 100, qualmetrics, quantmetrics)

function best_hierar(dists::DataFrame, n::Int, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol})
    d1 = transform(
        dists, :p_row,
        AsTable(qualmetrics) => ByRow(sqrt ∘ sum) => :qual_dist,
        AsTable(quantmetrics[1:3]) => ByRow(sum) => :area_dist,
        # AsTable(quantmetrics[1:2]) => ByRow(sum) => :area_dist,
        # AsTable(quantmetrics[3:4]) => ByRow(sum) => :les_dist
    )
    sort!(d1, [:qual_dist, qualmetrics[4], :area_dist])
    # sort!(d1, [:qual_dist, :les_dist, :area_dist])
    return d1[1:n, :]
end


sample_rejected(sel_rows::Vector{Int}, totrows::Int) = sample_rejected_n(sel_rows, totrows, 100)

sample_rejected_n(sel_rows::Vector{Int}, totrows::Int, n::Int) = rand(filter(n -> n ∉ sel_rows, 1:totrows), n)

get_params_rows(params::DataFrame, sel_rows::Vector{Int}) = subset(params, :p_row => x -> x .∈ Ref(sel_rows))

function get_best_accept_reject(parameters::DataFrame, sel_rows::Vector{Int}, b::Int)
    r1 = sel_rows[b]
    selparams = get_params_rows(parameters, sel_rows)
    bestest = filter(:p_row => .==(r1), selparams)
    pointestimate = combine(selparams, Not(:p_row) .=> median, renamecols = false)
    rejected = get_params_rows(parameters, sample_rejected(sel_rows, nrow(parameters)))
    for df in (bestest, selparams, rejected)
        transform!(df, Not(:p_row) .=> ByRow(round4), renamecols = false)
    end
    transform!(pointestimate, All() .=> ByRow(round4), renamecols = false)
    return bestest, pointestimate, selparams, rejected
end

function write_dfs(dfs::NTuple{4, DataFrame}, metrics::String, fn::String)
    bestpoint, medpoint, selparams, rejected = dfs
    CSV.write(string("results/ABC/params/sents/", fn, "/", metrics, "_bestpointestimate.csv"), bestpoint)
    CSV.write(string("results/ABC/params/sents/", fn, "/", metrics, "_medpointestimate.csv"), medpoint)
    CSV.write(string("results/ABC/params/sents/", fn, "/", metrics, "_accepted.csv"), selparams)
    CSV.write(string("results/ABC/params/sents/", fn, "/", metrics, "_rejected.csv"), rejected)
end
    

function write_accept_reject_runs(parameters::DataFrame, sel_rows::DataFrame, metrics::String, b::Int, fn::String)

    bestpoint, medpoint, selparams, rejected = get_best_accept_reject(parameters, sel_rows, b)
    write_dfs((bestpoint, medpoint, selparams, rejected), metrics, fn)

    return bestpoint, pointestimate, selparams, rejected
end

function top_n_rows(parameters::DataFrame, selrows::Vector{Int}, n::Int)
    toppars = DataFrame(deepcopy(parameters[selrows[1], :]))
    toprowns = selrows[2:n]
    for rown in toprowns
        push!(toppars, parameters[rown, :])
    end
    transform!(toppars, Not(:p_row) .=> ByRow(round4), renamecols = false)
    return toppars
end

round6(x) = round(x, digits = 6)
round4(x) = round(x, digits = 4)

function best_sepvars(dists::DataFrame, var::Symbol, n::Int)
    d1 = transform(
        dists,
        AsTable([:exh_sun, :prod_clr_sun, :exh_shade, :prod_clr_shade]) => ByRow(sqrt ∘ sum) => :qual_dist)
    sort(d1, [:qual_dist, var])[1:n, :]
end

function test_params(pars, row)
    steps = 2920
    dffs = simplerun(steps; seed = 123, common_map = :fullsun,
    start_days_at = 115,
    prune_sch = [15, 166, -1],
    post_prune = [0.15, 0.2, -1],
    pars[row, :]...);
    dfms = simplerun(steps; seed = 123, common_map = :regshaded, shade_d = 6, barriers = (0,0),
    start_days_at = 115, 
    prune_sch = [15, 166, -1],
    post_prune = [0.15, 0.2, -1],
    pars[row, :]...);
    return dffs, dfms
end


