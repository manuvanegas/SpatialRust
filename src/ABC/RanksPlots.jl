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

function best_100(dists::DataFrame, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol})
    return best_n(dists, qualmetrics, quantmetrics, 100)
end

function best_n(dists::DataFrame, qualmetrics::Vector{Symbol}, quantmetrics::Vector{Symbol}, n::Int)
    if isempty(quantmetrics)
        d1 = transform(
        dists, :p_row,
        AsTable(qualmetrics) => ByRow(sqrt ∘ sum) => :qual_dist
        )
        sort!(d1, :qual_dist)
    else
        d1 = transform(
            dists, :p_row,
            AsTable(qualmetrics) => ByRow(sqrt ∘ sum) => :qual_dist,
            AsTable(quantmetrics) => ByRow(sqrt ∘ sum) => :quant_dist,
            )
        sort!(d1, [:qual_dist, :quant_dist])
    end
    return d1[1:n, :]
end

get_best_params(params::DataFrame, sel_rows::DataFrame) = subset(params, :RowN => x -> x .∈ Ref(sel_rows.p_row))

## Plots

isnormalpar(v::String) = v == "max_g_temp" || v == "opt_g_temp"

dodged_rainclouds(params::DataFrame, selected::DataFrame, nnorms::Int, randpars::Vector{Int}, ndots::Int; kwargs...) =
dodged_rainclouds(params[randpars, :], selected, nnorms, ndots; kwargs...)


function dodged_rainclouds(wideparams::DataFrame, wideselected::DataFrame, nnorms::Int, ndots::Int;
    height = 1200, width = 600)

    params = stack(wideparams)
    selected = stack(wideselected)
    normsvstot = nnorms/(ncol(wideselected) - 1)

    cloud_w_p = 1.0
    cloud_w_s = 1.0
    bp_width = 0.1
    bp_nudge_p = 0.12
    bp_nudge_s = 0.24
    color_p = :orange
    alpha_p = 0.7
    color_s = :teal
    alpha_s = 0.6
    side_nudge = 0.45 # 0.45 # 0.4
    jitter_width = 0.1 # 0.25 # 0.075
    markersize_p = 4.0 # 0.05 # 0.2 # 1.0 # 0.15 still visible, 0.1 makes them disappear
    markersize_s = 3.8
    n_dots = ndots

    nparams = filter(:variable => v -> isnormalpar(v), params)
    nselected = filter(:variable => v -> isnormalpar(v), selected)
    uparams = filter(:variable => v -> !isnormalpar(v), params)
    uselected = filter(:variable => v -> !isnormalpar(v), selected)

    fbox = Figure(resolution = (width, height));
    # fbox = Figure(resolution = (72 .* (5, 10)), fontsize = 11);

    ax1 = Axis(fbox[1,1];
    limits = ((0.75, 1.25), nothing),
    xticks = 0.8:0.1:1.2,
    yticklabelrotation = π/4,
    )
    ax2 = Axis(fbox[2,1];
        limits = ((-0.2, 2.2), nothing),
        yticklabelrotation = π/4,
        xlabel = "Scaled Value"
    )

    nrcp, nrcs = tworainclouds!(
        ax1, nparams.variable, nparams.value, nselected.variable, nselected.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s, n_dots
    )
    urcp, urcs = tworainclouds!(
        ax2, uparams.variable, uparams.value, uselected.variable, uselected.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s, n_dots
    )
    
    rowsize!(fbox.layout, 1, Relative(normsvstot))
    Label(fbox[:,0], "Parameter", rotation = π/2)
    # return fbox, nrcp, nrcs, urcp, urcs
    return fbox
end

function tworainclouds!(
    ax::Axis, pvariables, pvalues, svariables, svalues,
    color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
    bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
    jitter_width, markersize_p, markersize_s, n_dots
    )
    
    rcp = lessscatterrainclouds!(
        ax,
        pvariables, pvalues,
        color = (color_p, alpha_p),
        # dodge = fill(1, nrow(params)),
        cloud_width = cloud_w_p,
        orientation = :horizontal,
        violin_limits = (0.0, 2.0), # extrema,
        center_boxplot = false,
        boxplot_width = bp_width,
        boxplot_nudge = bp_nudge_p,
        side_nudge = side_nudge,
        jitter_width = jitter_width,
        markersize = markersize_p,
        n_dots = n_dots
    )
    rcs = rainclouds!(
        ax,
        svariables, svalues,
        color = (color_s, alpha_s),
        # dodge = fill(2, nrow(selected)),
        cloud_width = cloud_w_s,
        orientation = :horizontal,
        violin_limits = (0.0, 2.0),# extrema,
        center_boxplot = false,
        boxplot_width = bp_width,
        boxplot_nudge = bp_nudge_s,
        side_nudge = side_nudge,
        markersize = markersize_s
    )
    return rcp, rcs
end

function dodged_rainclouds_maxinf(wideparams::DataFrame, wideselected::DataFrame, nnorms::Int;
    height = 1200, width = 600)

    params = stack(wideparams)
    selected = stack(wideselected)
    normsvstot = nnorms/(ncol(wideselected) - 1)
    maxinfvstot = 0.9/(ncol(wideselected) - 1)
    restvstot = 1.0 - (normsvstot + maxinfvstot)

    cloud_w_p = 1.0
    cloud_w_s = 1.0
    bp_width = 0.1
    bp_nudge_p = 0.12
    bp_nudge_s = 0.24
    color_p = :orange
    alpha_p = 0.7
    color_s = :teal
    alpha_s = 0.6
    side_nudge = 0.45 
    jitter_width = 0.15 
    markersize_p = 0.05 
    markersize_s = 3.8

    nparams = filter(:variable => v -> isnormalpar(v), params)
    nselected = filter(:variable => v -> isnormalpar(v), selected)
    maxinfparams = filter(:variable => v -> v == "max_inf", params)
    maxinfselec = filter(:variable => v -> v == "max_inf", selected)
    uparams = filter(:variable => v -> !isnormalpar(v) && v != "max_inf", params)
    uselected = filter(:variable => v -> !isnormalpar(v) && v != "max_inf", selected)

    fbox = Figure(resolution = (width, height));

    ax1 = Axis(fbox[1,1];
    limits = ((0.75, 1.25), nothing),
    xticks = 0.8:0.1:1.2,
    yticklabelrotation = π/4,
    )
    ax2 = Axis(fbox[2,1];
    limits = ((-0.2, 2.2), nothing),
    yticklabelrotation = π/4,
    bottomspinevisible = false
    )
    hidexdecorations!(ax2, grid = false)
    ax3 = Axis(fbox[3,1];
        limits = ((-0.2, 2.2), nothing),
        yticklabelrotation = π/4,
        topspinevisible = false,
        xlabel = "Scaled Value"
    )
    rowgap!(fbox.layout, 2, 0)

    tworainclouds!(
        ax1, nparams.variable, nparams.value, nselected.variable, nselected.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s
    )

    tworainclouds!(
        ax2, uparams.variable, uparams.value, uselected.variable, uselected.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s
    )

    tworainclouds!(
        ax3, maxinfparams.variable, maxinfparams.value, maxinfselec.variable, maxinfselec.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s
    )
    
    rowsize!(fbox.layout, 1, Relative(normsvstot))
    rowsize!(fbox.layout, 2, Relative(restvstot))
    rowsize!(fbox.layout, 3, Relative(maxinfvstot))
    Label(fbox[:,0], "Parameter", rotation = π/2)
    return fbox
end

function dodged_rainclouds_smalldots(params::DataFrame, selected::DataFrame, relnorms::Float64;
    # height = 1200, 
    width = 800)
    height = width * 2

    bp_width = 0.1
    bp_nudge_p = 0.12
    bp_nudge_s = 0.24
    side_nudge = 0.5
    jitter_width = 0.25
    markersize_p = 0.15
    markersize_s = 3.2
    color_p = :orange
    alpha_p = 0.7
    color_s = :teal
    alpha_s = 0.6

    uparams = filter(:variable => v -> !isnormalpar(v), params)
    uselected = filter(:variable => v -> !isnormalpar(v), selected)
    nparams = filter(:variable => v -> isnormalpar(v), params)
    nselected = filter(:variable => v -> isnormalpar(v), selected)

    fbox = Figure(resolution = (width, height));
    ax1 = Axis(fbox[1,1];
    limits = ((0.75, 1.25), nothing),
    xticks = 0.8:0.1:1.2,
    yticklabelrotation = π/4,
    # xlabel = "Scaled Value"
    )
    ax2 = Axis(fbox[2,1];
        limits = ((-0.2, 2.2), nothing),
        yticklabelrotation = π/4,
        # ylabel = "Parameter",
        xlabel = "Scaled Value"
    )
    tworainclouds!(
        ax1, nparams.variable, nparams.value, nselected.variable, nselected.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s
    )

    tworainclouds!(
        ax2, uparams.variable, uparams.value, uselected.variable, uselected.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s
    )
    rowsize!(fbox.layout, 1, Relative(relnorms))
    Label(fbox[:,0], "Parameter", rotation = π/2)
    return fbox
end