## Trying to decide whether growth rate is well defined.
# It is. Calibrating opt_g_temp will (trasladar) the parabole to the sides
# Could also calibrate the "ancho" or min/max growth temps, but seems like
# too much detail for a section that is not well characterized


# using Interact, Plots
#
# @manipulate for local_temp = 14:0.5:30
#     days = collect(1:50)
#     size = zeros(length(days))
#     size[1] = 0.01
#
#     for day in 2:length(days)
#         size[day] = size[day - 1] + 0.5 * (-0.0178 * ((- local_temp + 22.5) ^ 2) + 1) * size[day - 1] * (1 - size[day - 1])
#     end
#
#     plot(days, size)
# end
#
# @manipulate for opt_temp = 14:0.5:30,
#                 ancho = 0.005:0.002:0.03
#     local_temp = collect(10:0.2:34)
#     rate = -ancho .* ((local_temp .- opt_temp) .^ 2.0) .+ 1.0
#
#     plot(local_temp, rate, ylims = (0,1))
# end

# Normal vs exponential distributions, for wind dispersion
#histogram(rand(truncated(Normal(),0.0, Inf), 1000) .* 5, xlims=(0,25))
#histogram!(rand(Exponential(5),1000), alpha=0.3, bins = 50)

# histogram(abs.(2 .* randn(1000)))
# histogram!(rand(truncated(Normal(),0.0, Inf), 1000) .* 2, alpha = 0.3)
# histogram!(rand(truncated(Normal(0,2),0.0, Inf), 1000) .* 2, alpha = 0.3)

# Testing how it works with dataframes

# using Distributed
# @everywhere using DrWatson
# @everywhere @quickactivate "SpatialRust"
# @everywhere using DataFrames
# other_df = DataFrame(a = [1,2,3,10,11,12], b = [4,5,6,13,14,15], c = [7,8,9,16,17,18])
#
# @everywhere function testingmap(col)
#     println(col)
# end
#
# pmap(testingmap, eachrow(other_df))

# Output:

# DataFrameRow
# │ Row │ a     │ b     │ c     │
# │     │ Int64 │ Int64 │ Int64 │
# ├─────┼───────┼───────┼───────┤
# │ 1   │ 1     │ 4     │ 7     │
# DataFrameRow
# │ Row │ a     │ b     │ c     │
# │     │ Int64 │ Int64 │ Int64 │
# ├─────┼───────┼───────┼───────┤
# │ 2   │ 2     │ 5     │ 8     │
# DataFrameRow
# │ Row │ a     │ b     │ c     │
# │     │ Int64 │ Int64 │ Int64 │
# ├─────┼───────┼───────┼───────┤
# │ 3   │ 3     │ 6     │ 9     │
# DataFrameRow
# │ Row │ a     │ b     │ c     │
# │     │ Int64 │ Int64 │ Int64 │
# ├─────┼───────┼───────┼───────┤
# │ 4   │ 10    │ 13    │ 16    │
# DataFrameRow
# │ Row │ a     │ b     │ c     │
# │     │ Int64 │ Int64 │ Int64 │
# ├─────┼───────┼───────┼───────┤
# │ 5   │ 11    │ 14    │ 17    │
# DataFrameRow
# │ Row │ a     │ b     │ c     │
# │     │ Int64 │ Int64 │ Int64 │
# ├─────┼───────┼───────┼───────┤
# │ 6   │ 12    │ 15    │ 18    │

##
#= Now with the general observations by McCain (1984):
    - max radius of 1-1.5 cm -> max area is 3.14 to 7 cm^2. Assume 5 cm^2
 + exp data starts with size = 0.001

 => modelling relative areas (from 0 to 1). Need to divide exp data /5 to compare to model

 max area recorded in exp data is ~0.6 at age 7w (49 days). 0.6/5 = 0.12
=#

Pkg.activate(".")
using CairoMakie

g_r = 0.15
g_r = 0.4
snl = 24.0

days = collect(1:100)
sizes = zeros(length(days))
sizes[1] = 0.00014

for day in 2:length(days)
    sizes[day] = sizes[day - 1] + (g_r * sizes[day - 1] * (1.0 - sizes[day - 1]) * (1.0 - (snl + sizes[day - 1])/25.0)) #* temp_modif#* prod[day - 1]
    if sizes[day] < 0.0 #> 1.0
        sizes[day] = 0.0
    end

end

sizes[49]

lines(days, sizes)

local_temp = 20.0
temp_modif = (-0.0178 * ((local_temp - 22.5) ^ 2.0) + 1.0)
prod = [i / 365 for i in days] .+ 1
sizep = zeros(length(days))
sizep[1] = 0.0002

for day in 2:length(days)
    sizep[day] = sizep[day - 1] + (g_r * sizep[day - 1] * (1.0 - sizep[day - 1])) * prod[day - 1] * temp_modif
end

lines(days, sizep)

## Implementing Runge-Kutta to correct extreme changes. Then benchmark

function rungekutta()
    g_r = 3.1

    days = collect(1:100)
    size = zeros(length(days))
    size[1] = 0.0002

    growth_f(x) = x * (1.0 - x)
    # rk1(x, g_r) = growth_f(x, g_r)
    # rk2(x) = growth_f(x + growth_f(x) * 0.5)
    rk2(x,k1) = growth_f(x + k1 * 0.5)
    # rk3(x) = growth_f(x + rk2(x) * 0.5)
    rk3(x,k2) = growth_f(x + k2 * 0.5)
    # rk4(x) = growth_f(x + rk3(x))
    rk4(x,k3) = growth_f(x + k3)
    function appr_df(x, g_r)
        let k1 = growth_f(x), k2 = rk2(x, k1), k3 = rk3(x, k2), k4 = rk4(x, k3)
            return g_r * (k1 + 2k2 + 2k3 + k4) / 6
        end
    end

    for day in 2:length(days)
        size[day] = size[day - 1] + appr_df(size[day - 1], g_r)
    end
    return size
end

function maxone()
    g_r = 3.1

    days = collect(1:100)
    size = zeros(length(days))
    size[1] = 0.0002

    for day in 2:length(days)
        size[day] = size[day - 1] + (g_r * size[day - 1] * (1.0 - size[day - 1])) #* temp_modif#* prod[day - 1]
        if size[day] > 1.0
            size[day] = 1.0
        end
    end
    return size
end

function eqsol()
    g_r = 3.1

    days = collect(1:100)
    size = zeros(length(days))
    size[1] = 0.0002

    growth_f(x, g_r) =  (x * exp(g_r)) / (1 - x + (x * exp(g_r)))

    for day in 2:length(days)
        size[day] = size[day - 1] + growth_f(size[day - 1], g_r)
    end
    return size
end

using BenchmarkTools

@benchmark rungekutta() # ~2 µs

@benchmark maxone() # ~450 ns

@benchmark eqsol() #this one is incorrect (and slower than maxone)
