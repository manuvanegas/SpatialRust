# Meanshade heatmaps

function shade_heatmap(df)
    f = Figure(resolution = (860, 630), fontsize = 16)
    fig = GridLayout(f[1,1])
    # withshades = subset(df, :n_shades => ByRow(>(0)), :shade_val => ByRow(<(0.8)))
    withshades = subset(df, :n_shades => ByRow(>(0)))
    nshadeopts = sort!(unique(withshades.n_shades))
    withshades[!, :shlevel] = searchsortedfirst.(Ref(nshadeopts), withshades[!, :n_shades])
    bynum = groupby(withshades, :prunes_year)
    # prune0 = bynum[1]
    climits = extrema(withshades.meanshade)
    ax1, hm1 = single_hm(fig[1,1], bynum[4], climits)
    ax2, hm2 = single_hm(fig[1,2], bynum[3], climits)
    ax3, hm3 = single_hm(fig[1,3], bynum[2], climits)
    ax4, hm4 = noprune_hm(fig[1,4], bynum[1], climits)
    # hlines!.([ax1, ax2, ax3, ax4], [3.5], linewidth = 3, color = :steelblue3)
    c1 = :dodgerblue3
    c2 = :dodgerblue1
    c3 = :steelblue3
    hlines!(ax1, [1.5, 2.48], xmin = 0.4, xmax = 0.6, linewidth = 3, color = c1)
    vlines!(ax1, [0.325, 0.475], ymin = 0.139, ymax = 0.288, linewidth = 3, color = c1)
    hlines!(ax2, [5.5, 6.48], xmin = 0.4, xmax = 0.6, linewidth = 3, color = c2)
    vlines!(ax2, [0.325, 0.475], ymin = 0.714, ymax = 0.857, linewidth = 3, color = c2)
    hlines!(ax3, [6.5, 7.47], xmin = 0.4, xmax = 0.6, linewidth = 3, color = c3)
    vlines!(ax3, [0.325, 0.475], ymin = 0.857, ymax = 1.0, linewidth = 3, color = c3)
    
    ax1.ylabel = "Number of Shade Trees"
    # ax1.xlabel = "Pruning Shade Level"
    # ax2.xlabel = "Pruning Shade Level"
    # ax1.xaxisposition = :top
    # ax2.xaxisposition = :top
    hideydecorations!(ax2)
    hideydecorations!(ax3)
    # hideydecorations!(ax4)
    ax4.yaxisposition = :right
    # Colorbar(fig[1,5], hm1, label = "Yearly Mean Shading", ticks = 0.1:0.1:0.6, width = 14)
    colsize!(fig, 1, Relative(0.31))#Aspect(1, 0.74))
    colsize!(fig, 2, Relative(0.31))#Aspect(1, 0.74))
    colsize!(fig, 3, Relative(0.31))#Aspect(1, 0.74))
    colsize!(fig, 4, Relative(0.06))#Aspect(1, 0.14))
    # Label(fig[1,0], "Number of Shade Trees", tellheight = false, rotation = pi/2)
    Label(fig[2,1:4], "Individual Shade Post Pruning", padding = (0,0,0,-15))
    Colorbar(fig[-1,1:4], hm1, 
        label = rich("Yearly Mean Shading (",rich("meanShading", font=:italic),")"),
        ticks = 0.1:0.1:0.6,
        vertical = false, flipaxis = true, width = 300,
        ticklabelsize = 14,
        # bottomspinevisible = false, topspinevisible = false, leftspinevisible = false, rightspinevisible = false,
    )
    Label(fig[0,1], "Pruning\nFrequency:", 
    tellheight = false, tellwidth = false, halign = :left, padding = (-75,0,0,0))
    Label(fig[0,1], "3 per Year")
    Label(fig[0,2], "2 per Year")
    Label(fig[0,3], "1 per Year")
    Label(fig[0,4], "Free Growth")
    rowsize!(fig, -1, 0.08)
    # resize_to_layout!(fig)
    # colsize!(fig.layout, 5, Aspect(1, 0.15))
    return f
end

function single_hm(ax, df, climits)
    ax, hm = heatmap(ax, df.shade_val, df.shlevel, df.meanshade, colorrange = climits, colormap = :speed)
    ax.xticks = collect(0.1:0.15:0.7)
    ax.yticks = (collect(1:7), string.([81,144,289,784,848,884,1040]))
    ax.xticklabelsize = 14
    ax.yticklabelsize = 14
    ax.xticksvisible = false
    ax.yticksvisible = false
    return ax, hm
end

function noprune_hm(ax, df, climits)
    ax, hm = heatmap(ax, df.shade_val, df.shlevel, df.meanshade, colorrange = climits, colormap = :speed)
    ax.xticks = [0.8,]
    ax.yticks = (collect(1:7), string.([81,144,289,784,848,884,1040]))
    ax.xticklabelsize = 14
    ax.yticklabelsize = 12
    ax.xticksvisible = false
    # ax.yticksvisible = false
    ax.yticksize = 4
    ax.yticks = (collect(1:7), [
        # "No barriers, 12x12", "No barriers, 9x9", "No barriers, 6x6",
        # "Barriers, 100x100","Barriers, 12x12","Barriers, 9x9","Barriers, 6x6",
        "barriers = F,\nshade_d = 12", "barriers = F,\nshade_d = 9", "barriers = F,\nshade_d = 6",
        "barriers = T,\nshade_d = 100","barriers = T,\nshade_d = 12","barriers = T,\nshade_d = 9","barriers = T,\nshade_d = 6",
    ]
    )
    return ax, hm
end

######
# Intensity instead of original shade_val

function shade_heatmap_intensity(df)
    fig = Figure(resolution = (860, 450), fontsize = 16)
    # withshades = subset(df, :n_shades => ByRow(>(0)), :shade_val => ByRow(<(0.8)))
    withshades = subset(df, :n_shades => ByRow(>(0)))
    nshadeopts = sort!(unique(withshades.n_shades))
    withshades[!, :shlevel] = searchsortedfirst.(Ref(nshadeopts), withshades[!, :n_shades])
    bynum = groupby(withshades, :prunes_year)
    # prune0 = bynum[1]
    climits = extrema(withshades.meanshade)
    ax1, hm1 = single_hm_intensity(fig[1,1], bynum[4], climits)
    ax2, hm2 = single_hm_intensity(fig[1,2], bynum[3], climits)
    ax3, hm3 = single_hm_intensity(fig[1,3], bynum[2], climits)
    ax4, hm4 = noprune_hm_intensity(fig[1,4], bynum[1], climits)
    # hlines!.([ax1, ax2, ax3, ax4], [3.5], linewidth = 3, color = :steelblue3)
    
    ax1.ylabel = "Number of Shade Trees"
    # ax1.xlabel = "Pruning Shade Level"
    # ax2.xlabel = "Pruning Shade Level"
    # ax1.xaxisposition = :top
    # ax2.xaxisposition = :top
    hideydecorations!(ax2)
    hideydecorations!(ax3)
    # hideydecorations!(ax4)
    ax4.yaxisposition = :right
    # Colorbar(fig[1,5], hm1, label = "Yearly Mean Shading", ticks = 0.1:0.1:0.6, width = 14)
    colsize!(fig.layout, 1, Relative(0.31))#Aspect(1, 0.74))
    colsize!(fig.layout, 2, Relative(0.31))#Aspect(1, 0.74))
    colsize!(fig.layout, 3, Relative(0.31))#Aspect(1, 0.74))
    colsize!(fig.layout, 4, Relative(0.06))#Aspect(1, 0.14))
    # Label(fig[1,0], "Number of Shade Trees", tellheight = false, rotation = pi/2)
    Label(fig[2,1:4], rich("Pruning Intensity (0.8 - ", rich("post_prune", font = :italic), ")"), padding = (0,0,0,-15))
    # Label(fig[2,1:4], rich("Pruning Intensity (", rich("pr_ints", font = :italic), ")"), padding = (0,0,0,-15))
    Colorbar(fig[3,1:4], hm1, label = "Yearly Mean Shading", ticks = 0.1:0.1:0.6,
    vertical = false, flipaxis = false, width = 300
    )
    Label(fig[0,1], "Pruning\nFrequency:", 
    tellheight = false, tellwidth = false, halign = :left, padding = (-75,0,0,0))
    Label(fig[0,1], "3 per Year")
    Label(fig[0,2], "2 per Year")
    Label(fig[0,3], "1 per Year")
    Label(fig[0,4], "Free Growth")
    # resize_to_layout!(fig)
    # colsize!(fig.layout, 5, Aspect(1, 0.15))
    return fig
end

function single_hm_intensity(ax, df, climits)
    ax, hm = heatmap(ax, df.shade_val, df.shlevel, df.meanshade, colorrange = climits, colormap = :speed)
    # ax.xticks = collect(0.1:0.15:0.7)
    ax.xticks = (collect(0.1:0.15:0.7), string.(0.7:-0.15:0.1))
    ax.yticks = (collect(1:7), string.([81,144,289,784,848,884,1040]))
    ax.xticklabelsize = 14
    ax.yticklabelsize = 14
    ax.xticksvisible = false
    ax.yticksvisible = false
    return ax, hm
end

function noprune_hm_intensity(ax, df, climits)
    ax, hm = heatmap(ax, df.shade_val, df.shlevel, df.meanshade, colorrange = climits, colormap = :speed)
    # ax.xticks = [0.8,]
    ax.xticks = ([0.8,],string.([0.0,]))
    ax.yticks = (collect(1:7), string.([81,144,289,784,848,884,1040]))
    ax.xticklabelsize = 14
    ax.yticklabelsize = 11
    ax.xticksvisible = false
    # ax.yticksvisible = false
    ax.yticksize = 4
    ax.yticks = (collect(1:7), [
        # "No barriers, 12x12", "No barriers, 9x9", "No barriers, 6x6",
        # "Barriers, 100x100","Barriers, 12x12","Barriers, 9x9","Barriers, 6x6",
        "barriers = F,\nshade_d = 12", "barriers = F,\nshade_d = 9", "barriers = F,\nshade_d = 6",
        "barriers = T,\nshade_d = 100","barriers = T,\nshade_d = 12","barriers = T,\nshade_d = 9","barriers = T,\nshade_d = 6",
    ]
    )
    return ax, hm
end



#######
# "Rotated" (vertical)


function shade_heatmap_rot(df)
    fig = Figure(
        resolution = (500, 200), 
        fontsize = 16
        )
    # withshades = subset(df, :n_shades => ByRow(>(0)), :shade_val => ByRow(<(0.8)))
    withshades = subset(df, :n_shades => ByRow(>(0)))
    nshadeopts = sort!(unique(withshades.n_shades))
    withshades[!, :shlevel] = searchsortedfirst.(Ref(nshadeopts), withshades[!, :n_shades])
    bynum = groupby(withshades, :prunes_year)
    # prune0 = bynum[1]
    climits = extrema(withshades.meanshade)
    ax1, hm1 = single_hm_rot(fig[1,1], bynum[4], climits)
    ax2, hm2 = single_hm_rot(fig[2,1], bynum[3], climits)
    ax3, hm3 = single_hm_rot(fig[3,1], bynum[2], climits)
    ax4, hm4 = noprune_hm_rot(fig[4,1], bynum[1], climits)
    vlines!.([ax1, ax2, ax3, ax4], [3.5], linewidth = 3, color = :steelblue3)
    
    ax1.xlabel = "Number of Shade Trees"
    # ax1.xlabel = "Pruning Shade Level"
    # ax2.xlabel = "Pruning Shade Level"
    ax1.xaxisposition = :top
    # ax2.xaxisposition = :top
    hidexdecorations!(ax2)
    hidexdecorations!(ax3)
    # hidexdecorations!(ax4)
    # Colorbar(fig[1,5], hm1, label = "Yearly Mean Shading", ticks = 0.1:0.1:0.6, width = 14)
    rowsize!(fig.layout, 1, Aspect(1, 0.7))
    rowsize!(fig.layout, 2, Aspect(1, 0.7))
    rowsize!(fig.layout, 3, Aspect(1, 0.7))
    rowsize!(fig.layout, 4, Aspect(1, 0.14))
    # Label(fig[1,0], "Number of Shade Trees", tellheight = false, rotation = pi/2)
    Label(fig[1:4,0], "Pruning Intensity", rotation = pi/2, padding = (0,-12,0,0))
    Label(fig[0:1,2], "Pruning\nFrequency:", tellheight = false, valign = :top)
    Label(fig[1,2], "3 per Year")
    Label(fig[2,2], "2 per Year")
    Label(fig[3,2], "1 per Year")
    Label(fig[4,2], "Free Growth")
    resize_to_layout!(fig)
    # colsize!(fig.layout, 5, Aspect(1, 0.15))
    return fig
end

function single_hm_rot(ax, df, climits)
    ax, hm = heatmap(ax, df.shlevel, df.shade_val, df.meanshade, colorrange = climits, colormap = :speed)
    ax.yticks = collect(0.1:0.15:0.7)
    ax.xticks = (collect(1:7), string.([81,144,289,784,848,884,1040]))
    ax.xticklabelsize = 14
    ax.yticklabelsize = 14
    ax.xticksvisible = false
    ax.yticksvisible = false
    return ax, hm
end

function noprune_hm_rot(ax, df, climits)
    ax, hm = heatmap(ax, df.shlevel, df.shade_val, df.meanshade, colorrange = climits, colormap = :speed)
    ax.yticks = [0.8,]
    ax.xticks = (collect(1:7), [
        "No barriers, 12x12", "No barriers, 9x9    ", "No barriers, 6x6    ",
        "Barriers, 100x100","Barriers, 12x12    ","Barriers, 9x9        ","Barriers, 6x6        ",
    ]
    )
    ax.xticklabelsize = 12
    ax.xticksvisible = false
    ax.yticksvisible = false
    ax.xticklabelrotation = pi/2
    return ax, hm
end

######################
# Not heatmaps but will go in the same fig

function addegplots!(f, df, climits, relsize)
    # f = Figure(resolution = (860, 450), fontsize = 16)
    # fig = GridLayout(f[1,1], tellwidth = false, halign = :left, width = Relative(0.91))
    fig = GridLayout(f[2,1], tellwidth = false, alignmode = Mixed(right = -85))
    m1 = mean(df.mapshade1)
    m2 = mean(df.mapshade2)
    m3 = mean(df.mapshade3)
    c1 = :dodgerblue3
    c2 = :dodgerblue1
    c3 = :steelblue3
    # linec = Makie.wong_colors()[2]
    linec = :gray14
    # xt = [0, 74, 196, 227, 319, 365]
    xt = collect(0:73:365)
    ax1 = Axis(fig[1,1], ylabel = "Mean Farm Shading", xticks = xt,
        bottomspinecolor = c1, topspinecolor = c1, leftspinecolor = c1, rightspinecolor = c1, spinewidth = 3,
        limits = ((0,365), nothing)
    )
    l1 = lines!(ax1, df.dayn, df.mapshade1, color = linec)
    ax2 = Axis(fig[1,2], xlabel = "Day of Year", xticks = xt,
        bottomspinecolor = c2, topspinecolor = c2, leftspinecolor = c2, rightspinecolor = c2, spinewidth = 3,
        limits = ((0,365), nothing)
    )
    l2 = lines!(ax2, df.dayn, df.mapshade2, color = linec)
    ax3 = Axis(fig[1,3],  xticks = xt,
        bottomspinecolor = c3, topspinecolor = c3, leftspinecolor = c3, rightspinecolor = c3, spinewidth = 3,
        limits = ((0,365), nothing)
    )
    l2 = lines!(ax3, df.dayn, df.mapshade3, color = linec)

    # Box(fig[1, 3], color = (:red, 0.2), strokewidth = 0)

    hlines!(ax1, m1, linestyle = :dot, linewidth = 2, color = [m1], colormap = :speed, colorrange = climits)
    hlines!(ax2, m2, linestyle = :dot, linewidth = 2, color = [m2], colormap = :speed, colorrange = climits)
    hlines!(ax3, m3, linestyle = :dot, linewidth = 2, color = [m3], colormap = :speed, colorrange = climits)
    
    linkyaxes!(ax1,ax2,ax3)
    hideydecorations!.([ax2,ax3], grid = false)
    rowsize!(f.layout, 1, Relative(relsize))
    rowgap!(f.layout, 50)

    return f
end