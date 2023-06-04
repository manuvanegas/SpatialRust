
function historyhm(df)
    fig = Figure(resolution = (800,800))
    ax1 = Axis(fig[1,1],
        yticks = [1, 15, 30, 45, 60, 75],
        ylabel = "Position in Chromosome",
        xlabel = "Generations"
    )
    hm = heatmap!(ax1, df.gen, df.pos, df.minfreq, colormap = :viridis)
    Colorbar(fig[0,1], hm, tellwidth = false, 
    vertical = false, height = 10, width = 500,
    label = "Position Variability", labelsize = 14, ticklabelsize = 12)
    loci = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:19, 20:25, 26:31, 32:37, 38:43, 44:48, 49:54, 55:60, 61:66, 67:72, 73:73, 74:79]
    pars = ["row_d", "plant_d", "shade_d", "barriers", "barrier_rows", "prune_sch1", "prune_sch2", "prune_sch3", "post_prune1", "post_prune2", "post_prune3",
    "inspect_period", "inspect_effort", "fungicide_sch1", "fungicide_sch2", "fungicide_sch3", "incidence_as_thr", "incidence_thr"]
    ax2 = Axis(fig[1,2])
    for (rg, lab) in zip(loci, pars)
        # bracket!(ax2,0,8,0,13, text = "prune_sch1", orientation = :down)
        if length(rg) == 1
            bracket!(ax2,
            0, first(rg) - 0.01, 0, last(rg) + 0.01, text = lab,
            # style = :square,
            # orientation = :down,
            width = 10,
            rotation = 0, textoffset = 4, fontsize = 12, align = (:left, :center))
        else
            bracket!(ax2,
            0, first(rg) - 0.4, 0, last(rg) + 0.4, text = lab,
            # style = :square,
            # orientation = :down,
            width = 10,
            rotation = 0, textoffset = 4, fontsize = 12, align = (:left, :center))
        end
    end
    # hidedecorations!(ax1, ticks = false, ticklabels = false)
    hidedecorations!(ax2)
    hidespines!(ax1)
    hidespines!(ax2)
    # hidet
    colgap!(fig.layout, 0)
    colsize!(fig.layout, 1, Relative(0.85))
    # rowsize!(fig.layout, 0, Relative(0.05))
    ylims!(ax1, 80, 0)
    ylims!(ax2, 80, 0)
    xlims!(ax2, 0, 0.8)
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
    xlims!(low = 1)
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

bits_to_int(bits) = 1 + sum(bit * 2 ^ (pos - 1) for (pos,bit) in enumerate(bits))

DoY(x::Int) = round(Int, 365 * x * inv(64))
sch(days::Vector{Int}) = collect(ifelse(s == 1, DoY(f), -1) for (f,s) in Iterators.partition(days, 2))
propto08(x::Int) = x * 0.75 * inv(64)
perioddays(x::Int) = x * 2
proportion(x::Int) = x * inv(128) # (*inv(64) * 0.5)
fung_str(x::Int) = ifelse(x < 3, ifelse(x == 1, :cal, :cal_incd), ifelse(x == 3, :incd, :flor))

function ints_to_pars(transcr::Matrix{Int}, steps, cprice)
    return (
        row_d = transcr[1],
        plant_d = transcr[2],
        shade_d = ifelse(transcr[3] < 2, 100, transcr[3] * 3),
        barriers = ifelse(Bool(transcr[4] - 1), (1,1), (0,0)),
        barrier_rows = transcr[5],
        prune_sch = sch(transcr[6:11]),
        post_prune = propto08.(transcr[12:14]),
        inspect_period = perioddays(transcr[15]),
        inspect_effort = proportion(transcr[16]),
        fungicide_sch = sch(transcr[17:22]),
        fung_stratg = fung_str(transcr[23]),
        incidence_thresh = proportion(transcr[24]),
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