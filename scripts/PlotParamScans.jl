using DrWatson

@quickactivate "SpatialRust"

using CSV, ColorSchemes, DataFrames, DrWatson, StatsPlots, Statistics, Query

files = filter(x -> endswith(x, ".csv"), readdir(projectdir("results")))
dfs = DataFrame.(CSV.File.(projectdir.("results",files)))
df = reduce(vcat, dfs)
df2 = DataFrame.(CSV.File.(projectdir.("results","md-frag.csv")))

df.adj_yield_loss = 1 .- (df.yield ./ (5 .* (1 .- df.shade_percent)))
df2.adj_yield_loss = 1 .- (df2.yield ./ (5 .* (1 .- df2.shade_percent)))


expl_vars = [:step, :shade_percent, :target_shade, :inspect_period, :fragmentation]
out_vars = [:rust_incid, :mean_sev_tot, :yield]

nofrag = filter(row -> row[:fragmentation] == false, df)
df = vcat(nofrag, df2)


grouped = groupby(df, expl_vars)

means = combine(grouped, valuecols(grouped) .=> mean)
stds = combine(grouped, valuecols(grouped) .=> std)

joined = innerjoin(means,stds, on = expl_vars)

## Now, plot!

plt = vcat(colorschemes[:RdYlBu_6][1:3],colorschemes[:RdYlBu_6][5:6])

# @df joined plot(
#     :step,
#     :rust_incid_mean,
#     group = (:fragmentation),
#     linestyle = [:solid :dash],
#     ribbon = :rust_incid_std,
#     legend = false
# )

# Plot Incidences over time
incidences = joined |>
    # @filter(_.shade_percent == 0.1) |>
    @filter(_.inspect_period == 30) |>
    @filter(_.fragmentation == true) |>
    @filter(_.target_shade == 0.3) |>
    @df plot(
        :step,
        :rust_incid_mean,
        group = :shade_percent,
        # markershape = :circle,
        # markersize = 4,
        # markerstrokewidth = 0.1,
        ribbon = :rust_incid_std,
        fillalpha = 0.5,
        linewidth = 1.6,
        palette = plt,
        legend = (0.15, 0.8),
        legendtitle = "Proportion of\nShade Trees",
        legendtitlefontvalign = :bottom,
        legendtitlefonthalign = :right,
        legendtitlefontsize = 8,
        legendfontsize = 7,
        fg_legend = :transparent,
        bg_legend = :transparent,
        primary = true,
        xlabel = "Days",
        ylabel = "Rust Incidence",
        labelfontsize = 10,
        ylims = (0, 1.05),
        xticks = (collect(0:100:900)),
        size = (450,350)
    )

incidences = joined |>
    # @filter(_.shade_percent == 0.1) |>
    @filter(_.inspect_period == 30) |>
    @filter(_.fragmentation == false) |>
    @filter(_.target_shade == 0.3) |>
    @df plot!(
        :step,
        :rust_incid_mean,
        linestyle = [:dash],
        group = :shade_percent,
        ribbon = :rust_incid_std,
        fillalpha = 0.3,
        linewidth = 1.6,
        palette = plt,
        label = ""
    )

png(incidences, plotsdir("Incidences"))

# Plot final yield

yields = joined |>
    @filter(_.step == 910) |>
    # @filter(_.inspect_period == 30) |>
    @filter(_.target_shade == 0.3) |>
    # @map({_.shade_percent,
    #     _.fragmentation,
    #     _.target_shade,
    #     _.yield_std,
    #     adj_yield = (_.yield_mean / (1 - _.shade_percent)) / 5,
    #     scaled_std = (_.yield_std / 5)}) |>
    @df groupedbar(
        :shade_percent,
        :adj_yield_loss_mean,
        group = (:fragmentation),
        palette = vcat(plt[1], plt[5]),
        alpha = 0.8,
        yerr = :adj_yield_loss_std,
        ylim = (0, 0.5),
        legend = :topright,
        fg_legend = :transparent,
        bg_legend = :transparent,
        legendtitle = "Fragmentation",
        legendtitlefontsize = 8,
        legendfontsize = 7,
        legendtitlefonthalign = :right,
        label = ["Absent" "Present"],
        xlabel = "Proportion of Shade Trees",
        ylabel = "Relative Cumulative Yield Loss",
        labelfontsize = 10,
        size = (450, 350)
    )

png(yields, plotsdir("Yields"))


# Plot severities

severities = joined |>
    # @filter(_.shade_percent == 0.1) |>
    @filter(_.inspect_period == 30) |>
    @filter(_.fragmentation == false) |>
    @filter(_.target_shade == 0.3) |>
    @df plot(
        :step,
        :mean_sev_tot_mean,
        group = :shade_percent,
        # markershape = :circle,
        # markersize = 4,
        # markerstrokewidth = 0.1,
        ribbon = :rust_incid_std,
        fillalpha = 0.5,
        linewidth = 1.6,
        palette = plt,
        legend = (0.15, 0.8),
        legendtitle = "Proportion of\nShade Trees",
        legendtitlefontvalign = :bottom,
        legendtitlefonthalign = :right,
        legendtitlefontsize = 8,
        legendfontsize = 7,
        fg_legend = :transparent,
        bg_legend = :transparent,
        primary = true,
        xlabel = "Days",
        ylabel = "Rust Incidence",
        labelfontsize = 12,
        xticks = (collect(0:100:900)),
        size = (600,350)
    )
