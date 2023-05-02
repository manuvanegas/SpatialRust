# Pkg.activate("src/ShadingExperiments/.")
using CairoMakie, CSV, DataFrames
using Statistics
using AlgebraOfGraphics
include("../../src/ShadingExperiments/Heatmaps.jl")
include("../../src/ShadingExperiments/Scatterplots.jl")


## base scenario: 22.5 T, 0.8 rain
temp = 22.0
rain = 0.8
wind = 0.7
reps = 25
savefigs = false
bfiles = readdir(string("results/Shading/ABCests/exp-22.0-0.8-0.7/"), join = true);
basedf = reduce(vcat, [CSV.read(f, DataFrame) for f in bfiles if contains(f, "r-$reps")])
# ndf = CSV.read("results/Shading/ABCests/exp-22.0-0.8-0.7/r-25-2-4y-2.csv", DataFrame)

function shadeval(st,n)
    if st == "Float64[]"
        n == 0 ? (return 0.0) : (return 0.8)
    else
        return parse(Float64, split(st[2:end-1],",")[1])
    end
end
transform!(basedf,
        [:obsprod, :attprod] => ByRow((o,e) -> (1.0 - o / e)) => :loss,
        [:post_prune, :n_shades] => ByRow(shadeval) => :shade_val,
        [:obsprod, :n_coffees] => ByRow((p,c) -> p/c) => :prod_cof
)
# describe(res)
describe(basedf)
hist(basedf.maxA)
hist(basedf.maxN)
hist(basedf.loss)
scatter(basedf.maxA, basedf.obsprod)
scatter(basedf.maxS, basedf.loss)
scatter(basedf.maxA, basedf.obsprod)
scatter(basedf.maxS, basedf.loss)

meanshading = combine(groupby(basedf, [:n_shades, :prunes_year, :shade_val]),
    :shading => mean => :meanshade,
    [:obsprod, :loss, :maxA, :maxS, :maxN, :maxE] .=> mean .=> [:prod, :loss, :maxA, :maxS, :maxN, :maxE],
)

hmfig = shade_heatmap(meanshading)
# hmfigr = shade_heatmap_rot(meanshading)

savefigs && savehere("shadehm2.png", hmfig)
savefigs && savediss("shadehm2.png", hmfig)

varsbyshading = combine(groupby(basedf, [:n_shades, :prunes_year, :shade_val]),
    [:barriers, :shade_d] .=> first .=> [:barriers, :shade_d],
    :shading => mean => :meanshade,
    [:obsprod, :prod_cof, :loss, :maxA, :maxS, :maxN, :maxE] .=> mean .=> [:prod, :prod_cof, :loss, :maxA, :maxS, :maxN, :maxE],
    :attprod => mean => :attprod
)
# basescattershade(varsbyshading, :prod, :shade_val)
# basescattershade(varsbyshading, :loss, :barriers)
# basescattershade(varsbyshading, :maxA, :barriers)
# basescattershade(varsbyshading, :maxS, :barriers)
# basescattershade(varsbyshading, :maxN, :barriers)
# basescattershade(varsbyshading, :maxE, :barriers)
# basescattershade(varsbyshading, :attprod, :barriers)

scloss = scbyprunefreqbarr(varsbyshading, :loss, "Production Loss (%)")
scprod = scbyprunefreqbarr(varsbyshading, :prod, "Total Farm Production")
scmaxa = scbyprunefreqbarr(varsbyshading, :maxA, "Maximum Latent Area Accumulation")
scmaxs = scbyprunefreqbarr(varsbyshading, :maxS, "Maximum Inoculum Accumulation")

# sclossd = scbyshadedistbarr(varsbyshading, :loss)
# add_legend!(scloss)
# lf = get_legend(Figure())
# scloss = drawsc!(Figure(), varsbyshading, :loss)

savediss("lossbydist.png", scloss)






w_b_areas, w_b_prod, w_b_prod_c = wide_plot_dfs(basedf)

f_base_a = pa_plot(w_b_areas, "Maximum Median Rust Area", temp, rain)
f_base_p = pa_plot(w_b_prod, "Median Total Coffee Production", temp, rain)
f_base_p_c = pa_plot(w_b_prod_c, "Median Production per Coffee", temp, rain)

# save("plots/Shading/RelativeProd_Base.png", f_base_p_c)

## future (1): 23.5, 0.65
f1files = filter(f -> occursin("/r2", f), readdir(projectdir("../../results/Shading/r-23.5-0.65/"), join = true))
f1df = reduce(vcat, [CSV.read(f, DataFrame) for f in f1files])
add_useful_cols!(f1df)
# describe(res)
describe(f1df)
hist(f1df.maxA)
hist(f1df.totprod)
scatter(f1df.maxA, f1df.totprod)

w_f1_areas, w_f1_prod, w_f1_prod_c = wide_plot_dfs(f1df)

f_f1_a = pa_plot(w_f1_areas, "Maximum Median Rust Area")
f_f1_p = pa_plot(w_f1_prod, "Median Total Coffee Production")
f_f1_p_c = pa_plot(w_f1_prod_c, "Median Production per Coffee", 23.5, 0.65)

# save("plots/Shading/RelativeProd_F1.png", f_f1_p_c)

## Tests

yearly0_2 = subset(basedf, :target_shade => sh -> sh .== 0.2, :prune_period => p -> p .== 365)
groupedbase02 = groupby(yearly0_2, [:shade_d, :usedbarriers])
# groupedbase[filter(k -> (k[:target_shade] == 0.2 && k[:prune_period] == 365), keys(groupedbase))]

KWb = KruskalWallisTest(
        groupedbase02[1].prod_cof,
        groupedbase02[2].prod_cof,
        groupedbase02[3].prod_cof,
        groupedbase02[4].prod_cof,
        groupedbase02[5].prod_cof
    )
pvalue(KWb)

b_y_02 = prod_c_boxplot(yearly0_2)

f1_yearly0_2 = subset(f1df, :target_shade => sh -> sh .== 0.2, :prune_period => p -> p .== 365)
f1_grouped02 = groupby(f1_yearly0_2, [:shade_d, :usedbarriers])
# groupedbase[filter(k -> (k[:target_shade] == 0.2 && k[:prune_period] == 365), keys(groupedbase))]

f1_KWb = KruskalWallisTest(
        f1_grouped02[1].prod_cof,
        f1_grouped02[2].prod_cof,
        f1_grouped02[3].prod_cof,
        f1_grouped02[4].prod_cof,
        f1_grouped02[5].prod_cof
    )
pvalue(f1_KWb)

f1_yearly0_9 = subset(f1df, :target_shade => sh -> sh .== 0.9, :prune_period => p -> p .== 365)
f1_grouped09 = groupby(f1_yearly0_9, [:shade_d, :usedbarriers])
# groupedbase[filter(k -> (k[:target_shade] == 0.2 && k[:prune_period] == 365), keys(groupedbase))]

f1_KWb_09 = KruskalWallisTest(
        f1_grouped09[1].prod_cof,
        f1_grouped09[2].prod_cof,
        f1_grouped09[3].prod_cof,
        f1_grouped09[4].prod_cof,
        f1_grouped09[5].prod_cof
    )
pvalue(f1_KWb_09)

f1_y_02 = prod_c_boxplot(f1_yearly0_2)

# save("plots/Shading/box_yearly02_Base.png", b_y_02)
# save("plots/Shading/box_yearly02_F1.png", f1_y_02)
