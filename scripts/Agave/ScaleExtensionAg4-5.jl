@everywhere using DrWatson
@everywhere quickactivate("/home/mvanega1/SpatialRust/", "SpatialRust")

@everywhere using Agents, AgentsPlots, CSV, DataFrames, Distributed, Random, StatsBase, Statistics

@everywhere include(srcdir("FarmInit.jl"))
@everywhere include(srcdir("ABMsim.jl"))
@everywhere include(srcdir("OneFarm.jl"))
@everywhere include(srcdir("AddToAgents.jl"))
@everywhere include(srcdir("ReportFncts.jl"))


@everywhere adata = [ind_area, ind_lesions]
@everywhere mdata = [count_rusts, :yield]

@everywhere steps = 950
@everywhere max_dim = 500

@everywhere repls = nworkers()

@everywhere function init_and_time(dims, steps)
    ii = initialize_sim(; map_dims=dims, shade_percent = 0.0, light_inh = 0.1, rain_washoff = 0.1, inspect_period = 30, rain_prob = [0.9], wind_prob = [0.6])
    timed = @timed aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, steps; adata = adata, mdata=mdata)
    rr = DataFrame(time = timed.time, bytes = timed.bytes)
    return rr
end

@everywhere function run_timing_exp(map_dim, repls, steps)
    out = DataFrame()
    out.map_dim = fill(map_dim,repls)
    out.rep = collect(1:repls)
    timesnbytes = pmap(j -> init_and_time(map_dim, steps), out.rep, retry_delay = zeros(3))
    t_n_b = reduce(vcat, timesnbytes)
    out.time = t_n_b.time
    out.bytes = t_n_b.bytes
    CSV.write(projectdir("results","timing_scales",string("$map_dim",".csv")), out)
end

for map_dim in 500:100:max_dim
    run_timing_exp(map_dim, repls, steps)
end


using Query, StatsPlots

function collect_and_plot_times()
    files = filter(x -> endswith(x, ".csv"), readdir(projectdir("results", "timing_scales")))
    dfs = DataFrame.(CSV.File.(projectdir.("results","timing_scales",files)))
    df = reduce(vcat, dfs)

    df.time = df.time / 60

    times = combine(groupby(df, :map_dim), [:time .=> f for f in [mean, minimum, maximum, std]])
    bytes = combine(groupby(df, :map_dim), [:bytes .=> f for f in [mean, minimum, maximum, std]])


    times_p = @df times plot(
    :map_dim,
    :time_mean,
    legend = :bottomright,
    # markershape = :circle,
    # markersize = 4,
    # markerstrokewidth = 0.1,
    ribbon = :time_std,
    fillalpha = 0.4,
    label = "Mean (sd)",
    # linewidth = 1.6,
    # # palette = plt,
    # legend = (0.15, 0.8),
    # legendtitle = "Proportion of\nShade Trees",
    # legendtitlefontvalign = :bottom,
    # legendtitlefonthalign = :right,
    # legendtitlefontsize = 8,
    # legendfontsize = 7,
    # fg_legend = :transparent,
    # bg_legend = :transparent,
    # primary = true,
    xlabel = "Map Side Length",
    ylabel = "Running Time (min)"
    # labelfontsize = 10,
    # ylims = (0, 1.05),
    # xticks = (collect(0:100:900)),
    # size = (450,350)
    )

    times_p = @df times plot!(
    :map_dim,
    :time_maximum,
    label = "Maximum",
    linestyle=:dash
    )
    times_p = @df times plot!(
    :map_dim,
    :time_minimum,
    label = "Minimum",
    linestyle=:dash
    )

    bytes_p = @df bytes plot(
    :map_dim,
    :bytes_mean,
    legend = :bottomright,
    label = "Mean (sd)",
    ribbon = :bytes_std,
    fillalpha = 0.4,
    xlabel = "Map Side Length",
    ylabel = "Bytes Allocated"
    )

    bytes_p = @df bytes plot!(
    :map_dim,
    :bytes_maximum,
    label = "Maximum",
    linestyle=:dash
    )
    bytes_p = @df bytes plot!(
    :map_dim,
    :bytes_minimum,
    label = "Minimum",
    linestyle=:dash
    )

    png(times_p, plotsdir("timing_scale_extension"))
    png(bytes_p, plotsdir("memory_scale_extension"))
end
