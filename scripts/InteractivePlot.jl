using DrWatson
@quickactivate "SpatialRust"

using Agents, DataFrames, Distributions, InteractiveDynamics, Random
using DrWatson: srcdir
using StatsBase: sample

include(srcdir("ABMsetup.jl"))
include(srcdir("ABMstep.jl"))
include(srcdir("ABCrun.jl"))
include(srcdir("CustomRun.jl"))
include(srcdir("ReportFncts.jl"))

d_mod = initialize_sim(; map_dims = 20, shade_percent = 0.0, steps = 50)
d_adata, _ = run!(d_mod, dummystep, step_model!, 50, adata = [:pos])

n_steps = 100
par_ranges = Dict(:temp_cooling => 1.0:5.0, :wind_protec => 0.5:2.0)
adata = [(ind_area, mean), (ind_lesions, mean)]
plot_mod1 = initialize_sim(; shade_percent = 0.3, steps = n_steps)
plot_mod2 = initialize_sim(; shade_percent = 0.3, steps = n_steps)


## This is WIP. Some dependencies of InteractiveDynamics errored at precompilation. May have to do with recent OS update

figure, agentdf, modeldf = abm_data_exploration(plot_mod1, dummystep, step_model!, par_ranges;
    ac = a_color, am = a_shape, as = a_size,
    adata
)


#typecolor(agent) = isa(agent, Coffee) ? :green : isa(agent, Shade) ?
a_color(a::Coffee) = (a.area / 25) == 1 ? :green : cgrad([:black, :green], [0.4 0.7])[(a.area / 25)]
a_color(a::Shade) = :brown
a_color(a::Rust) = :orange

a_shape(a::Coffee) = :square
a_shape(a::Shade) = :square
a_shape(a::Rust) = :circle

a_size(a::Coffee) = 3
a_size(a::Shade) = 3
a_size(a::Rust) = a.area * 4
