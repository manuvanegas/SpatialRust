# Vars vs meanshade scatterplots

function basescattershade(df, yvar, cvar)
    fs,as,sc = scatter(df[!, :meanshade], df[!, yvar], color = (df[!, cvar]))
    Colorbar(fs[1,2], sc)
    return fs
end

function scbyprunefreq(df, yvar)
    f = Figure(resolution = (500, 500), fontsize = 16,)
    ms = [:circle, :utriangle, :rect, :diamond]
    strokecs = cgrad(:speed, 9, categorical = true)[2:9]
    strwdth = 1.5
    mrksz = 10
    linepl = data(sort(df, yvar)) * mapping(:meanshade, yvar) *
    mapping(
        group = :shade_d => nonnumeric,) *
    mapping(layout = :prunes_year => nonnumeric) *
    visual(Lines, color = :gray, linestyle = :dot)

    wvars = data(subset(df, :barriers)) * mapping(:meanshade, yvar)
    wbarrsc = wvars *
    mapping(
        strokecolor = :shade_val => nonnumeric,
        color = :shade_val => nonnumeric,
        marker = :shade_d => nonnumeric,) *
    mapping(layout = :prunes_year => nonnumeric) *
    visual(Scatter, strokewidth = strwdth, markersize = mrksz)

    wovars = data(subset(df, :barriers => .!)) * mapping(:meanshade, yvar)
    wobarrsc = wovars *
    mapping(
        strokecolor = :shade_val => nonnumeric,
        marker = :shade_d => nonnumeric,) *
    mapping(layout = :prunes_year => nonnumeric) *
    visual(Scatter, strokewidth = strwdth, markersize = mrksz, color = :transparent)

    pl = linepl + wbarrsc + wobarrsc

    draw!(f[1,1], pl, palettes=(
        layout=[(2,2), (2,1), (1,2), (1,1)],
        marker = ms,
        strokecolor = strokecs,
        color = strokecs
    ))
    return f
end

function scbyprunefreqbarr(df, yvar, ylab)
    # f = Figure(resolution = (900, 500), fontsize = 16,)
    ms = [:circle, :utriangle, :rect, :diamond]
    strokecs = cgrad(:speed, 10, categorical = true)[3:10]
    cs = cgrad(:speed, 10, categorical = true)[2:9]

    pl = aogfreqbarr(df, yvar, ylab)

    # draw!(f[1,1], pl, palettes=(
    draw(pl, palettes=(
        layout=[(2,2), (2,1), (1,2), (1,1)],
        marker = ms,
        strokecolor = strokecs,
        color = strokecs
    ),
    figure = (resolution =(860, 400),),
    axis = (xticks = 0.0:0.2:0.6,),
    # legend = (position = :top, nbanks = 2)
    legend = (titlesize = 14, labelsize = 12, framevisible = false)
    )
end

function aogfreqbarr(df, yvar, ylab)
    strwdth = 1.5
    mrksz = 10
    shadeval = :shade_val => nonnumeric => "Pruning\nExtent"
    shaded = :shade_d => nonnumeric => "Shade\nDistance"
    "solve col names issue by adding a column to the df with the correct names"
    colrow = mapping(col = :prunes_year => nonnumeric, # => 
    # renamer(["Free Growth", "barriers = F", "hi", "hello"]),
    # renamer([0 => "Free Growth", 1 => "barriers = F", 2 => "hi", 3 => "hello"]),
    row = :barriers => renamer([true => "barriers = T", false => "barriers = F"]))

    linepl = data(df) * mapping(:meanshade => "Yearly Mean Shading", yvar => ylab) *
    mapping(
        group = shaded,
        ) *
    colrow *
    visual(Lines, color = :gray, linestyle = :dot)

    wbarrsc = data(df) * mapping(:meanshade => "Yearly Mean Shading", yvar => ylab) *
    mapping(
        strokecolor = shadeval,
        color = shadeval,
        marker = shaded,
        ) *
    colrow *
    visual(Scatter, strokewidth = strwdth, markersize = mrksz)

    # wobarrsc = data(subset(df, :barriers => .!)) * mapping(:meanshade, yvar => ylab) *
    # mapping(
    #     strokecolor = :shade_val => nonnumeric,
    #     color = :shade_val => nonnumeric,
    #     marker = :shade_d => nonnumeric,) *
    # colrow *
    # visual(Scatter, strokewidth = strwdth, markersize = mrksz)#, color = :transparent)

    return linepl + wbarrsc #+ wobarrsc
end

# function drawsc!(f, df, yvar)
#     # f = Figure(resolution = (900, 500), fontsize = 16,)
#     ms = [:circle, :utriangle, :rect, :diamond]
#     strokecs = cgrad(:speed, 10, categorical = true)[3:10]
#     cs = cgrad(:speed, 10, categorical = true)[2:9]
#     pl = aogfreqbarr(df, yvar)
#     draw!(f[1,1], pl, palettes=(
#         layout=[(2,2), (2,1), (1,2), (1,1)],
#         marker = ms,
#         strokecolor = strokecs,
#         color = cs
#     ))
#     return f
# end

###################

function scbyshadedist(df, yvar)
    f = Figure(resolution = (500, 500), fontsize = 16,)
    ms = [:circle, :utriangle, :rect, :diamond]
    strokecs = cgrad(:speed, 9, categorical = true)[2:9]
    strwdth = 1.2
    mrksz = 10
    linepl = data(sort(df, yvar)) * mapping(:meanshade, yvar) *
    mapping(
        group = :prunes_year => nonnumeric,) *
    mapping(layout = :shade_d => nonnumeric) *
    visual(Lines, color = :gray, linestyle = :dot)

    wvars = data(subset(df, :barriers)) * mapping(:meanshade, yvar)
    wbarrsc = wvars *
    mapping(
        strokecolor = :shade_val => nonnumeric,
        color = :shade_val => nonnumeric,
        marker = :prunes_year => nonnumeric,) *
    mapping(layout = :shade_d => nonnumeric) *
    visual(Scatter, strokewidth = strwdth, markersize = mrksz)

    wovars = data(subset(df, :barriers => .!)) * mapping(:meanshade, yvar)
    wobarrsc = wovars *
    mapping(
        strokecolor = :shade_val => nonnumeric,
        marker = :prunes_year => nonnumeric,) *
    mapping(layout = :shade_d => nonnumeric) *
    visual(Scatter, strokewidth = strwdth, markersize = mrksz, color = :transparent)

    pl = linepl + wbarrsc + wobarrsc

    draw!(f[1,1], pl, palettes=(
        layout=[(2,2), (2,1), (1,2), (1,1)],
        marker = ms,
        strokecolor = strokecs,
        color = strokecs
    ),
    # facet=(; linkxaxes=:none,)
    )
    return f
end

function scbyshadedistbarr(df, yvar)
    f = Figure(resolution = (900, 500), fontsize = 16,)
    ms = [:circle, :utriangle, :rect, :diamond]
    strokecs = [:orange; cgrad(:speed, 9, categorical = true)[3:9]]
    strwdth = 1.2
    mrksz = 10
    linepl = data(sort(df, yvar)) * mapping(:meanshade, yvar) *
    mapping(
        group = :prunes_year => nonnumeric,) *
    mapping(col = :shade_d => nonnumeric, row = :barriers) *
    visual(Lines, color = :gray, linestyle = :dot)

    wvars = data(subset(df, :barriers)) * mapping(:meanshade, yvar)
    wbarrsc = wvars *
    mapping(
        strokecolor = :shade_val => nonnumeric,
        color = :shade_val => nonnumeric,
        marker = :prunes_year => nonnumeric,) *
    mapping(col = :shade_d => nonnumeric, row = :barriers) *
    visual(Scatter, strokewidth = strwdth, markersize = mrksz)

    wovars = data(subset(df, :barriers => .!)) * mapping(:meanshade, yvar)
    wobarrsc = wovars *
    mapping(
        strokecolor = :shade_val => nonnumeric,
        color = :shade_val => nonnumeric,
        marker = :prunes_year => nonnumeric,) *
    mapping(col = :shade_d => nonnumeric, row = :barriers) *
    visual(Scatter, strokewidth = strwdth, markersize = mrksz)#, color = :transparent)

    pl = linepl + wbarrsc + wobarrsc

    draw!(f[1,1], pl, palettes=(
        # layout=[(2,2), (2,1), (1,2), (1,1)],
        marker = ms,
        strokecolor = strokecs,
        color = strokecs
    ),
    facet=(; linkxaxes=:minimal,)
    )
    return f
end

function add_legend!(f)
    mks = [:circle, :utriangle, :rect, :diamond]
    strokecs = cgrad(:speed, 10, categorical = true)[3:10]
    cs = cgrad(:speed, 10, categorical = true)[2:9]

    markerleg = [MarkerElement(marker = ms,
    color = :gray, strokecolor = :black, strokewidth = 1,
    markersize = 10) for ms in mks]
    colorleg = [PolyElement(color = color, strokecolor = strcolor)
    for (strcolor, color) in zip(strokecs, cs)]

    markerlabels = ["6", "9", "12", "100"]
    colorlabels = string.([0.0; collect(0.1:0.15:0.7); 0.8])
    Legend(f[1,2], 
    [markerleg, colorleg],
    [markerlabels, colorlabels],
    ["Shade Distance", "Shade Post Pruning"]
    )
    return f
end

function get_legend(f)
    mks = [:circle, :utriangle, :rect, :diamond]
    strokecs = cgrad(:speed, 10, categorical = true)[3:10]
    cs = cgrad(:speed, 10, categorical = true)[2:9]

    markerleg = [MarkerElement(marker = ms,
    color = :gray, strokecolor = :black, strokewidth = 1,
    markersize = 10) for ms in mks]
    colorleg = [PolyElement(color = color, strokecolor = strcolor, strokewidth = 1.5,
    points = Point2f[(0.15, 0.15), (0.85, 0.15), (0.85, 0.85), (0.15, 0.85)])
    for (strcolor, color) in zip(strokecs, cs)]
    # colorleg = [PolyElement(color = color, strokecolor = :transparent)
    # for color in cs]

    markerlabels = ["6", "9", "12", "100"]
    colorlabels = string.([0.0; collect(0.1:0.15:0.7); 0.8])
    legend = Legend(f, 
    [markerleg, colorleg],
    [markerlabels, colorlabels],
    ["Shade Distance", "Shade Post Pruning"]
    )
    f[1,2] = legend
    # Legend(f[3,1], 
    # markerleg,
    # markerlabels,
    # "Shade Distance",
    # )
    return f
end

###
# Save fns

function savehere(name, fig)
    save(joinpath("plots/Shading/now",name), fig)
end
function savediss(name, fig)
    p = mkpath("../../Dissertation/Chapters/Diss/Document/Figs/Shading")
    save(joinpath(p,name), fig, px_per_unit = 2)
end