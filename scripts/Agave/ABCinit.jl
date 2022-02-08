@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"

@everywhere begin
    using DataFrames
    using Agents: dummystep, run!
    using Distributed: pmap
    using CSV: read as crd
    include(projectdir("SpatialRust.jl"))
    #using .SpatialRust
end

startat = 2
less_this = 0

if length(ARGS) > 1
    startat = parse(Int, ARGS[2]) + 1
    less_this = parse(Int, ARGS[3])
end

when_collect = crd(datadir("exp_pro/inputs/sun_whentocollect_rust.csv"), DataFrame, select = [false, true])[!, 1]
when_cycle = crd(datadir("exp_pro/inputs/sun_whentocollect_plant.csv"), DataFrame, select = [false, true])[!, 1]

# read climate data
weather = crd(datadir("exp_pro/inputs/sun_weather.csv"), DataFrame)
rain_data = Vector{Bool}(weather[!, :Rainy])
temp_data = Vector{Float64}(weather[!, :meanTaTFS])

parameters = crd(datadir("ABC", ARGS[1]), DataFrame, skipto = startat, footerskip = less_this)

out_path = mkpath("/scratch/mvanega1/ABCveryraw")
mkpath("/scratch/mvanega1/ABCveryraw/stepdata")
mkpath("/scratch/mvanega1/ABCveryraw/substepdata")
mkpath("/scratch/mvanega1/ABCveryraw/cycledata")

#dummy run
d_mod = initialize_sim(; map_dims = 20, shade_percent = 0.0, steps = 50)
d_adata, _ = run!(d_mod, dummystep, step_model!, 50, adata = [:pos])

println("Dummy run completed")

processed = pmap(p -> run_for_abc(p, rain_data, temp_data, when_collect, out_path),
                eachrow(parameters); retry_delays = fill(0.1, 3))



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
