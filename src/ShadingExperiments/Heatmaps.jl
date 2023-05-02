# Meanshade heatmaps

function shade_heatmap(df)
    fig = Figure(resolution = (860, 450), fontsize = 16)
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
    Label(fig[2,1:4], "Individual Shade Post Pruning", padding = (0,0,0,-15))
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
