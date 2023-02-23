using Statistics: mean, std
include("CofProdDymcs.jl")

# Simulate 40 y and take last 20 into consideration
# (Stable after first 15-20 y)
# Only odd year numbers are considered due to biennial patterns
# avg by each day of year (for future use; for now I only need v and s on veg_i=1; v,p,s on rep_i)

function lastyears(l::Float64, ys::Int, dayns::Vector{Int}, bd::Int = 135)::Array{Float64}
    return run_oncee(
        a=0.2,
        b=0.8,
        c=0.6,
        d=0.25,
        e=0.0,
        f=0.0,
        µ_V=0.01,
        μ_B=0.01,
        μ_S=0.001,
        γ=0.02,
        # veg_gro=0.3,
        rep_gro=0.7,
        bd=bd,
        years=ys,
        Vi=1.0,
        Si=1.0,
        lgh=l,
        wrust=false)[1:3, 
        #have to come up with a better way here. only even years
        dayns]
end

function dailyavgs(lstep::Float64, ys::Int, even::Bool, bd::Int = 135)
    nlights = length(lstep:lstep:1.0)
    vegav = Array{Float64,2}(undef, 365, nlights)
    prodav = Array{Float64,2}(undef, 365, nlights)
    storav = Array{Float64,2}(undef, 365, nlights)
    if even
        dayns = reduce(vcat, (y*365+1):(y*365+365) for y in (ys - 20):2:(ys - 2))
    else
        dayns = reduce(vcat, (y*365+1):(y*365+365) for y in (ys - 19):2:(ys - 1))
    end

    for (i, l) in enumerate(lstep:lstep:1.0)
        out = lastyears(l, ys, dayns, bd)
        vegav[:, i] = mean(reshape(out[1,:], 365, 10), dims = 2)
        prodav[:, i] = mean(reshape(out[2,:], 365, 10), dims = 2)
        storav[:, i] = mean(reshape(out[3,:], 365, 10), dims = 2)
    end

    vegav .= round.(vegav, digits = 6)
    prodav .= round.(prodav, digits = 6)
    storav .= round.(storav, digits = 6)

    return vegav, prodav, storav
end

function ndayavgs(day::Int, lstep::Float64, ys::Int, even::Bool, bd::Int = 135)
    vegav2, prodav2, storav2 = dailyavgs(lstep, ys, even, bd)
    return vegav2[day,:], prodav2[end-1,:], storav2[day,:]
end

function ndayevenodd(day::Int, lstep::Float64, ys::Int, bd::Int = 135)
    vegav2, prodav2, storav2 = dailyavgs(lstep, ys, true, bd)
    vegav3, prodav3, storav3 = dailyavgs(lstep, ys, false, bd)
    # return vegav2[day,:], vegav3[day,:], prodav2[day,:], prodav3[day,:], storav2[day,:], storav3[day,:]
    return vegav2[day,:], vegav3[day,:], prodav2[end-1,:], prodav3[end-1,:], storav2[day,:], storav3[day,:]
    # using end-1 for prod to see how the year ends produciton-wise
end

function plotevenodd(day::Int, lstep::Float64, ys::Int, bd::Int = 135)
    vegav2, vegav3, prodav2, prodav3, storav2, storav3 = ndayevenodd(day, lstep, ys, bd)
    lights = lstep:lstep:1.0
    fig = Figure()
    ax1, vegevenp = scatter(fig[1,1], lights, vegav2, label = "Even Years", markersize = 4)
    vegoddp = scatter!(ax1, lights, vegav3, label = "Odd Years", markersize = 4)
    ax2, storevenp = scatter(fig[2,1], lights, storav2, label = "Even Years", markersize = 4)
    storoddp = scatter!(ax2, lights, storav3, label = "Odd Years", markersize = 4)
    ax3, reprevenp = scatter(fig[3,1], lights, prodav2, label = "End of Even Years", markersize = 4)
    reproddp = scatter!(ax3, lights, prodav3, label = "End of Odd Years", markersize = 4)
    Legend(fig[1:2, 2], ax1)
    Legend(fig[3, 2], ax3)
    ax1.xticks = 0.0:0.1:1.0
    ax2.xticks = 0.0:0.1:1.0
    ax3.xticks = 0.0:0.1:1.0
    ax3.xlabel = "Sunlight"
    ax1.ylabel = "Veg"
    ax2.ylabel = "Stor"
    ax3.ylabel = "Repr"
    Label(fig[4,:], "Avgs from last 20 years of a total of $ys on day # $day, where veg_i = 1 and rep_i = $bd", tellwidth = false)
    DataInspector(fig)
    fig
end

ttfig40 = plotevenodd(1, 0.001, 40)
# Makie.inline!(true) #true -> display in ide; false -> new window (allows inspecting data points)
# ttfig40

vegodd, _, storodd = ndayavgs(1, 0.001, 40, false)

# test numbers
figtest = plot_sun_shade(false, false,
    a=0.2,
    b=0.8,
    c=0.6,
    d=0.25,
    e=0.0,
    f=0.0,
    µ_V=0.01,
    μ_B=0.01,
    μ_S=0.001,
    γ=0.02,
    # veg_gro=0.3,
    rep_gro=0.7,
    Vi=1.85,
    Si=2.703,
    bd=135,
    years=10, lasty=10
)

#=
0.1: 1.042, 57.897
0.3: 1.423, 16.607
0.5: 1.540, 7.562
0.7: 1.596, 3.656
1.0: 1.872, 2.259
=#

function print_dataframes(day::Int, lstep::Float64, ys::Int, bd::Int = 135)
    # path = mkpath("data/CoffeInitiation")
    vegav, prodav, storav = dailyavgs(lstep, ys, false, bd)
    slnames = [string("sl_", l) for l in lstep:lstep:1.0]
    # need using CSV, DataFrames
    # write (string(path, "bd135-y40-veg.csv"), DataFrame(vegav, slnames))
    # write (string(path, "bd135-y40-prod.csv"), DataFrame(prodav, slnames))
    # write (string(path, "bd135-y40-stor.csv"), DataFrame(storav, slnames))

end

function lookup_dict(day::Int, lstep::Float64, ys::Int, bd::Int = 135)
    # vegv, _, storv = ndayavgs(day, lstep, ys, false, bd)
    if !isfile("data/CoffeInitiation/bd$day-y$ys-veg.csv")
        print_dataframes(day, lstep, ys, bd)
    end
    vegv = CSV.read("data/CoffeInitiation/bd$day-y$ys-veg.csv", DataFrame, skipto = day, limit = 1)
    storv = CSV.read("data/CoffeInitiation/bd$day-y$ys-stor.csv", DataFrame, skipto = day, limit = 1)
    lights = lstep:lstep:1.0
    vegstor_light = Dict(l => (v, s) for (l,v,s) in zip(lights, vegv, storv))
end

Makie.inline!(true)
ttfitlights = 0.01:0.01:1.0
lines(ttfitlights, 100.0 .* exp.(- 6.2 .* ttfitlights) .+ 2.5)
lines!(0.001:0.001:1.0, storodd)
current_figure()


function stor_appr(light)
    C = 100.0
    k = -6.2
    c = 2.5

    C * exp(k * light) + c
end



## Now for ABC. Starts Apr 26, which is day # 116

ttfigabc = plotevenodd(116, 0.001, 40)

vegoddabc, _, storoddabc = ndayavgs(116, 0.001, 40, false)

ttfitlights = 0.01:0.01:1.0
lines(ttfitlights, 100.0 .* exp.(- 6.5 .* ttfitlights) .+ 7.8)
lines!(0.001:0.001:1.0, storoddabc)
current_figure()

lines(ttfitlights, -2.9 .* exp.(- 4.2 .* ttfitlights) .+ 4.7)
lines!(0.001:0.001:1.0, vegoddabc)
current_figure()

ndayavgs(116, 0.05, 40, false)

function stor_appr_abc(light)
    C = 100.0
    k = -6.5
    c = 7.8

    C * exp(k * light) + c
end

function veg_appr_abc(light)
    C = -2.9
    k = -4.2
    c = 4.7

    C * exp(k * light) + c
end