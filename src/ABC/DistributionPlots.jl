function significant(par, is)
    is ? string(par,"*") : par
end

four_dodged_rainclouds(params::DataFrame, selected::DataFrame, nnorms::Int, randpars::Vector{Int}, ndots::Int; kwargs...) =
four_dodged_rainclouds(params[randpars, :], selected, nnorms, ndots; kwargs...)

function four_dodged_rainclouds(wideparams::DataFrame, wideselected::DataFrame, nsep::Int, ndots::Int;
    height = 900, width = 800)

    p05 = [:wind_dst, :spore_pct, :pdry_spo, :temp_ampl]
    prest1 = [:shade_block, :tree_block, :rain_dst]
    prest2 = Not([:opt_temp; p05; prest1; :rust_paras])

    opttemppar = stack(wideparams,:opt_temp)[:,18:19]
    opttempsel = stack(wideselected,:opt_temp)[:,18:19]
    v05par = stack(wideparams[:, p05])
    v05sel = stack(wideselected[:, p05])
    restpar1 = stack(wideparams[:, prest1])
    restsel1 = stack(wideselected[:, prest1])
    restpar2 = stack(wideparams[:, prest2])
    restsel2 = stack(wideselected[:, prest2])
    rustppar = stack(wideparams,:rust_paras)[:,18:19]
    rustpsel = stack(wideselected,:rust_paras)[:,18:19]
    optvstot = 1/8
    v05vstot = 4/8
    restvstot = 10/11

    # cs = cgrad(:roma, 10, categorical = true)
    # cs2 = cgrad(:broc10, 10, categorical = true)

    cloud_w_p = 1.0
    cloud_w_s = 1.0
    bp_width = 0.1
    bp_nudge_p = 0.12
    bp_nudge_s = 0.24
    color_p = :navajowhite3
    alpha_p = 0.7
    # color_s = :darkcyan
    color_s = :deepskyblue4
    alpha_s = 0.6
    side_nudge = 0.45 
    jitter_width = 0.15 
    markersize_p = 4.0
    markersize_s = 4.5
    n_dots = ndots

    fbox = Figure(resolution = (width, height));

    ga = GridLayout(fbox[1,1])
    ax1 = Axis(ga[1,1];
    limits = ((0.91, 1.09), (0.45,1.6)),
    xticks = 0.95:0.05:1.05,
    yticklabelrotation = π/4,
    )
    ax2 = Axis(ga[2,1];
    limits = ((0.45, 1.55), (0.45,4.6)),
    xticks = 0.5:0.2:1.5,
    yticklabelrotation = π/4,
    # xlabel = "Scaled Value"
    )
    ax3 = Axis(ga[3,1];
    limits = ((-0.1, 2.1), (0.45,3.6)),
    yticklabelrotation = π/4,
    xlabel = "Scaled Value"
    )
    
    gb = GridLayout(fbox[1,2])
    ax4 = Axis(gb[1,1];
    limits = ((-0.1, 2.1), (0.4,8.6)),
    yticklabelrotation = π/4,
    bottomspinevisible = false
    )
    hidexdecorations!(ax4, grid = false)
    ax5 = Axis(gb[2,1];
        limits = ((-0.1, 2.1), (0.45,1.55)),
        yticklabelrotation = π/4,
        topspinevisible = false,
        xlabel = "Scaled Value"
    )
    rowgap!(gb, 0)

    tworainclouds!(
        ax1, opttemppar.variable, opttemppar.value, opttempsel.variable, opttempsel.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s, n_dots, (0.89,1.11)
    )

    tworainclouds!(
        ax2, v05par.variable, v05par.value, v05sel.variable, v05sel.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p + 0.1, cloud_w_s,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s, n_dots, (0.52,1.48)
    )

    tworainclouds!(
        ax3, restpar1.variable, restpar1.value, restsel1.variable, restsel1.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p - 0.55, cloud_w_s - 0.7,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s, ndots, (-0.05,2.05)
    )

    tworainclouds!(
        ax4, restpar2.variable, restpar2.value, restsel2.variable, restsel2.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p - 0.35, cloud_w_s - 0.1,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s, ndots, (-0.05,2.05)
    )

    tworainclouds!(
        ax5, rustppar.variable, rustppar.value, rustpsel.variable, rustpsel.value,
        color_p, color_s, alpha_p, alpha_s, cloud_w_p - 0.4, cloud_w_s + 0.35,
        bp_width, bp_nudge_p, bp_nudge_s, side_nudge,
        jitter_width, markersize_p, markersize_s, ndots, (-0.05,2.05)
    )
    
    rowsize!(ga, 1, Relative(optvstot))
    rowsize!(ga, 2, Relative(v05vstot))
    # rowsize!(fbox.layout, 2, Relative(v05vstot))
    rowsize!(gb, 1, Relative(restvstot))
    # rowsize!(fbox.layout, 4, Relative(rustpvstot))
    Label(fbox[:,0], "Parameter", rotation = π/2, padding = (0,-30,0,0), fontsize = 18, tellheight = false)
    return fbox
end

dodged_rainclouds(params::DataFrame, selected::DataFrame, nnorms::Int, randpars::Vector{Int}, ndots::Int; kwargs...) =
dodged_rainclouds(params[randpars, :], selected, nnorms, ndots; kwargs...)

isnormalpar(v::String) = v ∈ ("opt_temp", "temp_cooling", "pdry_spo", "spore_pct", "wind_dst")

function dodged_rainclouds(wideparams::DataFrame, wideselected::DataFrame, nnorms::Int, ndots::Int;
    height = 1200, width = 600)

    # wideparamsc = select(wideparams, Not([:wind_distance, :res_commit, :µ_prod]))
    # wideselectedc = select(wideselected, Not([:wind_distance, :res_commit, :µ_prod]))
    wideparamsc = wideparams
    wideselectedc = wideselected

    normsvstot = nnorms/(ncol(wideselectedc) - 1)

    params = stack(wideparamsc)
    selected = stack(wideselectedc)

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
        jitter_width, markersize_p, markersize_s, n_dots, 
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
    jitter_width, markersize_p, markersize_s, n_dots, lims
    )
    
    rcp = lessscatterrainclouds!(
        # rcp = rainclouds!(
        ax,
        pvariables, pvalues,
        color = (color_p, alpha_p),
        # dodge = fill(1, nrow(params)),
        cloud_width = cloud_w_p,
        orientation = :horizontal,
        violin_limits = lims, # extrema,
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
        violin_limits = lims,# extrema,
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