using DrWatson
@quickactivate "SpatialRust"

using Agents, AgentsPlots, CSV, DataFrames, Distributed, Query, StatsPlots, Random, StatsBase, Statistics

include(srcdir("FarmInit.jl"))
include(srcdir("ABMsim.jl"))
include(srcdir("OneFarm.jl"))
include(srcdir("AddToAgents.jl"))
include(srcdir("ReportFncts.jl"))


adata = [ind_area, ind_lesions]
mdata = [count_rusts, :yield]

steps = 5
max_dim = 200

repls = nworkers()

function init_and_time(dims, steps)
    ii = initialize_sim(; map_dims=dims, shade_percent = 0.0, light_inh = 0.1, rain_washoff = 0.1, inspect_period = 30, rain_prob = [0.9], wind_prob = [0.6])
    timed = @timed aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, steps; adata = adata, mdata=mdata)
    rr = DataFrame(time = timed.time, bytes = timed.bytes)
    return rr
end

function run_timing_exp(map_dim, repls, steps)
    out = DataFrame()
    out.map_dim = fill(map_dim,repls)
    out.rep = collect(1:repls)
    timesnbytes = pmap(j -> init_and_time(map_dim, steps), out.rep, retry_delay = zeros(3))
    t_n_b = reduce(vcat, timesnbytes)
    out.time = t_n_b.time
    out.bytes = t_n_b.bytes
    CSV.write(projectdir("results","timing_scales",string("$map_dim",".csv")), out)
end

for map_dim in 100:100:max_dim
    run_timing_exp(map_dim, repls, steps)
end


function collect_and_plot_times()
    files = filter(x -> endswith(x, ".csv"), readdir(projectdir("results", "timing_scales")))
    dfs = DataFrame.(CSV.File.(projectdir.("results","timing_scales",files)))
    df = reduce(vcat, dfs)

    grouped = groupby(df, :map_dim)

    means = combine(grouped, :time .=> mean)
    stds = combine(grouped, :time .=> std)

    joined = innerjoin(means,stds, on = :map_dim)


    times = @df joined plot(
    :map_dim,
    :time_mean,
    legend = false,
    # markershape = :circle,
    # markersize = 4,
    # markerstrokewidth = 0.1,
    ribbon = :time_std,
    fillalpha = 0.4,
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
    xlabel = "Map Side",
    ylabel = "Running Time"
    # labelfontsize = 10,
    # ylims = (0, 1.05),
    # xticks = (collect(0:100:900)),
    # size = (450,350)
    )

    png(times, plotsdir("timing_scale_extension"))
end
