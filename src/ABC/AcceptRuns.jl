function scale_params(params::DataFrame, medians::DataFrame)
    df = similar(params)
    df[!, :RowN] .= params[:, :RowN]
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

function rm_toomanymissings(dists::DataFrame, ns::DataFrame, cut::Int)
    anymorethan(nmis::Vararg{Int}) = any(n > cut for n in nmis)
    df = transform(ns, 2:5 => ByRow(anymorethan) => :sel)
    subset!(df, :sel)
    return antijoin(dists, df, on = :p_row)
end

function replacenans(df::DataFrame, regex::Regex, val::Float64)
    nantoval(x) = ifelse.(isnan.(x), val, x)
    df2 = copy(df)
    df2[!, regex] = nantoval.(df[:, regex])
    return df2
end

function best_100(dists::DataFrame, qualsfirst::Bool, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol})
    return best_n(dists, qualsfirst, qualmetrics, quantmetrics, 100)
end

function best_n(dists::DataFrame, qualsfirst::Bool, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol}, n::Int)
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

get_best_params(params::DataFrame, sel_rows::DataFrame) = subset(params, :RowN => x -> x .∈ Ref(sel_rows.p_row))

function sample_rejected(sel_rows::DataFrame)
    rows = sel_rows.p_row
    rand(filter(n -> n ∉ rows, 1:10^6), 100)
end

get_rejected(params::DataFrame, sampled::Vector{Int}) = subset(params, :RowN => x -> x .∈ Ref(sampled))

function write_accept_reject_runs(parameters::DataFrame, sel_rows::DataFrame, metrics::String, nmissing::Int)
    selparams = get_best_params(parameters, sel_rows)
    # # selhead = first(selparams, 10)
    # append!(selhead, )
    # selhead[11, :RowN] = -1
    pointestimate = combine(selparams, Not(:RowN) .=> median, renamecols = false)
    rejected = get_rejected(parameters, sample_rejected(sel_rows))

    CSV.write(string("results/ABC/params/pointestimate_", metrics, "_", nmissing, ".csv"), pointestimate)
    CSV.write(string("results/ABC/params/accepted_", metrics, "_", nmissing, ".csv"), selparams)
    CSV.write(string("results/ABC/params/rejected_", metrics, "_", nmissing, ".csv"), rejected)
end