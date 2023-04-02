using GLMakie, DataFrames


function myinterplot(df::DataFrame)
    fig = Figure(resolution = (1000, 800))
    ranges = [0.0;0.00005;0.0001; collect(0.001:0.001:0.01); collect(0.02:0.01:0.1); collect(0.2:0.1:1.0); collect(1.0:28.0)]

    scorenames = names(df[:, Not(1)])
    x_dropdown = Menu(fig, options = scorenames, default = scorenames[1])
    y_dropdown = Menu(fig, options = scorenames, default = scorenames[2])
    c_dropdown = Menu(fig, options = [scorenames; "p_row"], default = scorenames[3])

    fig[1, 1] = vgrid!(
        Label(fig, "y axis", width = nothing),
        y_dropdown,
        Label(fig, "x axis", width = nothing),
        x_dropdown,
        Label(fig, "color", width = nothing),
        c_dropdown;
        tellheight = false, width = 150, valign = :top)


    xcurr = Observable{String}(scorenames[1])
    ycurr = Observable{String}(scorenames[2])
    ccurr = Observable{String}(scorenames[3])

    xs = @lift(df[!, $xcurr])
    ys = @lift(df[!, $ycurr])
    cs = @lift(df[!, $ccurr])
    rangesx = lift(xs) do xs
        maxx = maximum(xs)
        push!(filter(<=(maxx), ranges), maxx, maxx * 1.1)
    end
    rangesy = lift(ys) do ys
        maxy = maximum(ys)
        push!(filter(<=(maxy), ranges), maxy, maxy * 1.1)
    end

    ax = Axis(fig[1, 2], xlabel = xcurr, ylabel = ycurr)
    sl_x = IntervalSlider(fig[2, 2], range = rangesx)
    sl_y = IntervalSlider(fig[1, 3], range = rangesy, horizontal = false)

    # maxc = maximum(cs[])
    # rangesc = push!(filter(r -> r <= maxc, ranges), maxc)
    # sl_c = Slider(fig[1, 5], range = rangesc, startvalue = maxc, horizontal = false)

    scat = scatter!(ax, xs, ys, markersize = 4px, color = cs)#, colorrange = (0,5), highclip = :transparent)
    cb = Colorbar(fig[1, 4], scat, label = ccurr)#, highclip = :transparent)

    on(x_dropdown.selection) do s
        xcurr[] = s
        autolimits!(ax)
    end
    notify(x_dropdown.selection)

    on(y_dropdown.selection) do s
        ycurr[] = s
        autolimits!(ax)
    end
    notify(y_dropdown.selection)

    on(c_dropdown.selection) do s
        ccurr[] = s
    end
    notify(c_dropdown.selection)

    xmax = lift(sl_x.interval) do xm
        xlims!(ax, xm)
    end
    ymax = lift(sl_y.interval) do ym
        ylims!(ax, ym)
    end
    # lift(sl_c.value) do cval
    #     newdf = filter(ccurr[] => <(cval), df)
    #     nxs = newdf[!, xcurr[]]
    #     nys = newdf[!, ycurr[]]
    #     ncs = newdf[!, ccurr[]]
    #     nscat = scatter!(ax, nxs, nys, markersize = 4px, color = ncs)
    # end

    fig
end


ifig = myinterplot(sdists)
DataInspector(ifig)
