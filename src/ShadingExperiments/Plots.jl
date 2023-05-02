function CV_plot(cvs::DataFrame)
    fig = Figure()
    ax = Axis(fig[1,1], xlabel = L"Number of runs",
        ylabel = L"Coefficient of Variance, $C_V = \frac{μ}{σ^2}$",
        xticks = collect(100:100:1000))
    lines!(ax, cvs.n, cvs.prod, label = L"Coffee Production CV")
    lines!(ax, cvs.n, cvs.area, label = L"Max Rust Area CV")
    axislegend()
    return fig
end

## Prod or area (pa) scatter plot
function pa_plot(df::DataFrame, ylab::String, temp::Float64, rain::Float64)
    fig = Figure(resolution=(900,450));
    axF = Axis(fig[1,1], title = "Barriers: Absent", xlabel = "Target Shade", ylabel = ylab)
    axT = Axis(fig[1,2], title = "Barriers: Present", xlabel = "Target Shade")
    linkaxes!(axF, axT)
    for c in names(df)[3:end]
        scatterlines!(fig[1,1],
            df[df.barriers .== false, :post_prune],
            df[df.barriers .== false, c],
            marker = col_marker(c),
            markersize = col_markersize(c),
            color = col_color(c),
            linestyle = col_line(c))
    end
    for c in names(df)[3:end]
        scatterlines!(fig[1,2],
            df[df.barriers .== true, :post_prune],
            df[df.barriers .== true, c],
            marker = col_marker(c),
            markersize = col_markersize(c),
            color = col_color(c),
            linestyle = col_line(c))
    end

    group_marker_size_line = [
        [LineElement(linestyle = lines),
        MarkerElement(marker = markers, markersize = 15)] for (markers, lines) in zip(
            [:xcross, :circle, :utriangle], [nothing, nothing, :dash]
        )
    ]
    group_color = [PolyElement(color = color) for color in [:red, :orange, :teal, :olivedrab]]

    Legend(fig[1,3],
        [group_marker_size_line, group_color],
        [["0", "2", "3"], ["Absent Grid", "12", "9", "6"]],
        ["Prunings per Year", "Shade Grid Distance"])

    hideydecorations!(axT, grid = false)

    # Label(fig[0,1], "Barriers: Absent", tellwidth = false)
    # Label(fig[1,2], "Barriers: Present", tellwidth = false)

    # colsize!(fig.layout, 1, 2/3)
    colgap!(fig.layout, 12)


    Label(fig[2,1:2], "Temperature: $temp; Rain probability: $rain")

    return fig
end

## Boxplot

function prod_c_boxplot(df::DataFrame)

    fig = Figure(resolution = (800, 400))
    ax = Axis(fig[1,1],
        xlabel = "Shade Grid Distance",
        ylabel = "Median Production per Coffee",
        xticks = (1:4, ["Grid Absent", "6", "9", "12"]))

    # wbarr = subset(df, :usedbarriers)
    # wobarr = subset(df, :usedbarriers => ByRow(!))

    # boxplot!(ax, wobarr.boxplot_pos, wobarr.prod_cof,
    #     dodge = fill(1, length(wobarr.prod_cof)), width = 0.5, label = "Absent") #, dodge_gap = 2.4, color = (:teal, 0.8)
    # boxplot!(ax, wbarr.boxplot_pos,wbarr.prod_cof,
    #     dodge = fill(2, length(wbarr.prod_cof)), width = 0.5, label = "Present")
    bx = boxplot!(ax, df.boxplot_pos, df.prod_cof,
        dodge = barr_to_dodge.(df.barriers), width = 0.5,
        label = barr_to_label.(df.barriers), color = barr_to_color.(df.barriers))

    Legend(fig[1,1],
        [MarkerElement(marker = :circle, markersize = 15, color = color) for color in [:teal, :orange]],
        ["Barriers: Absent", "Barriers: Present"],
        halign = :left, valign = :top,
        margin = (20, 10, 10, 10), tellwidth = false, tellheight = false,
        # labelsize = 15,
        framevisible = false)

    # axislegend(ax, "Barriers", position = :lt, unique = true)
    # ylims!(ax, 0.3,0.6)

    return fig
end

## Scatter plot helpers
function col_marker(st::String)
    if occursin("15,", st)
        return :utriangle
    elseif occursin("74,", st)
        return :circle
    else
        return :xcross
    end
end

function col_markersize(st::String)
    if occursin("15,", st)
        return 15
    elseif occursin("74,", st)
        return 12
    else
        return 18
    end
end

function col_line(st::String)
    if occursin("15,", st)
        return :dash
    elseif occursin("75,", st)
        return nothing
    else
        return nothing
    end
end

function col_color(st::String)
    if occursin("_100", st)
        return :red
    elseif occursin("_6", st)
        return :olivedrab
    elseif occursin("_9", st)
        return :teal
    else
        return :orange
    end
end

## Boxplot helpers

barr_to_dodge(barr::Bool) = ifelse(barr, 2, 1)

barr_to_label(barr::Bool) = ifelse(barr, "Present", "Absent")

barr_to_color(barr::Bool) = ifelse(barr, :orange, :teal)

## Not plotting fs, but used in the plotting workflow

function add_useful_cols!(df::DataFrame)
    transform!(df, [:barriers] => ByRow(x -> ifelse(x == "(0, 0)", false, true)) => :usedbarriers)
    transform!(df, [:shade_d, :usedbarriers] => ByRow((s,b) -> n_coffees(s,b)) => :n_coffees)
    transform!(df, [:totprod, :n_coffees] => ByRow((s,b) -> (s / b)) => :prod_cof)
    transform!(df, :shade_d =>
        ByRow(s -> (n_shades = n_inter_shades(s), boxplot_pos = boxplot_pos(s))) =>
        AsTable)
end

function wide_plot_dfs(df::DataFrame)

    "prune period was replaced by prune_sch (SVector of days)"
    gdf = groupby(df, [:post_prune, :barriers, :prune_sch, :shade_d])

    # b_areas = combine(gbasedf, [:maxA] => (x -> (maxA_mean = mean(x), sd = std(x))) => AsTable)
    df_areas = combine(gdf, [:maxA] => mean)
    "prune period was replaced by prune_sch (SVector of days)"
    transform!(df_areas, [:prune_sch, :shade_d] => ByRow((x,y) -> string("s_", x, "_", y)) => :shade_i)
    w_df_areas = unstack(df_areas, [:post_prune, :barriers], :shade_i, :maxA_mean)

    df_prod = combine(gdf, [:totprod] => median)
    transform!(df_prod, [:prune_sch, :shade_d] => ByRow((x,y) -> string("s_", x, "_", y)) => :shade_i)
    w_df_prod = unstack(df_prod, [:post_prune, :barriers], :shade_i, :totprod_median)

    df_prod_cof = combine(gdf, [:prod_cof] => median)
    transform!(df_prod_cof, [:prune_sch, :shade_d] => ByRow((x,y) -> string("s_", x, "_", y)) => :shade_i)
    w_df_prod_cof = unstack(df_prod_cof, [:post_prune, :barriers], :shade_i, :prod_cof_median)

    return w_df_areas, w_df_prod, w_df_prod_cof
end

n_inter_shades(shade_d::Int) = if shade_d == 100
    0
elseif shade_d == 12
    70
elseif shade_d == 9
    123
else
    278
end

boxplot_pos(shade_d::Int) = if shade_d == 100
    1
elseif shade_d == 12
    4
elseif shade_d == 9
    3
else
    2
end

# n_barr_shades(used::Bool) = ifelse(used, 196, 0)
