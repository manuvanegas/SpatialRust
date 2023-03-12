using CairoMakie

# cvs = CSV.read(projectdir("results/Shading/CVs-22.5-0.8.csv"), DataFrame)
# cvs2 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8.csv"), DataFrame)
# cvs22 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r100.csv"), DataFrame)
# append!(cvs22, CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1000.csv"), DataFrame))

# cvs3 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1001.csv"), DataFrame)
# cvs4 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-r1002.csv"), DataFrame)
# cvs5 = CSV.read(projectdir("results/Shading/CVs-22.5-0.8-1003.csv"), DataFrame)

cvs = CSV.read("results/Shading/ABCests/CVs-byaroccincid-23.0-0.8-600.csv", DataFrame)

fig = Figure();
ax = Axis(fig[1,1], xlabel = "Number of runs", ylabel = "CV");
lines!(ax, cvs.n, cvs.prod, label = "Coffee Production CV");
lines!(ax, cvs.n, cvs.area, label = "Max Rust Area CV");
axislegend()
fig

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
