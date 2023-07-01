
function historyhm(df)
    fig = Figure(resolution = (860,800))
    ax1 = Axis(fig[1,1],
        # xticks = [1, 15, 30, 45, 60, 75],
        # ylabel = "Position in Chromosome",
        # xlabel = "Generations"
        xticks = [1, 20, 40, 60, 80],
        # xticks = [1, 15, 30, 45, 60, 75],
        xlabel = "Position in Chromosome",
        ylabel = "Generations",
        xaxisposition = :top,
        yreversed = true
    )
    # hm = heatmap!(ax1, df.gen, df.pos, df.minfreq, colormap = :viridis)
    hm = heatmap!(ax1, df.pos, df.gen, df.minfreq, colormap = :viridis)
    # Colorbar(fig[0,1], hm, tellwidth = false, 
    # vertical = false, height = 10, width = 500,
    Colorbar(fig[1,2], hm, tellwidth = false, tellheight = false, height = 400,
    label = "Position Variability", labelsize = 15, ticklabelsize = 12,
    labelpadding = 4)
    # loci = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:19, 20:25, 26:31, 32:37, 38:43, 44:48, 49:54, 55:60, 61:66, 67:72, 73:73, 74:79]
    # pars = ["row_d", "plant_d", "shade_d", "barriers", "barrier_rows", "prune_sch1", "prune_sch2", "prune_sch3", "post_prune1", "post_prune2", "post_prune3",
    # "inspect_period", "inspect_effort", "fungicide_sch1", "fungicide_sch2", "fungicide_sch3", "incidence_as_thr", "incidence_thr"]
    loci = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:14, 15:20, 21:21, 22:27, 28:28, 29:34, 35:40, 41:46, 47:51, 52:57, 58:63, 64:64, 65:70, 71:71, 72:77, 78:78, 79:80, 81:86]
    pars = ["row_d", "plant_d", "shade_d", "barriers", "barrier_rows", "prune_sch1", "ign_p1", "prune_sch2", "ign_p2", "prune_sch3","ign_p3",  "post_prune1", "post_prune2", "post_prune3",
    "inspect_period", "inspect_effort", "fungicide_sch1", "ign_f1", "fungicide_sch2", "ign_f2", "fungicide_sch3", "ign_f3", "fung_stratg", "incidence_thr"]
    ax2 = Axis(fig[2,1], yreversed = true)
    # scatter!(ax2,1:10, 0.1:0.1:1.0)
    brot = pi/2
    psize = 12.5
    for (rg, lab) in zip(loci, pars)
        # bracket!(ax2,0,8,0,13, text = "prune_sch1", orientation = :down)
        if length(rg) == 1
            bracket!(ax2,
            # 0, first(rg) - 0.01, 0, last(rg) + 0.01, text = lab,
            first(rg) - 0.01, 0, last(rg) + 0.01, 0, text = lab,
            # style = :square,
            orientation = :down,
            width = 10,
            rotation = brot, textoffset = 4, 
            fontsize = psize, align = (:right, :center))
        else
            bracket!(ax2,
            first(rg) - 0.4, 0, last(rg) + 0.4, 0, text = lab,
            # style = :square,
            orientation = :down,
            width = 10,
            rotation = brot, textoffset = 4, 
            fontsize = psize, align = (:right, :center))
        end
    end
    hidedecorations!(ax1, ticks = false, ticklabels = false, label = false)
    hidedecorations!(ax2)
    hidespines!(ax1)
    hidespines!(ax2)
    # hidet
    # colgap!(fig.layout, 0)
    # colsize!(fig.layout, 1, Relative(0.85))
    rowgap!(fig.layout, 0)
    colgap!(fig.layout, 5)
    rowsize!(fig.layout, 1, Relative(0.85))
    colsize!(fig.layout, 2, Relative(0.03))
    # rowsize!(fig.layout, 0, Relative(0.05))
    # ylims!(ax1, 87, 0)
    # ylims!(ax2, 87, 0)
    # xlims!(ax2, 0, 0.8)
    xlims!(ax1, 0, 87)
    xlims!(ax2, 0, 87)
    ylims!(ax2, 0.9, 0)
    return fig
end
# \pm is ±


function plotfit(df)
    dfsd = transform(df,
        [:meanfit, :sd] => ByRow((m,s) -> (lower = m - s, upper = m + s)) => AsTable
    )
    transform!(dfsd, [:meanfit, :maxfit, :lower, :upper] .=> ByRow(v -> v /1000) .=> [:meanfit, :maxfit, :lower, :upper])
    lw = 2
    mcolr = :deepskyblue4
    fig = Figure()
    ax1, b1 = band(fig[1,1], dfsd.gen, dfsd.lower, dfsd.upper, color = (mcolr, 0.4), label = "Mean ± sd")
    l1 = lines!(ax1, dfsd.gen, dfsd.meanfit, color = (mcolr, 1.0), linewidth = lw, label = "Mean ± sd")
    l2 = lines!(ax1, dfsd.gen, dfsd.maxfit, color = (:firebrick4, 1.0), linestyle = :dash, linewidth = lw, label = "Maximum")
    
    ax1.xlabel = "Generations"
    ax1.ylabel = "Fitness Score"
    ax1.xticks = collect(20:20:160)
    xlims!(low = 1, high = maximum(dfsd.gen))
    fig[0,1] = Legend(fig, ax1, merge = true, orientation = :horizontal)
    
    return fig
end

#########
# Save fns

function savehereGA(name, fig)
    save(joinpath("plots/GA",name), fig)
end
function savedissGA(name, fig)
    p = mkpath("../../Dissertation/Chapters/Diss/Document/Figs/GA")
    save(joinpath(p,name), fig, px_per_unit = 2)
end

function historyhm(df, genes)
    fig = Figure(resolution = (860,800))
    ax1 = Axis(fig[1,1],
        # xticks = [1, 15, 30, 45, 60, 75],
        # ylabel = "Position in Chromosome",
        # xlabel = "Generations"
        xticks = [1, 20, 40, 60, 80],
        # xticks = [1, 15, 30, 45, 60, 75],
        xlabel = "Position in Chromosome",
        ylabel = "Generations",
        xaxisposition = :top,
        yreversed = true
    )
    # hm = heatmap!(ax1, df.gen, df.pos, df.minfreq, colormap = :viridis)
    hm = heatmap!(ax1, df.pos, df.gen, df.minfreq, colormap = :viridis)
    # Colorbar(fig[0,1], hm, tellwidth = false, 
    # vertical = false, height = 10, width = 500,
    Colorbar(fig[1,2], hm, tellwidth = false, tellheight = false, height = 400,
    label = "Position Variability", labelsize = 15, ticklabelsize = 12,
    labelpadding = 4)
    # if genes 
        # loci = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:19, 20:25, 26:31, 32:37, 38:43, 44:48, 49:54, 55:60, 61:66, 67:72, 73:73, 74:79]
        # pars = ["row_d", "plant_d", "shade_d", "barriers", "barrier_rows", "prune_sch1", "prune_sch2", "prune_sch3", "post_prune1", "post_prune2", "post_prune3",
        # "inspect_period", "inspect_effort", "fungicide_sch1", "fungicide_sch2", "fungicide_sch3", "incidence_as_thr", "incidence_thr"]
        # loci = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:14, 15:20, 21:21, 22:27, 28:28, 29:34, 35:40, 41:46, 47:51, 52:57, 58:63, 64:64, 65:70, 71:71, 72:77, 78:78, 79:80, 81:86]
        # pars = ["row_d", "plant_d", "shade_d", "barriers", "barrier_rows", "prune_sch1", "ign_p1", "prune_sch2", "ign_p2", "prune_sch3","ign_p3",  "post_prune1", "post_prune2", "post_prune3",
        # "inspect_period", "inspect_effort", "fungicide_sch1", "ign_f1", "fungicide_sch2", "ign_f2", "fungicide_sch3", "ign_f3", "fung_stratg", "incidence_thr"]
        loci = [1:7, 8:14, 15:21, 22:27, 28:33, 34:39, 40:41, 42:45, 46:46, 47:53, 54:54, 55:56, 57:57, 58:64, 65:71, 72:78, 79:80, 81:87]
        pars = ["prune_sch1", "prune_sch2", "prune_sch3", "post_prune1", "post_prune2", "post_prune3", "rm_lesions", "inspect_period",
        "row_d", "inspect_effort", "plant_d", "shade_d", "barriers",
        "fungicide_sch1", "fungicide_sch2", "fungicide_sch3", "fung_stratg", "incidence_thr"]
        ax2 = Axis(fig[2,1], yreversed = true)
        # scatter!(ax2,1:10, 0.1:0.1:1.0)
        brot = pi/2
        psize = 12.5
        for (rg, lab) in zip(loci, pars)
            # bracket!(ax2,0,8,0,13, text = "prune_sch1", orientation = :down)
            if length(rg) == 1
                bracket!(ax2,
                # 0, first(rg) - 0.01, 0, last(rg) + 0.01, text = lab,
                first(rg) - 0.01, 0, last(rg) + 0.01, 0, text = lab,
                # style = :square,
                orientation = :down,
                width = 10,
                rotation = brot, textoffset = 4, 
                fontsize = psize, align = (:right, :center))
            else
                bracket!(ax2,
                first(rg) - 0.4, 0, last(rg) + 0.4, 0, text = lab,
                # style = :square,
                orientation = :down,
                width = 10,
                rotation = brot, textoffset = 4, 
                fontsize = psize, align = (:right, :center))
            end
        end
        hidedecorations!(ax2)
        hidespines!(ax2)
        # colgap!(fig.layout, 0)
        # colsize!(fig.layout, 1, Relative(0.85))
        # rowsize!(fig.layout, 0, Relative(0.05))
        # ylims!(ax1, 87, 0)
        # ylims!(ax2, 87, 0)
        # xlims!(ax2, 0, 0.8)
    # end
    hidedecorations!(ax1, ticks = false, ticklabels = false, label = false)
    hidespines!(ax1)
    rowgap!(fig.layout, 0)
    colgap!(fig.layout, 5)
    rowsize!(fig.layout, 1, Relative(0.85))
    colsize!(fig.layout, 2, Relative(0.03))
    xlims!(ax1, 0, 88)
    xlims!(ax2, 0, 88)
    # ylims!(ax2, 0.9, 0)
    # hidet
    return fig
end
# \pm is ±

function hmaxis!(fig, pos, df)
    ax1 = Axis(fig[pos...],
        xticks = [1, 20, 40, 60, 80],
        yticks = [1, 50, 100],
        # xlabel = "Position in Chromosome",
        # ylabel = "Generations",
        xaxisposition = :top,
        yreversed = true
    )
    hm = heatmap!(ax1, df.pos, df.gen, df.minfreq,
    colormap = Reverse(:roma),
    # colormap = :viridis,
    colorrange = (0, 0.5))
    hidedecorations!(ax1, ticks = false, ticklabels = false, label = false)
    hidespines!(ax1)
    xlims!(ax1, 0, 88.2)
    # ylims!(ax1, maximum(df.gen)+1.3, 0)
    return ax1, hm
end
"       "
function braxis!(fig, pos)
    loci = [1:7, 8:14, 15:21, 22:27, 28:33, 34:39, 40:41, 42:45, 46:46, 47:53, 
    54:54, 55:56, 57:57, 58:64, 65:71, 72:78, 79:80, 81:87]
    pars = ["prune_sch1", "prune_sch2", "prune_sch3", "post_prune1", "post_prune2", "post_prune3", 
    "rm_lesions", "inspect_period", "row_d", "inspect_effort", "plant_d", "shade_d", "barriers",
    "fungicide_sch1", "fungicide_sch2", "fungicide_sch3", "fung_stratg", "incidence_thr"]
    ax2 = Axis(fig[pos...], yreversed = true)
    brot = pi/2
    psize = 11.0
    for (rg, lab) in zip(loci, pars)
        # bracket!(ax2,0,8,0,13, text = "prune_sch1", orientation = :down)
        if length(rg) == 1
            bracket!(ax2,
            # 0, first(rg) - 0.01, 0, last(rg) + 0.01, text = lab,
            first(rg) - 0.01, 0, last(rg) + 0.01, 0, text = lab,
            # style = :square,
            orientation = :down,
            width = 10, linewidth = 1,
            rotation = brot, textoffset = 4, 
            fontsize = psize, align = (:right, ifelse(lab == "plant_d", :bottom, ifelse(lab == "barriers", :top, :center))))
        else
            bracket!(ax2,
            first(rg) - 0.4, 0, last(rg) + 0.4, 0, text = lab,
            # style = :square,
            orientation = :down,
            width = 10, linewidth = 1,
            rotation = brot, textoffset = 4, 
            fontsize = psize, align = (:right, :center))
        end
    end
    hidedecorations!(ax2)
    hidespines!(ax2)
    return ax2
end

function barebraxis!(fig, pos)
    loci = [1:7, 8:14, 15:21, 22:27, 28:33, 34:39, 40:41, 42:45, 46:46, 47:53, 
    54:54, 55:56, 57:57, 58:64, 65:71, 72:78, 79:80, 81:87]
    ax2 = Axis(fig[pos...], yreversed = true)
    wd = 8
    for rg in loci
        # bracket!(ax2,0,8,0,13, text = "prune_sch1", orientation = :down)
        if length(rg) == 1
            bracket!(ax2,
            first(rg) - 0.01, 0, last(rg) + 0.01, 0, 
            # style = :square,
            orientation = :down,
            width = wd, linewidth = 1,
            # rotation = brot, textoffset = 4, 
            # fontsize = psize, align = (:right, :center)
            )
        else
            bracket!(ax2,
            first(rg) - 0.4, 0, last(rg) + 0.4, 0,
            orientation = :down,
            width = wd, linewidth = 1,
            # rotation = brot, textoffset = 4,
            # fontsize = psize, align = (:right, :center)
            )
        end
    end
    hidedecorations!(ax2)
    hidespines!(ax2)
    return ax2
end



function readaddinfo(f)
    df = CSV.read(f, DataFrame, header = false)
    i = parse(Int, f[end-6:end-4])
    transform!(df, eachindex => :pos)
    df.gen .= i
    return df
end

function minfreq(v)
    ts = mean(v)
    return min(ts, 1.0 - ts)
end

function bfreqs(folder, exp)
    popfiles = readdir(joinpath(folder, exp, "pops"), join = true)
    popsraw = [readaddinfo(f) for f in popfiles]
    pops = reduce(vcat, popsraw)

    return select(pops, :gen, :pos,
        AsTable(r"Column") => ByRow(minfreq) => :minfreq
    )
end

function modpos(pos)
    return pos .* (2, 1)
end

function hmfigure(folder, exps, poss)
    fig = Figure(resolution= (890,950))
    nax = length(exps)
    hms = [hmaxis!(fig, modpos(pos), bfreqs(folder, exp)) for (exp, pos) in zip(exps, poss)]
    hidexdecorations!.([hms[n][1] for n in 3:nax])
    hideydecorations!.([hms[n][1] for n in 2:nax if iseven(n)])
    # colgap!(fig.layout, 1, 5)
    # rowgap!(fig.layout, 1, 10)
    braxs = [barebraxis!(fig, (r, c)) for r in 3:2:nax, c in 1:2]
    
    Label(fig[0, 1], "Profit", tellwidth = false, height = 5, font = :bold)
    Label(fig[0, 2], "Profit + Severity Bonus", tellwidth = false, height = 5, font = :bold)
    Label(fig[1, 1:end], "Position in Chromosome", height = 10, padding = (0,0,0,0))
    Label(fig[1:end, 0], "Generation", rotation = pi/2, width = 15, padding = (-10,0,0,0))
    Label(fig[2, 3], "Short Term,\nNo Premiums", rotation = 3pi/2, tellheight = false, font = :bold)
    Label(fig[4, 3], "Short Term,\nPremiums", rotation = 3pi/2, tellheight = false, font = :bold)
    Label(fig[6, 3], "Medium Term,\nNo Premiums", rotation = 3pi/2, tellheight = false, font = :bold)
    Label(fig[8, 3], "Medium Term,\nPremiums", rotation = 3pi/2, tellheight = false, font = :bold)

    cb = Colorbar(fig[-1, 1:2], limits = (0, 0.5),
    colormap = Reverse(:roma),
    # colormap = :viridis,
    tellwidth = false, tellheight = false, width = 400, height = 10,
    label = "Position Variability", labelsize = 15, ticklabelsize = 12,
    vertical = false,
    labelpadding = 2)
    rowsize!(fig.layout,-1,2)

    rowgap!(fig.layout, 1, 38)
    rowgap!(fig.layout, 2, 10)
    rowgap!(fig.layout, 3, 4)
    colgap!(fig.layout, 1, 0)
    
    namepos = nax + 1
    br1 = braxis!(fig, (namepos,1))
    br2 = braxis!(fig, (namepos,2))


    [rowsize!(fig.layout, r, 10) for r in 3:2:nax]
    [rowgap!(fig.layout, r, 0) for r in 4:2:nax+1]
    [rowgap!(fig.layout, r, 10) for r in 5:2:nax+2]
    xlims!.(braxs, 0, 88.2)
    ylims!.(braxs, 0.9, 0)

    rowsize!(fig.layout, namepos, Relative(0.14))
    xlims!.([br1, br2], 0, 88.2)
    ylims!.([br1, br2], 0.9, 0)
    rowgap!(fig.layout, namepos+1, -3)

    

    return fig
end



function readnstats(folder, exp, gen)
    fitdf = CSV.read(joinpath(folder, exp, "fitnesshistory-$gen.csv"), DataFrame, header = false)

    df = select(fitdf,
        AsTable(:) => ByRow(mean) => :meanfit,
        AsTable(:) => ByRow(maximum) => :maxfit,
        AsTable(:) => ByRow(std) => :sd,
        eachindex => :gen
    )
    dfsd = transform(df,
        [:meanfit, :sd] => ByRow((m,s) -> (lower = m - s, upper = m + s)) => AsTable
    )
    transform!(dfsd, [:meanfit, :maxfit, :lower, :upper] .=> ByRow(v -> v /1000) .=> [:meanfit, :maxfit, :lower, :upper])
    
    return dfsd
end

function fitaxis!(fig, pos, dfsd)
    lw = 2
    mcolr = :deepskyblue4
    ax1, b1 = band(fig[pos...], dfsd.gen, dfsd.lower, dfsd.upper, color = (mcolr, 0.4), label = "Mean ± sd")
    l1 = lines!(ax1, dfsd.gen, dfsd.meanfit, color = (mcolr, 1.0), linewidth = lw, label = "Mean ± sd")
    l2 = lines!(ax1, dfsd.gen, dfsd.maxfit, color = (:firebrick4, 1.0), linestyle = :dash, linewidth = lw, label = "Maximum")
    ax1.xticks = collect(20:20:160)
    ax1.yticks = collect(0:20:100)
    xlims!(low = 1, high = maximum(dfsd.gen))

    return ax1
end

function fitfigure(folder, exps, poss, gen)
    fig = Figure(resolution = (860, 900))
    fitdfs = [readnstats(folder, exp, gen) for exp in exps]
    fitaxs = [fitaxis!(fig, pos, df) for (df, pos) in zip(fitdfs, poss)]

    fig[-1,1:end] = Legend(fig, fitaxs[2], merge = true, orientation = :horizontal)
    
    for ax in 1:2:length(fitaxs)
        linkyaxes!(fitaxs[ax], fitaxs[ax + 1])
    end
    # linkyaxes!(fitaxs...)
    # linkyaxes!.([p for p in Iterators.partition(fitaxs, 2)])

    Label(fig[1:end, 0], "Fitness Score", rotation = pi/2)
    Label(fig[5, 1:end], "Generation")
    Label(fig[0, 1], "Profit", tellwidth = false, height = 5, font = :bold)
    Label(fig[0, 2], "Profit + Severity Bonus", tellwidth = false, height = 5, font = :bold)
    Label(fig[1, 3], "Short Term,\nNo Premiums", rotation = 3pi/2, tellheight = false, font = :bold)
    Label(fig[2, 3], "Short Term,\nPremiums", rotation = 3pi/2, tellheight = false, font = :bold)
    Label(fig[3, 3], "Medium Term,\nNo Premiums", rotation = 3pi/2, tellheight = false, font = :bold)
    Label(fig[4, 3], "Medium Term,\nPremiums", rotation = 3pi/2, tellheight = false, font = :bold)

    rowgap!(fig.layout, 2, 5)
    rowgap!(fig.layout, 6, 10)
    colgap!(fig.layout, 1, 10)
    colgap!(fig.layout, 3, 10)

    return fig
end

function plotfit(obj, gen)
    fitness = CSV.read("results/GA/4/2/$obj/fitnesshistory-$gen.csv", DataFrame, header = false);
    # if occursin("sev", obj)
    #     fitness = .- log10.(abs.(fitness))
    #     ylab = "-Log(Fitness Score)"
    # end

    df = select(fitness,
        AsTable(:) => ByRow(mean) => :meanfit,
        AsTable(:) => ByRow(maximum) => :maxfit,
        AsTable(:) => ByRow(std) => :sd,
        eachindex => :gen
    )

    dfsd = transform(df,
        [:meanfit, :sd] => ByRow((m,s) -> (lower = m - s, upper = m + s)) => AsTable
    )

    # if occursin("profit", obj)
        transform!(dfsd, [:meanfit, :maxfit, :lower, :upper] .=> ByRow(v -> v /1000) .=> [:meanfit, :maxfit, :lower, :upper])
        ylab = "Fitness Score"
    # end

    lw = 2
    mcolr = :deepskyblue4
    fig = Figure()
    ax1, b1 = band(fig[1,1], dfsd.gen, dfsd.lower, dfsd.upper, color = (mcolr, 0.4), label = "Mean ± sd")
    l1 = lines!(ax1, dfsd.gen, dfsd.meanfit, color = (mcolr, 1.0), linewidth = lw, label = "Mean ± sd")
    l2 = lines!(ax1, dfsd.gen, dfsd.maxfit, color = (:firebrick4, 1.0), linestyle = :dash, linewidth = lw, label = "Maximum")
    
    ax1.xlabel = "Generations"
    ax1.ylabel = ylab
    ax1.xticks = collect(20:20:160)
    xlims!(low = 1, high = maximum(dfsd.gen))
    fig[0,1] = Legend(fig, ax1, merge = true, orientation = :horizontal)
    
    return fig
end

#########
# Save fns

function savehereGA(name, fig)
    save(joinpath("plots/GA",name), fig)
end
function savedissGA(name, fig)
    p = mkpath("../../Dissertation/Chapters/Diss/Document/Figs/GA")
    save(joinpath(p,name), fig, px_per_unit = 2)
end
#
#########

# Central dogma of GA

DoY(x::Int) = round(Int, 365 * x / 126)
#sch(days::Vector{Int}) = collect(ifelse(s == 1, DoY(f), -1) for (f,s) in Iterators.partition(days, 2))
sch(days::Vector{Int}) = collect(ifelse(d == 1 || d == 128, -1, DoY(d - 1)) for d in days)
propto08(x::Int) = round(x * 0.75 / 64.0, digits = 4)
perioddays(x::Int) = x * 2
proportion(x::Int) = x * inv(256) # (*inv(64) * 0.5)
fung_str(x::Int) = ifelse(x < 3, ifelse(x == 1, :cal, :cal_incd), ifelse(x == 3, :incd, :flor))

function ints_to_pars(transcr::Matrix{Int}, steps, cprice)
    return (
        prune_sch = sch(transcr[1:3]),
        post_prune = propto08.(transcr[4:6]),
        rm_lesions = transcr[7],
        inspect_period = perioddays(transcr[8]),
        row_d = transcr[9],
        inspect_effort = proportion(transcr[10]),
        plant_d = transcr[11],
        shade_d = ifelse(transcr[12] < 2, 100, transcr[12] * 3),
        barriers = ifelse(Bool(transcr[13] - 1), (1,1), (0,0)),
        fungicide_sch = sch(transcr[14:16]),
        fung_stratg = fung_str(transcr[17]),
        incidence_thresh = proportion(transcr[18]),
        steps = steps,
        coffee_price = cprice
    )
end

############### Older ################

function plot_fitn_history(fhist::Matrix{Float64})
    max = maximum(fhist, dims = 1)
    µ = mean(fhist, dims = 1)
    σ = std(fhist, dims = 1)
    max_mean_fitness(max, µ, σ)
end

function plot_fitn_history(fhist::DataFrame)
    summhist = combine(
        fhist, All() .=> [maximum, mean, std] => [:max, :µ, :std]
    )
    max = summhist[:, :max]
    µ = summhist[:, :µ]
    σ = summhist[:, :std]
    max_mean_fitness(max, µ, σ)
end

function max_mean_fitness(max::Vector{Float64}, µ::Vector{Float64}, σ::Vector{Float64})
    
end
#
#########

# Central dogma of GA

bits_to_int(bits) = 1 + sum(bit * 2 ^ (pos - 1) for (pos,bit) in enumerate(bits))

DoY(x::Int) = round(Int, 365 * x / 126)
#sch(days::Vector{Int}) = collect(ifelse(s == 1, DoY(f), -1) for (f,s) in Iterators.partition(days, 2))
sch(days::Vector{Int}) = collect(ifelse(d == 1 || d == 128, -1, DoY(d - 1)) for d in days)
propto08(x::Int) = round(x * 0.75 / 64.0, digits = 4)
perioddays(x::Int) = x * 2
proportion(x::Int) = x * inv(256) # (*inv(64) * 0.5)
fung_str(x::Int) = ifelse(x < 3, ifelse(x == 1, :cal, :cal_incd), ifelse(x == 3, :incd, :flor))

function ints_to_pars(transcr::Vector{Int}, steps, cprice)
    return (
        prune_sch = sch(transcr[1:3]),
        post_prune = propto08.(transcr[4:6]),
        rm_lesions = transcr[7],
        inspect_period = perioddays(transcr[8]),
        row_d = transcr[9],
        inspect_effort = proportion(transcr[10]),
        plant_d = transcr[11],
        shade_d = ifelse(transcr[12] < 2, 100, transcr[12] * 3),
        barriers = ifelse(Bool(transcr[13] - 1), (1,1), (0,0)),
        fungicide_sch = sch(transcr[14:16]),
        fung_stratg = fung_str(transcr[17]),
        incidence_thresh = proportion(transcr[18]),
        steps = steps,
        coffee_price = cprice
    )
end

############### Older ################

function plot_fitn_history(fhist::Matrix{Float64})
    max = maximum(fhist, dims = 1)
    µ = mean(fhist, dims = 1)
    σ = std(fhist, dims = 1)
    max_mean_fitness(max, µ, σ)
end

function plot_fitn_history(fhist::DataFrame)
    summhist = combine(
        fhist, All() .=> [maximum, mean, std] => [:max, :µ, :std]
    )
    max = summhist[:, :max]
    µ = summhist[:, :µ]
    σ = summhist[:, :std]
    max_mean_fitness(max, µ, σ)
end

function max_mean_fitness(max::Vector{Float64}, µ::Vector{Float64}, σ::Vector{Float64})
    
end