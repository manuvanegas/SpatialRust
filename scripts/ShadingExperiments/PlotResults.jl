# Pkg.activate("src/ShadingExperiments/.")
using CairoMakie, CSV, DataFrames
using Statistics
using AlgebraOfGraphics
include("../../src/ShadingExperiments/Heatmaps.jl")
include("../../src/ShadingExperiments/Scatterplots.jl")


temp = 22.0
rain = 0.8
wind = 0.7
reps = 200
savefigs = false

# Merge all df's, correct shade_val, and write a single file
# bfiles = readdir(string("results/Shading/ABCests/exp-22.0-0.8-0.7/"), join = true);
# basedf = reduce(vcat, [CSV.read(f, DataFrame) for f in bfiles if (contains(f, "r-$reps") && !contains(f, "all"))])
# rename!(basedf, :shadeval => :shade_val)
# transform!(basedf,
#         [:shade_d, :barriers, :prunes_year, :shade_val] => 
#         ByRow(correctshadeval) => :shade_val,
# )
# CSV.write("results/Shading/ABCests/exp-22.0-0.8-0.7/r-200-all-4y.csv", basedf)

basedf = CSV.read("results/Shading/ABCests/exp-22.0-0.8-0.7/r-200-all-4y.csv", DataFrame)

transform!(basedf,
        [:obsprod, :attprod] => ByRow((o,e) -> (1.0 - o / e)) => :loss,
        [:obsprod, :n_coffees] => ByRow((p,c) -> p/c) => :prod_cof
)

respvars = [:obsprod, :prod_cof, :loss, :maxA, :maxS, :maxN, :maxE, :attprod]
meanshading = combine(groupby(basedf, [:n_shades, :prunes_year, :shade_val]),
    [:barriers, :shade_d] .=> first .=> [:barriers, :shade_d],
    :shading => mean => :meanshade,
    respvars .=> mean .=> respvars,
)

hmfig = shade_heatmap(meanshading)

savefigs && savehere("shadehm2.png", hmfig)
savefigs && savediss("shadehm2.png", hmfig)


# scprod = scbyprunefreqbarr(meanshading, :prod, "Total Farm Production")
# scmaxa = scbyprunefreqbarr(meanshading, :maxA, "Maximum Latent Area Accumulation")
scloss = scbyprunefreqbarr(meanshading, :loss, "", 0.0:0.2:0.6)
scmaxs = scbyprunefreqbarr(meanshading, :maxS, "", 0:20:60)

savefigs && savediss("lossbyfreqbr.png", scloss)
savefigs && savehere("lossbyfreqbr.png", scloss)
savefigs && savediss("maxSbyfreqbr.png", scmaxs)
savefigs && savehere("maxSbyfreqbr.png", scmaxs)


dropprunesyear = combine(groupby(basedf, [:shade_d, :shade_val, :barriers]),
    :shading => mean => :meanshade,
    [:obsprod, :attprod] .=> mean .=> [:obsprod, :attprod],
    [:obsprod, :attprod] .=> std .=> [:obsprod_sd, :attprod_sd],
)   

o_vs_a = obsvsatt(dropprunesyear)

savefigs && savehere("prods.png", o_vs_a)
savefigs && savediss("prods.png", o_vs_a)

