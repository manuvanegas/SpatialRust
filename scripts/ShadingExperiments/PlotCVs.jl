using CairoMakie

# cvs = CSV.read(projectdir("results/Shading/CVs-22.5-0.8.csv"), DataFrame)
# cvs2 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8.csv"), DataFrame)
# cvs22 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r100.csv"), DataFrame)
# append!(cvs22, CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1000.csv"), DataFrame))

# cvs3 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1001.csv"), DataFrame)
# cvs4 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1002.csv"), DataFrame)
# cvs5 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-1003.csv"), DataFrame)
p = "results/Shading/ABCests2/CV"
temp = 22.0
rain = 0.8
maxreps = 600
ys = 4
cvs = CSV.read(joinpath(p, "CVs-$temp-$rain-$(maxreps)-$(ys)y.csv"), DataFrame)

cvsd = mapcols(diff, cvs[!, Not([:n, :nrow])])
cvsd.n = cvs.n[2:end];

fig = Figure(resolution = (500,600), fontsize = 16);
ax = Axis(fig[1,1], xlabel = "Number of runs", ylabel = "Coefficient of Variation",
xticks = [10;collect(50:50:600)], xticklabelsize = 14, yticklabelsize = 14);
lines!(ax, cvs.n, cvs.prod, label = "Total Observed Production");
lines!(ax, cvs.n, cvs.spore, label = "Maximum Cumulative Inoculum (maxSumSpore)");
lines!(ax, cvs.n, cvs.loss, label = "Production Loss Percentage (prodLoss)");
# lines!(ax, cvs.n, cvs.area, label = "Max Latent Area");
# lines!(ax, cvs.n, cvs.nls, label = "Max N Lesions");
# lines!(ax, cvs.n, cvs.exh, label = "Max Exhausted");
# axislegend(ax, position = :rc)
# fig
# cvs = CSV.read(joinpath(p, "CVs-$temp-$rain-$(maxreps)-$(r50s)-$(ys)y.csv"), DataFrame)

# fig2 = Figure(resolution = (600,400), fontsize = 16);
ax2 = Axis(fig[2,1], xlabel = "Number of Repetitions", ylabel = "Coefficient of Variation Difference",
xticks = [10;collect(50:50:600)], xticklabelsize = 14, yticklabelsize = 14);
lines!(ax2, cvsd.n, cvsd.prod, label = "Total Observed Production");
lines!(ax2, cvsd.n, cvsd.spore, label = "Maximum Cumulative Inoculum (maxSumSpore)");
lines!(ax2, cvsd.n, cvsd.loss, label = "Production Loss Percentage (prodLoss)");
# lines!(ax2, cvsd.n, cvsd.area, label = "Max Latent Area");
# lines!(ax2, cvsd.n, cvsd.nls, label = "Max N Lesions");
# lines!(ax2, cvsd.n, cvsd.exh, label = "Max Exhausted");
# axislegend(ax2, position = :rb)
hidexdecorations!(ax, grid = false)
linkxaxes!(ax,ax2)
yspace = maximum(tight_yticklabel_spacing!, [ax, ax2])
ax.yticklabelspace = yspace
ax2.yticklabelspace = yspace
Legend(fig[0,1], ax, "",tellheight = false, tellwidth = false, framevisible = false, labelsize = 14)
rowsize!(fig.layout, 0, Relative(1/10))
fig



save("../../Dissertation/Chapters/Diss/Document/Figs/Shading/CVs.png", fig)
save("plots/Shading/now/CVs.png", fig)
