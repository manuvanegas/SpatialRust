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

function pa_plot(df::DataFrame, ylab::String)
    fig = Figure(resolution=(900,450));
    axF = Axis(fig[1,1], xlabel = "Target Shade", ylabel = ylab)
    axT = Axis(fig[1,2], xlabel = "Target Shade")
    linkyaxes!(axF, axT)
    for c in names(df)[3:end]
        scatterlines!(fig[1,1],
            df[df.usedbarriers .== false, :target_shade],
            df[df.usedbarriers .== false, c],
            marker = col_marker(c),
            color = col_color(c),
            markersize = col_markersize(c))
    end
    for c in names(df)[3:end]
        scatterlines!(fig[1,2],
            df[df.usedbarriers .== true, :target_shade],
            df[df.usedbarriers .== true, c],
            marker = col_marker(c),
            color = col_color(c),
            markersize = col_markersize(c))
    end
    #=
    lines!(xs, ys .- i/6, linestyle = nothing, linewidth = lw)
    lines!(xs, ys .- i/6 .- 1, linestyle = :dash, linewidth = lw)
    lines!(xs, ys .- i/6 .- 2, linestyle = :dot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 3, linestyle = :dashdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 4, linestyle = :dashdotdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 5, linestyle = [0.5, 1.0, 1.5, 2.5], linewidth = lw)
    =#

# https://makie.juliaplots.org/stable/examples/blocks/legend/

    # group_size = [MarkerElement(marker = :circle, color = :black,
    # strokecolor = :transparent,
    # markersize = ms) for ms in markersizes]
    #
    # group_color = [PolyElement(color = color, strokecolor = :transparent)
    #     for color in colors]
    #
    # legends = [Legend(f,
    #     [group_size, group_color],
    #     [string.(markersizes), string.(colors)],
    #     ["Size", "Color"]) for _ in 1:6]
    #
    # Legend(f[1, 2], [lin, sca, lin], ["a line", "some dots", "line again"])

    return fig
end


function col_marker(st::String)
    if occursin("_1461_", st)
        return :xcross
    elseif occursin("_365_", st)
        return :circle
    else
        return :utriangle
    end
end

function col_markersize(st::String)
    if occursin("_1461_", st)
        return 18
    elseif occursin("_365_", st)
        return 12
    else
        return 15
    end
end

function col_color(st::String)
    if occursin("_0", st)
        return :blue
    elseif occursin("_6", st)
        return :green
    else
        return :orange
    end
end
