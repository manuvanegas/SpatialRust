using CairoMakie, CSV, DataFrames, DelimitedFiles, Statistics
using Distributions, Random
using SpatialRust


# vars = vec([Symbol(t,n) for n in 4:7, t in [:p, :s, :f]])

function globscengroup(s)
    findfirst(==(s), [:p_np_s, :p_p_s, :p_np_m, :p_p_m, :s_np_s, :s_p_s, :s_np_m, :s_p_m])
end

function addjitter(dfo, var, bands, seed)
    rng = Xoshiro(seed)
    df = deepcopy(dfo)
    gdf = groupby(df, :scenario)
    # transform!(gdf, groupindices => :g)
    transform!(df, :scenario => ByRow(scengroup) => :g)
    for g in gdf
        gmin, gmax = extrema(g[:, var])
        lims = [gmin + ((gmax - gmin)/ bands) * i for i in 1:bands]
        lg = transform(g, var => ByRow(v -> searchsortedfirst(lims, v)) => :band)
        transform!(groupby(lg, :band), proprow => :crowd)
        g[!, :crowd] .= copy(lg.crowd)
    end
    # transform!(df, [:g, :crowd] => ByRow((g,c) -> g + rand(rng) * 1.5 * c - 0.75 * c) => :xpos)
    transform!(df, [:g, :crowd] => ByRow((g,c) -> g + rand(rng) * 2 * c - c) => :xpos)
    # transform!(df, [:g, :crowd] => ByRow((g,c) -> g + rand(Normal(0, c))) => :xpos)
    return df
end

p4df = addjitter(df, :p4, 20)

scatter(p4df.xpos, p4df.p4)


function scengroup(s)
    # findfirst(==(s), [:p_np_s, :p_p_s, :p_np_m, :p_p_m, :s_np_s, :s_p_s, :s_np_m, :s_p_m])
    findfirst(p -> s in p, [[:p_np_s, :s_np_s], [:p_p_s, :s_p_s], [:p_np_m, :s_np_m], [:p_p_m, :s_p_m]])
    # findfirst(p -> s in p, [[:p_np_s, :s_np_s, :p_p_s, :s_p_s], [:inthemiddle], [:p_np_m, :s_np_m, :p_p_m, :s_p_m]]) + 0.5
end

getcolor(g, colors, alpha) = (colors[iseven(g) + 1], alpha)
getlabel(g) = iseven(g) ? "Premiums" : "No Premiums"
# getxpos(g) = g < 3 ? 1.5 : 3.5

function p_s(df)
    dfp = subset(df, :scenario => ByRow(s -> s in [:p_np_s, :p_p_s, :p_np_m, :p_p_m]))
    dfs = subset(df, :scenario => ByRow(s -> s in [:s_np_s, :s_p_s, :s_np_m, :s_p_m]))
    return dfp, dfs
end

function boxplotfig(dfi, var, withscatt, bands = 10)

    df = transform(dfi, :scenario => ByRow(scengroup) => :group)

    fig = Figure(resolution = (800,500))
    colors = [categorical_colors(:oleron10,10)[[1,6]]]
    alpha = 0.6
    df.color .= getcolor.(df.group, colors, alpha)
    df.label .= getlabel.(df.group)
    if var in [:p4, :p5, :p6, :p7]
        ylab = "Final Farm Profit (Arbitrary Units)"
        scalph = 0.4
    else
        ylab = rich("Mean Observed Rust Severity (cm",superscript("2"),")")
        scalph = 0.2
    end

    dfp, dfs = p_s(df)

    tsize = 12
    ax1 = Axis(fig[1,1], 
        ylabel = ylab,
        xgridvisible = false,
        # xticks = (collect(1:4), [
        #     "Short Term, No Premiums", "Short Term, Premiums", "Medium Term, No Premiums", "Medium Term, Premiums",
        # ]),
        xticks = ([1.5, 3.5], [
            "Short Term", "Medium Term",
        ]),
        xticklabelrotation = pi/4,
        # xticklabelsize = tsize
    )
    ax2 = Axis(fig[1,2], 
        xgridvisible = false,
        # xticks = (collect(1:4), [
        #     "Short Term, No Premiums", "Short Term, Premiums", "Medium Term, No Premiums", "Medium Term, Premiums",
        # ]),
        xticks = ([1.5, 3.5], [
            "Short Term", "Medium Term",
        ]),
        xticklabelrotation = pi/4,
        # xticklabelsize = tsize
    )
    

    if withscatt
        boxplot!(ax1, dfp.group, dfp[:, var], color = dfp.color, show_outliers = false)
        boxplot!(ax2, dfs.group, dfs[:, var], color = dfs.color, show_outliers = false)
        jdf = addjitter(df, var, bands, 22)
        jdfp, jdfs = p_s(jdf)
        scatter!(ax1, jdfp.xpos, jdfp[:, var], color = (:gray20, scalph), markersize = 8)
        scatter!(ax2, jdfs.xpos, jdfs[:, var], color = (:gray20, scalph), markersize = 8)
    else
        boxplot!(ax1, dfp.group, dfp[:, var], color = dfp.color)
        boxplot!(ax2, dfs.group, dfs[:, var], color = dfs.color)
    end

    linkyaxes!(ax1, ax2)
    hideydecorations!(ax2, grid = false)
    colgap!(fig.layout, 1, 10)

    Label(fig[0, 1], "Profit", tellwidth = false, font = :bold)
    Label(fig[0, 2], "Profit + Severity Bonus", tellwidth = false, font = :bold)
    rowgap!(fig.layout, 1, 20)

    group_prems = [[
        PolyElement(color = (color, alpha)),
        LineElement(color = :black, linestyle = nothing)] for color in colors[1]]
    # group_prems = [MarkerElement(marker = :rect, color = (color, alpha), size = 20) for color in colors[1]]
    
    fig[-1, 1:end] = Legend(fig,
        group_prems,
        ["No Premiums", "Premiums"],
        orientation = :horizontal, 
    )
    rowsize!(fig.layout, -1, Relative(0.05))

    # axislegend(ax1)

    return fig
end


dfs = [CSV.read(f, DataFrame) for f in readdir("results/GA/4/2/fittest/100", join = true) if occursin("p_", f)];
df = reduce(vcat, dfs);
df.scenario .= Symbol.(df.scenario);
transform!(df, [:p4, :p5, :p6, :p7] .=> (p -> p / 1000) .=> [:p4, :p5, :p6, :p7]);
# CSV.write("results/GA/4/2/fittest/100/all.csv", df)

p4 = boxplotfig(df, :p4, true, 10)
s4 = boxplotfig(df, :s4, true, 10)

boxplotfig(df, :s6, true, 10)

savedissGA("profit4.png", p4)
savedissGA("severity4.png", s4)


# ["Profit, Short Term, No Premiums", "Profit, Short Term, Premiums", "Profit, Medium Term, No Premiums", "Profit, Medium Term, Premiums",
# "Profit + Severity, Short Term, No Premiums", "Profit + Severity, Short Term, Premiums", "Profit + Severity, Medium Term, No Premiums", "Profit + Severity, Medium Term, Premiums",]
# [
# "Short Term, No Premiums", "Short Term, Premiums", "Medium Term, No Premiums", "Medium Term, Premiums",
# ]