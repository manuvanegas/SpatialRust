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
    strokecs = cgrad(:speed, 10, categorical = true)[3:9]
    cs = collect((c, 0.7) for c in cgrad(:speed, 10, categorical = true)[3:9])

    if yvar == :maxS
        ylabl = rich("Maximum Cumulative Inoculum Metric (",rich("maxSumSpore", font=:italic),")")
    elseif yvar == :loss
        ylabl = rich("Coffee Production Loss\n(",rich("prodLoss", font=:italic),"; %)")
    elseif yvar == :maxA
        ylabl = rich("Maximum Cumulative Latent ", rich("Rust", font=:italic)," Area\n(",rich("maxSumArea", font=:italic),"; cm",superscript("2"),")")
    elseif yvar == :maxE
        ylabl = rich("Maximum Percentage of Exhausted ",rich("Coffees", font=:italic), "\n(",rich("maxExhausted", font=:italic),"; %)")
    else
        ylabl = ylab
    end
    xlabl = rich("Yearly Mean Shading (",rich("meanShading", font=:italic),")")

    if isnothing(yticks)
        yts = Makie.automatic
    else
        yts = yticks
    end

    # if yvar == :maxA
    #     xlims = (19,35)
    # else
    #     xlims = Makie.automatic
    # end

    pl = aogfreqbarr(df, yvar, ylab)

    sq1 = 0.25
    sq2 = 0.75
    sqpoints = Point2f[(sq1, sq1), (sq1, sq2), (sq2, sq2), (sq2, sq1)]

    # draw!(f[1,1], pl, palettes=(
    draw(pl,
        palettes=(
            # layout=[(2,2), (2,1), (1,2), (1,1)],
            marker = ms,
            strokecolor = strokecs,
            color = cs
        ),
        figure = (resolution =(860, 500), fontsize = 15),
        axis = (xticks = 0.0:0.2:0.6, xlabel = xlabl,
            yticks = yts, ylabel = ylabl,
            # limits = (nothing,(20.5,35)),
            xlabelsize = 16, ylabelsize = 16
        ),
        # legend = (position = :top, nbanks = 2)
        legend = (titlesize = 15, labelsize = 13, framevisible = false,
            padding = (0,0,2,2),
            position = :top,
            polypoints = sqpoints,# polycolor = cs,
            linecolor = :transparent, linepoints = [Point2f(0.4, 0.5), Point2f(0.6, 0.5)],
            patchlabelgap = 2, groupgap = 40
        ),
    )
end

function aogfreqbarr(df, yvar, ylab)
    strwdth = 1.5
    mrksz = 10
    shadeval = :shade_val => nonnumeric => "Shading Level Post Pruning"
    shaded = :shade_d => nonnumeric => "Grid Shade Distance"
    dfcols = transform(df, 
        :prunes_year => ByRow(pruningsyear) => :prunes_year,
        :barriers => ByRow(b -> ifelse(b, "With Barriers", "No Barriers")) => :barriers
    )
    colrow = mapping(col = :prunes_year => sorter("3 Prunings / Year", "2 Prunings / Year", "1 Pruning / Year", "Free Growth"), # => 
    # renamer(["Free Growth", "barriers = F", "hi", "hello"]),
    # renamer([0 => "Free Growth", 1 => "barriers = F", 2 => "hi", 3 => "hello"]),
    row = :barriers)# => renamer([true => "With Barriers", false => "No Barriers"]))

    errbars = data(dfcols) * mapping(:meanshade, yvar, Symbol(yvar, :_sd)) *
    mapping(
        group = shaded,
        ) *
    colrow *
    visual(Errorbars, whiskerwidth = 5, color = :gray)


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

    return errbars + linepl + wbarrsc  #+ wobarrsc
    # return linepl + wbarrsc  #+ wobarrsc
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

function scbydistbarr(df, yvar, ylab, yticks = nothing)
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

    pl = aogdistbarr(df, yvar, ylab)

    # draw!(f[1,1], pl, palettes=(
    draw(pl, palettes=(
        # layout=[(2,2), (2,1), (1,2), (1,1)],
        marker = ms,
        strokecolor = strokecs,
        color = strokecs
    ),
    figure = (resolution =(800, 900), fontsize = 15),
    axis = (
        xticks = 0.0:0.1:0.6, 
        xlabel = xlabl,
        yticks = yts, ylabel = ylabl,
        xlabelsize = 16, ylabelsize = 16),
    # legend = (position = :top, nbanks = 2)
    legend = (titlesize = 15, labelsize = 13, framevisible = false),
    facet = (linkxaxes = :minimal,)
    )
end

function aogdistbarr(df, yvar, ylab)
    strwdth = 1.5
    mrksz = 10
    shadeval = :shade_val => nonnumeric => "Pruning\nExtent"
    prunes = :prunes_year => nonnumeric => "Pruning\nFrequency"
    dfcols = transform(df, 
        :shade_d => ByRow(shadedstrings) => :shade_d,
        :barriers => ByRow(b -> ifelse(b, "Barriers Present", "Barriers Absent")) => :barriers
    )
    colrow = mapping(
        row = :shade_d => sorter("Shade Grid: None", "12 x 12", "9 x 9", "6 x 6"),
        col = :barriers
    )

    errbars = data(dfcols) * mapping(:meanshade, yvar, Symbol(yvar, :_sd)) *
    mapping(
        group = prunes,
        ) *
    colrow *
    visual(Errorbars, whiskerwidth = 4, color = :gray)


    linepl = data(dfcols) * mapping(:meanshade, yvar => ylab) *
    mapping(
        group = prunes,
        ) *
    colrow *
    visual(Lines, color = :gray, linestyle = :dot)

    wbarrsc = data(dfcols) * mapping(:meanshade, yvar => ylab) *
    mapping(
        strokecolor = shadeval,
        color = shadeval,
        marker = prunes,
        ) *
    colrow *
    visual(Scatter, strokewidth = strwdth, markersize = mrksz)

    return errbars + linepl + wbarrsc
end

function shadedstrings(n)
    ifelse(n == 100, "Shade Grid: None", ifelse(n == 12, "12 x 12", ifelse(n == 9, "9 x 9", "6 x 6")))
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

function obsvsatt(dfi)
    fs = 18
    alph = 0.7
    blue = (Makie.wong_colors()[1], alph)
    sblue = Makie.wong_colors()[1]
    orange = (Makie.wong_colors()[2], alph)
    sorange = Makie.wong_colors()[2]
    ms = 18
    markers = [:circle, :utriangle, :rect, :diamond]
    # stkcs = cgrad(:speed, 10, categorical = true)[3:10]
    cs = cgrad(:speed, 10, categorical = true)[3:9]

    df = transform(dfi,
        :shade_val => ByRow(s -> prunetocol(s, cs, alph)) => :shadevalcol,
        :shade_val => ByRow(s -> prunetocolst(s, cs)) => :shadevalcolst,
        :shade_d => ByRow(s -> disttomark(s, markers)) => :distmark,
    )

    with_theme(Theme(
        # palette = (marker = markers, strokecolor = cs, color = cs),
        Scatter = (markersize = ms, strokewidth = 2.5,)
    )) do
    fig = Figure(resolution = (850,620), fontsize = fs)
    ax = Axis(fig[1,1],
        xlabel = rich("Yearly Mean Shading (", rich("meanShading", font=:italic), ")"),
        # xlabel = L"Yearly Mean Shading ($meanShading$)",
        ylabel = rich("Production Units (", rich("prodTot", font=:italic), ")"),
        xticks = collect(0.0:0.2:0.6),
        yticks = (collect(3.75e4:0.25e4:4.75e4), string.(collect(3.75:0.25:4.75))),
        xticklabelsize = fs - 2,
        yticklabelsize = fs - 2,
    )
    wbarr = subset(df, :barriers)
    wobarr = subset(df, :barriers => ByRow(!))
    errorbars!(ax, df.meanshade, df.obsprod, df.obsprod_sd, whiskerwidth = 6, color = (:dimgray, 0.8))
    # errorbars!(ax, df.meanshade, df.attprod, df.attprod_sd, whiskerwidth = 6, color = (:gray14, 0.8))
    # scatter!(ax, wbarr.meanshade, wbarr.attprod, marker = :rect, color = orange, strokecolor = sorange)
    # scatter!(ax, wobarr.meanshade, wobarr.attprod, marker = :circle, color = orange, strokecolor = sorange)
    scatter!(ax, wbarr.meanshade, wbarr.obsprod, marker = wbarr.distmark, color = wbarr.shadevalcol, strokecolor = wbarr.shadevalcolst)
    scatter!(ax, wobarr.meanshade, wobarr.obsprod, marker = wobarr.distmark, color = :transparent, strokecolor = wobarr.shadevalcolst)
    # scatter!(ax, wbarr.meanshade, wbarr.obsprod)
    # scatter!(ax, wobarr.meanshade, wobarr.obsprod, color = :transparent)
    
    sqpoints = Point2f[(0.2, 0.2), (0.2, 0.8), (0.8, 0.8), (0.8, 0.2)]
    colorgs = [
        # PolyElement(color = (c, alph), strokecolor = c, strokewidth = 2, points = sqpoints) for c in cs
        MarkerElement(marker = :rect, color = (c, alph), strokecolor = c, strokewidth = 2, markersize = 18) for c in cs
    ]
    colorlabs = string.([0.0; collect(0.1:0.15:0.7); 0.8])
    shapegs = [
        MarkerElement(marker = shape,
        strokecolor = :black, strokewidth = 2,
        color = (:black, 0.4), markersize = 18) for shape in markers
    ]
    shapelabs = ["6", "9", "12", "100"]
    fillgs = [
        MarkerElement(marker = :rect,
        strokecolor = :black, strokewidth = 2,
        color = :transparent, markersize = 18),
        MarkerElement(marker = :rect,
        strokecolor = :black, strokewidth = 2,
        color = (:black, 0.4), markersize = 18),
    ]
    filllabs = ["Absent", "Present"]
    
    # Legend(fig[0,1], [colorgs, shapegs], [colorlabs, shapelabs], ["Shading Level Post Pruning", "Grid Shade Distance"],
    # orientation = :horizontal, 
    # # nbanks = 2,
    # tellwidth = false,
    # framevisible = false,
    # titlesize = fs - 1, labelsize = fs - 2)
    # axislegend(ax, [colorgs, shapegs], [colorlabs, shapelabs], ["Production\nScenario", "Shade Barriers"],
    # position = :rb, #framevisible = false, bgcolor = :white,
    # titlesize = fs - 1, labelsize = fs - 2)
    gl = GridLayout(fig[0,1],)
    Legend(gl[2,1:2], colorgs, colorlabs, "Shading Level Post Pruning",
    orientation = :horizontal, 
    # nbanks = 2,
    tellwidth = false,
    # colgap = 8, patchlabelgap = 2,
    framevisible = false,
    titlesize = fs - 1, labelsize = fs - 2,
    # alignmode = Mixed(left = 30)
    )
    Legend(gl[1,1], shapegs, shapelabs, "Grid Shade Distance",
    orientation = :horizontal, 
    # nbanks = 2,
    tellwidth = false,
    # colgap = 8, patchlabelgap = 2,
    framevisible = false,
    titlesize = fs - 1, labelsize = fs - 2)
    Legend(gl[1,2], fillgs, filllabs, "Shade Barriers",
    orientation = :horizontal, 
    # nbanks = 2,
    tellwidth = false,
    # colgap = 8, patchlabelgap = 2,
    framevisible = false,
    titlesize = fs - 1, labelsize = fs - 2)
    colgap!(gl, 5)
    rowgap!(gl, 0)
    rowgap!(fig.layout, 10)
    colsize!(gl, 1, Relative(5/15))
    colsize!(gl, 2, Relative(4/15))
    # colsize!(gl, 3, Relative(2/15))

    ms2 = 10
    stw = 1.2
    ax2 = Axis(fig, 
        # bbox = BBox(420, 610, 100, 290),
        bbox = BBox(560, 805, 100, 235),
        title = "Attainable Production", titlesize = 14,
        backgroundcolor = :white,
        xticks = collect(0.0:0.2:0.6),
        yticks = (collect(1.2e5:0.1e5:1.4e5), string.(collect(12:1:14))),
        xticklabelsize = fs - 2,
        yticklabelsize = fs - 2,
    )
    errorbars!(ax2, df.meanshade, df.attprod, df.attprod_sd, whiskerwidth = 6, color = (:dimgray, 0.8))
    scatter!(ax2, wbarr.meanshade, wbarr.attprod, marker = wbarr.distmark, color = blue, strokecolor = sblue, markersize = ms2, strokewidth = stw)
    scatter!(ax2, wobarr.meanshade, wobarr.attprod, marker = wobarr.distmark, color = :transparent, strokecolor = sblue, markersize = ms2, strokewidth = stw)
    # scatter!(ax2, wbarr.meanshade, wbarr.attprod, marker = wbarr.distmark, color = wbarr.shadevalcol, strokecolor = wbarr.shadevalcolst, markersize = ms2, strokewidth = stw)
    # scatter!(ax2, wobarr.meanshade, wobarr.attprod, marker = wobarr.distmark, color = :transparent, strokecolor = wobarr.shadevalcolst, markersize = ms2, strokewidth = stw)
    translate!(ax2.blockscene, 0, 0, 500)
    return fig
    end
end

function prunetocol(prune, cols, alpha)
    w = searchsortedfirst([0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.8], prune)
    return (cols[w], alpha)
end

function prunetocolst(prune, cols)
    w = searchsortedfirst([0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.8], prune)
    return cols[w]
end

function disttomark(dist, marks)
    w = searchsortedfirst([6,9,12,100], dist)
    return marks[w]
end

function scjustobs(df, wiatt)
    strokecs = cgrad(:speed, 10, categorical = true)[3:10]

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