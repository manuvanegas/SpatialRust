using DrWatson
@quickactivate "SpatialRust"

using Agents, AgentsPlots, CSV, DataFrames, Distributed, Plots, Random, StatsBase, Statistics
# import Dates.now

include(srcdir("FarmInit.jl"))
include(srcdir("ABMsim.jl"))
include(srcdir("OneFarm.jl"))
include(srcdir("AddToAgents.jl"))
include(srcdir("ReportFncts.jl"))

adata = [ind_area, ind_lesions]
mdata = [count_rusts, rust_incid, mean_sev_tot, std_sev_tot,
        mean_production, std_production, :yield]

function init_and_run(dims, steps)
    ii = initialize_sim(; map_dims=dims, shade_percent = 0.1, light_inh = 0.1, rain_washoff = 0.1)
    aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, steps; adata = adata, mdata=mdata)
end

@df aadd plot(:step, :ind_lesions, group = :id, legend = false)
plot(mmdd.step, mmdd.mean_rust_sev_tot, xlims=(100,200))

function init_and_gif(dims, steps, filename)
    model = initialize_sim(; map_dims=dims, shade_percent = 0.1, light_inh = 0.1, rain_washoff = 0.1)
    l = @layout [a b]
    p1 = myplotabm(model;
            am = b_shape,
            as = b_size,
            ac = b_color,
            size = (2000, 1000),
            grid = false,
            showaxis = false,
            aspect_ratio = :equal,
            title = "step 0")
    p2 = myplotabm(model;
            am = b_shape,
            as = b_size,
            ac = b_color,
            size = (2000, 1000),
            grid = false,
            showaxis = false,
            aspect_ratio = :equal)
    # t = plot(title = "step 0", grid = false, showaxis = false, titlefontsize = 30)
    p = plot(p1, p2, layout = l)

    anim = Animation()
    for i in 1:steps
        step!(model, pre_step!, agent_step!, model_step!)
        plotabm!(p[1], model;
                am = b_shape,
                as = b_size,
                ac = b_color,
                size = (2000, 1000),
                grid = false,
                showaxis = false,
                aspect_ratio = :equal)
        # title!(p1, "step $(i)", titlefontsize = 30)
        plotabm!(p[2], model;
                am = b_shape,
                as = b_size,
                ac = b_color,
                size = (2000, 1000),
                grid = false,
                showaxis = false,
                aspect_ratio = :equal)
        title!(p[1], "step $(i)", titlefontsize = 30, titlelocation = :left)
        # p = plot(p1, p2, layout = l)
        frame(anim, p)
    end
    gif(anim, plotsdir("gifs", string(filename, ".gif")), fps = 2)
end

function init_and_gif_rust(dims, steps, filename, frag)
    model = initialize_sim(; map_dims=dims, fragmentation = frag, shade_percent = 0.1, light_inh = 0.1, rain_washoff = 0.1)
    p1 = plotabm(model;
            am = a_shape,
            as = a_size,
            ac = a_color,
            size = (800, 800),
            grid = false,
            showaxis = false,
            aspect_ratio = :equal,
            title = "step 0")

    anim = @animate for i in 1:steps
        step!(model, pre_step!, agent_step!, model_step!)
        plotabm(model;
                am = a_shape,
                as = a_size,
                ac = a_color,
                size = (800, 800),
                grid = false,
                showaxis = false,
                aspect_ratio = :equal)
        title!("step $(i)", titlefontsize = 20)
    end
    gif(anim, plotsdir("gifs", string(filename, "-rust.gif")), fps = 8)
end

model = initialize_sim(; map_dims=10, shade_percent = 0.1, light_inh = 0.1, rain_washoff = 0.1)
plotabm(model;
        am = a_shape,
        as = a_size,
        ac = a_color,
        grid = false,
        showaxis = false,
        aspect_ratio = :equal)


### visualization functions
a_color(a::Coffee) = (a.area / 25) == 1 ? :green : cgrad([:black, :green], [0.4 0.7])[(a.area / 25)]
a_color(a::Shade) = :brown
a_color(a::Rust) = :orange

b_color(a::Coffee) = cgrad([:brown, :green])[a.production]
b_color(a::Shade) = :brown
b_color(a::Rust) = :orange

a_shape(a::Coffee) = :square
a_shape(a::Shade) = :square
a_shape(a::Rust) = :circle

b_shape(a::Coffee) = :square
b_shape(a::Shade) = :square
b_shape(a::Rust) = :circle

a_size(a::Coffee) = 3
a_size(a::Shade) = 3
a_size(a::Rust) = a.area * 4

b_size(a::Coffee) = 4
b_size(a::Shade) = 4
b_size(a::Rust) = 1



function plotabm!(plt, mmodel::ABM{A,<:Union{GridSpace,ContinuousSpace}};
    ac = "#765db4",
    as = 10,
    am = :circle,
    scheduler = mmodel.scheduler,
    offset = nothing,
    kwargs...,
    )   where {A}

    ids = mmodel.scheduler(mmodel)
    colors = typeof(ac) <: Function ? [ac(mmodel[i]) for i in ids] : ac
    sizes = typeof(as) <: Function ? [as(mmodel[i]) for i in ids] : as
    markers = typeof(am) <: Function ? [am(mmodel[i]) for i in ids] : am
    if offset == nothing
        pos = [mmodel[i].pos for i in ids]
    else
        pos = [mmodel[i].pos .+ offset(mmodel[i]) for i in ids]
    end

    scatter!(plt,
        pos;
        markercolor = colors,
        markersize = sizes,
        markershapes = markers,
        label = "",
        markerstrokewidth = 0.5,
        markerstrokecolor = :black,
        kwargs...,
    )
end

function myplotabm(mmodel::ABM{A,<:Union{GridSpace,ContinuousSpace}};
    ac = "#765db4",
    as = 10,
    am = :circle,
    scheduler = mmodel.scheduler,
    offset = nothing,
    kwargs...,
    )   where {A}

    ids = mmodel.scheduler(mmodel)
    colors = typeof(ac) <: Function ? [ac(mmodel[i]) for i in ids] : ac
    sizes = typeof(as) <: Function ? [as(mmodel[i]) for i in ids] : as
    markers = typeof(am) <: Function ? [am(mmodel[i]) for i in ids] : am
    if offset == nothing
        pos = [mmodel[i].pos for i in ids]
    else
        pos = [mmodel[i].pos .+ offset(mmodel[i]) for i in ids]
    end

    scatter!(
        pos;
        markercolor = colors,
        markersize = sizes,
        markershapes = markers,
        label = "",
        markerstrokewidth = 0.5,
        markerstrokecolor = :black,
        kwargs...,
    )
end
