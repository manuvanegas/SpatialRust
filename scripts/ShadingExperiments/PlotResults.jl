Pkg.activate("src/ShadingExperiments/.")
using CairoMakie, CSV, DataFrames
using Statistics
include("Plots.jl")


## base scenario: 22.5 T, 0.8 rain
bfiles = filter(f -> occursin("/r2", f), readdir(projectdir("../../results/Shading/r-22.5-0.8/"), join = true))
basedf = reduce(vcat, [CSV.read(f, DataFrame) for f in bfiles])
add_useful_cols!(basedf)
# describe(res)
describe(basedf)
hist(basedf.maxA)
hist(basedf.totprod)
scatter(basedf.maxA, basedf.totprod)

w_b_areas, w_b_prod, w_b_prod_c = wide_plot_dfs(basedf)

f_base_a = pa_plot(w_b_areas, "Maximum Median Rust Area")
f_base_p = pa_plot(w_b_prod, "Median Total Coffee Production")
f_base_p_c = pa_plot(w_b_prod_c, "Median Production per Coffee", 22.5, 0.8)

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
