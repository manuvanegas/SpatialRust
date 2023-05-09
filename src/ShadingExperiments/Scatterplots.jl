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

function scbyprunefreqbarr(df, yvar, ylab, yticks = nothing)
    # f = Figure(resolution = (900, 500), fontsize = 16,)
    ms = [:circle, :utriangle, :rect, :diamond]
    strokecs = cgrad(:speed, 10, categorical = true)[3:10]
    # cs = cgrad(:speed, 10, categorical = true)[2:9]

    if yvar == :maxS
        ylabl = rich("Maximum Cumulative Inoculum Metric\n(",rich("maxSumSpore", font=:italic),")")
    elseif yvar == :loss
        ylabl = rich("Production Loss (%)\n(",rich("prodLoss", font=:italic),")")
    else
        ylabl = ylab
    end
    xlabl = rich("Yearly Mean Shading\n(",rich("meanShading", font=:italic),")")

    if isnothing(yticks)
        yts = Makie.automatic
    else
        yts = yticks
    end

    pl = aogfreqbarr(df, yvar, ylab)

    # draw!(f[1,1], pl, palettes=(
    draw(pl, palettes=(
        layout=[(2,2), (2,1), (1,2), (1,1)],
        marker = ms,
        strokecolor = strokecs,
        color = strokecs
    ),
    figure = (resolution =(860, 400), fontsize = 12),
    axis = (xticks = 0.0:0.2:0.6, xlabel = xlabl,
        yticks = yts, ylabel = ylabl,
        xlabelsize = 15, ylabelsize = 15),
    # legend = (position = :top, nbanks = 2)
    legend = (titlesize = 13, labelsize = 12, framevisible = false),
    )
end

function aogfreqbarr(df, yvar, ylab)
    strwdth = 1.5
    mrksz = 10
    shadeval = :shade_val => nonnumeric => "Pruning\nExtent"
    shaded = :shade_d => nonnumeric => "Shade\nDistance"
    dfcols = transform(df, 
        :prunes_year => ByRow(pruningsyear) => :prunes_year,
        :barriers => ByRow(b -> ifelse(b, "With Barriers", "No Barriers")) => :barriers
    )
    colrow = mapping(col = :prunes_year => sorter("Free Growth", "1 Pruning / Year", "2 Prunings / Year", "3 Prunings / Year"), # => 
    # renamer(["Free Growth", "barriers = F", "hi", "hello"]),
    # renamer([0 => "Free Growth", 1 => "barriers = F", 2 => "hi", 3 => "hello"]),
    row = :barriers)# => renamer([true => "With Barriers", false => "No Barriers"]))

    # errbars = data(dfcols) * mapping(:meanshade, yvar, Symbol(yvar, :_sd)) *
    # mapping(
    #     group = shaded,
    #     ) *
    # colrow *
    # visual(Errorbars, whiskerwidth = 5)


    linepl = data(dfcols) * mapping(:meanshade, yvar => ylab) *
    mapping(
        group = shaded,
        ) *
    colrow *
    visual(Lines, color = :gray, linestyle = :dot)

    wbarrsc = data(dfcols) * mapping(:meanshade, yvar => ylab) *
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

    # return errbars + linepl + wbarrsc  #+ wobarrsc
    return linepl + wbarrsc  #+ wobarrsc
end

pruningsyear(n) = ifelse(n == 0, "Free Growth", ifelse(n == 1, "1 Pruning / Year", string(n, " Prunings / Year")))

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

###############
# Obs vs Att prod

function obsvsatt(df)
    fs = 18
    alph = 0.7
    blue = (Makie.wong_colors()[1], alph)
    sblue = Makie.wong_colors()[1]
    orange = (Makie.wong_colors()[2], alph)
    sorange = Makie.wong_colors()[2]
    ms = 18
    with_theme(Theme(
        Scatter = (markersize = ms, strokewidth = 2,)
    )) do
    fig = Figure(resolution = (800,600), fontsize = fs)
    ax = Axis(fig[1,1],
        xlabel = "Yearly Mean Shading",
        ylabel = "Production Units",
        xticks = collect(0.0:0.2:0.6),
        yticks = (collect(0.4e5:0.2e5:1.4e5), string.(collect(40:20:140))),
        xticklabelsize = fs - 2,
        yticklabelsize = fs - 2,
    )
    wbarr = subset(df, :barriers)
    wobarr = subset(df, :barriers => ByRow(!))
    errorbars!(ax, df.meanshade, df.obsprod, df.obsprod_sd, whiskerwidth = 6, color = (:gray14, 0.8))
    # errorbars!(ax, df.meanshade, df.attprod, df.attprod_sd, whiskerwidth = 6, color = (:gray14, 0.8))
    scatter!(ax, wbarr.meanshade, wbarr.attprod, marker = :rect, color = orange, strokecolor = sorange)
    scatter!(ax, wobarr.meanshade, wobarr.attprod, marker = :circle, color = orange, strokecolor = sorange)
    scatter!(ax, wbarr.meanshade, wbarr.obsprod, marker = :rect, color = blue, strokecolor = sblue)
    scatter!(ax, wobarr.meanshade, wobarr.obsprod, marker = :circle, color = blue, strokecolor = sblue)
    
    sqpoints = Point2f[(0.15, 0.15), (0.15, 0.85), (0.85, 0.85), (0.85, 0.15)]
    colorgs = [
        PolyElement(color = orange, strokecolor = sorange, strokewidth = 2, points = sqpoints),
        PolyElement(color = blue, strokecolor = sblue, strokewidth = 2, points = sqpoints)
    ]
    colorlabs = ["Attainable", "Observed"]
    shapegs = [
        MarkerElement(marker = shape,
        strokecolor = :black, strokewidth = 2,
        color = (:black, alph), markersize = 18) for shape in [:circle, :rect]
    ]
    shapelabs = ["Absent", "Present"]
    
    # Legend(fig[0,1], [colorgs, shapegs], [colorlabs, shapelabs], ["Production", "Shade Barriers"],
    # orientation = :horizontal, tellwidth = false,
    # titlesize = fs - 1, labelsize = fs - 2)
    axislegend(ax, [colorgs, shapegs], [colorlabs, shapelabs], ["Production\nScenario", "Shade Barriers"],
    position = :rb, #framevisible = false, bgcolor = :white,
    titlesize = fs - 1, labelsize = fs - 2)
    return fig
    end
end



###############
# Save fns

function savehere(name, fig)
    save(joinpath("plots/Shading/now",name), fig)
end
function savediss(name, fig)
    p = mkpath("../../Dissertation/Chapters/Diss/Document/Figs/Shading")
    save(joinpath(p,name), fig, px_per_unit = 2)
end

#####
# For raw output files
function correctshadeval(shdist,b,py,val)
    if shdist == 100 && b && py == 0
        return 0.8
    else
        return val
    end
end