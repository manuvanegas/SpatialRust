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
    quals = [
        :exh_sun, :prod_clr_sun, :exh_shade, :prod_clr_shade,
        :exh_spct, :prod_clr_cor
    ]
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
        d1 = transform(
            dists, :p_row,
            AsTable(qualmetrics) => ByRow(sqrt ∘ sum) => :qual_dist,
            AsTable(quantmetrics) => ByRow(sqrt ∘ sum) => :quant_dist,
            )
        sort!(d1, [:qual_dist, :quant_dist])
    else
        d1 = transform(
            dists, :p_row,
            AsTable(qualmetrics) => ByRow(sqrt ∘ sum) => :qual_dist,
            AsTable(quantmetrics) => ByRow(sqrt ∘ sum) => :quant_dist,
            )
        sort!(d1, [:quant_dist, :qual_dist])
    end
    return d1[1:n, :]
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

get_best_params(params::DataFrame, sel_rows::DataFrame) = subset(params, :p_row => x -> x .∈ Ref(sel_rows.p_row))

function sample_rejected(sel_rows::DataFrame)
    rows = sel_rows.p_row
    rand(filter(n -> n ∉ rows, 1:10^6), 100)
end

get_rejected(params::DataFrame, sampled::Vector{Int}) = subset(params, :p_row => x -> x .∈ Ref(sampled))

function write_accept_reject_runs(parameters::DataFrame, sel_rows::DataFrame, metrics::String, nmissing::Int)
    selparams = get_best_params(parameters, sel_rows)
    # # selhead = first(selparams, 10)
    # append!(selhead, )
    # selhead[11, :p_row] = -1
    pointestimate = combine(selparams, Not(:p_row) .=> median, renamecols = false)
    rejected = get_rejected(parameters, sample_rejected(sel_rows))

    CSV.write(string("results/ABC/params/pointestimate_", metrics, "_", nmissing, ".csv"), pointestimate)
    CSV.write(string("results/ABC/params/accepted_", metrics, "_", nmissing, ".csv"), selparams)
    CSV.write(string("results/ABC/params/rejected_", metrics, "_", nmissing, ".csv"), rejected)
end

function best_sepvars(dists::DataFrame, var::Symbol, n::Int)
    d1 = transform(
        dists,
        AsTable([:exh_sun, :prod_clr_sun, :exh_shade, :prod_clr_shade]) => ByRow(sqrt ∘ sum) => :qual_dist)
    sort(d1, [:qual_dist, var])[1:n, :]
end