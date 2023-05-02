using CairoMakie

# cvs = CSV.read(projectdir("results/Shading/CVs-22.5-0.8.csv"), DataFrame)
# cvs2 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8.csv"), DataFrame)
# cvs22 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r100.csv"), DataFrame)
# append!(cvs22, CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1000.csv"), DataFrame))

# cvs3 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1001.csv"), DataFrame)
# cvs4 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1002.csv"), DataFrame)
# cvs5 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-1003.csv"), DataFrame)
p = "results/Shading/ABCests/CV"
temp = 22.0
rain = 0.8
maxreps = 500
ys = 4
r50s = 450
# cvs = CSV.read(joinpath(p, "CVs-$temp-$rain-$(maxreps)-$(ys)y-a.csv"), DataFrame)
# cvs50 = CSV.read(joinpath(p, "CVs-$temp-$rain-$(r50s)-$(ys)y.csv"), DataFrame)
# append!(cvs, cvs50)
# sort!(cvs, :n)
# CSV.write(joinpath(p, "CVs-$temp-$rain-500-450-$(ys)y.csv"), cvs)
cvs = CSV.read(joinpath(p, "CVs-$temp-$rain-$(maxreps)-$(r50s)-$(ys)y.csv"), DataFrame)


fig = Figure();
ax = Axis(fig[1,1], xlabel = "Number of runs", ylabel = "Coefficient of Variation",
xticks = collect(100:100:500));
lines!(ax, cvs.n, cvs.loss, label = "Coffee Production Loss");
lines!(ax, cvs.n, cvs.area, label = "Max Latent Area");
lines!(ax, cvs.n, cvs.spore, label = "Max Spore Area");
lines!(ax, cvs.n, cvs.nls, label = "Max N Lesions");
lines!(ax, cvs.n, cvs.exh, label = "Max Exhausted");
axislegend()
fig

cvsd = mapcols(diff, cvs[!, Not([:n, :nrow])])
cvsd.n = cvs.n[2:end]
cvs = CSV.read(joinpath(p, "CVs-$temp-$rain-$(maxreps)-$(r50s)-$(ys)y.csv"), DataFrame)

fig2 = Figure();
ax2 = Axis(fig2[1,1], xlabel = "Number of runs", ylabel = "Coefficient of Variation Difference",
xticks = collect(100:100:500));
lines!(ax2, cvsd.n, cvsd.loss, label = "Coffee Production Loss");
lines!(ax2, cvsd.n, cvsd.area, label = "Max Latent Area");
lines!(ax2, cvsd.n, cvsd.spore, label = "Max Spore Area");
lines!(ax2, cvsd.n, cvsd.nls, label = "Max N Lesions");
lines!(ax2, cvsd.n, cvsd.exh, label = "Max Exhausted");
# axislegend()
fig2

fig2 = Figure()
ax = Axis(fig2[1,1], xlabel = "Number of runs", ylabel = "CV")
lines!(ax, cvs2.n, cvs2.prod, label = "Coffee Production CV")
lines!(ax, cvs2.n, cvs2.area, label = "Max Rust Area CV")
axislegend()
fig2

fig3 = Figure();
ax3 = Axis(fig3[1,1], xlabel = "Number of runs",
    ylabel = L"Coefficient of Variance, $C_V$ = $\frac{μ}{σ^2}$",
    fontsize = 18)
lines!(ax3, cvs22.n, cvs22.prod, label = "Coffee Production CV")
lines!(ax3, cvs22.n, cvs22.area, label = "Max Rust Area CV")
axislegend()
fig3

fig4 = Figure();
ax4 = Axis(fig4[1,1], xlabel = L"Number of runs",
    ylabel = L"Coefficient of Variance, $C_V$ = $\frac{μ}{σ^2}$")
lines!(ax4, cvs3.n, cvs3.prod, label = L"Coffee Production CV")
lines!(ax4, cvs3.n, cvs3.area, label = L"Max Rust Area CV")
axislegend()
fig4

fig5 = CV_plot(cvs5)

# save("plots/Shading/CVs.png", fig5)
