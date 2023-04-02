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
    color_p = :goldenrod # :sandybrown
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
    uparams = filter(:variable => v -> !isnormalpar(v) && v != "wind_distance", params)
    uselected = filter(:variable => v -> !isnormalpar(v) && v != "wind_distance", selected)

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