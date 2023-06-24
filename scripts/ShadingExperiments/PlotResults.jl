# Pkg.activate("src/ShadingExperiments/.")
using CairoMakie, CSV, DataFrames
using Statistics
using AlgebraOfGraphics
include("../../src/ShadingExperiments/Heatmaps.jl")
include("../../src/ShadingExperiments/Scatterplots.jl")


temp = 22.0
rain = 0.8
wind = 0.7
reps = 300
savefigs = true

# Merge all dfs and write a single file
# bfiles = readdir(string("results/Shading/ABCests2/exps2/"), join = true);
# basedf = reduce(vcat, [CSV.read(f, DataFrame) for f in bfiles if (contains(f, "r-$reps") && !contains(f, "all"))])
# CSV.write("results/Shading/ABCests2/exps2/r-300-all-4y.csv", basedf)

basedf = CSV.read("results/Shading/ABCests2/exps2/r-300-all-4y.csv", DataFrame)

transform!(basedf,
        [:obsprod, :attprod] => ByRow((o,e) -> (1.0 - o / e)) => :loss,
        [:obsprod, :n_coffees] => ByRow((p,c) -> p/c) => :prod_cof,
        :maxE => ByRow(e -> e * 100.0) => :maxE
)

respvars = [:obsprod, :prod_cof, :loss, :maxA, :maxS, :maxN, :maxE, :attprod]
meanshading = combine(groupby(basedf, [:n_shades, :prunes_year, :shade_val]),
    [:barriers, :shade_d] .=> first .=> [:barriers, :shade_d],
    :shading => mean => :meanshade,
    respvars .=> mean .=> respvars,
    respvars .=> std .=> Symbol.(respvars, :_sd),
    [:loss, :maxS, :maxA, :maxE] .=> extrema
)

eg1 = simplerun(365, p_rusts = 0.0, common_map = :regshaded, shade_d = 9, prune_sch = [74, 196, 319], post_prune = [0.4,0.4,0.4])
eg2 = simplerun(365, p_rusts = 0.0, shade_d = 9, barriers = (1,1), prune_sch = [74,227], post_prune = [0.4,0.4])
eg3 = simplerun(365, p_rusts = 0.0, shade_d = 6, barriers = (1,1), prune_sch = [74,], post_prune = [0.4,])
egdf = DataFrame(dayn = eg1.dayn, mapshade1 = eg1.mapshade, mapshade2 = eg2.mapshade, mapshade3 = eg3.mapshade)
climits = extrema(meanshading.meanshade)

hmfig = shade_heatmap(meanshading)
hmfig = addegplots!(hmfig, egdf, climits, 0.75)

savefigs && savehere("shadehm3.png", hmfig)
savefigs && savediss("shadehm3.png", hmfig)


# scprod = scbyprunefreqbarr(meanshading, :prod, "Total Farm Production")
# scmaxa = scbyprunefreqbarr(meanshading, :maxA, "Maximum Latent Area Accumulation")
scloss = scbyprunefreqbarr(meanshading, :loss, "")
colsize!(scloss.layout, 5, Relative(1/15))
scmaxs = scbyprunefreqbarr(meanshading, :maxS, "")
scmaxa = scbyprunefreqbarr(meanshading, :maxA, "", 20:5:35)
scmaxe = scbyprunefreqbarr(meanshading, :maxE, "", 89:3:98)

savefigs && savediss("maxAbyfreqbr2h.png", scmaxa)


# aogmaxa = aogfreqbarr(meanshading, :maxA, "max area")
# aogmaxe = aogfreqbarr(meanshading, :maxA, "max exh")
# with_theme(
#     Theme(palette = (
#         marker = [:circle, :utriangle, :rect, :diamond],
#         strokecolor = cgrad(:speed, 10, categorical = true)[3:10],
#         color = cgrad(:speed, 10, categorical = true)[3:10]
#     ))
# ) do
# clrfig = Figure(resolution = (1000,900));
# clrax1 = GridLayout(clrfig[1,1])
# clrax2 = GridLayout(clrfig[1,2])
# draw!(clrax1, aogmaxa)
# draw!(clrax2, aogmaxe)
# clrfig
# end

savefigs && savediss("lossbyfreqbr2h.png", scloss)
savefigs && savehere("lossbyfreqbr2h.png", scloss)
# savefigs && savediss("maxSbyfreqbr2.png", scmaxs)
# savefigs && savehere("maxSbyfreqbr2.png", scmaxs)
savefigs && savediss("maxAbyfreqbr2h.png", scmaxa)
savefigs && savehere("maxAbyfreqbr2h.png", scmaxa)
savefigs && savediss("maxEbyfreqbr2h.png", scmaxe)
savefigs && savehere("maxEbyfreqbr2h.png", scmaxe)


dropprunesyear = combine(groupby(basedf, [:shade_d, :shade_val, :barriers]),
    :shading => mean => :meanshade,
    [:obsprod, :attprod] .=> mean .=> [:obsprod, :attprod],
    [:obsprod, :attprod] .=> std .=> [:obsprod_sd, :attprod_sd],
)

o_vs_a = obsvsatt(dropprunesyear)
scatter(dropprunesyear.meanshade, dropprunesyear.obsprod)

savefigs && savehere("prods2.png", o_vs_a)
savefigs && savediss("prods2.png", o_vs_a)

scatter(basedf.shading, basedf.maxA)


# scloss2 = scbydistbarr(meanshading, :loss, "loss")
# scmaxs2 = scbydistbarr(meanshading, :maxS, "loss")