@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"

@everywhere using Agents, CSV, DataFrames, Random, Distributed, Distributions, StatsBase

@everywhere begin
    include(srcdir("FarmInit.jl"))
    include(srcdir("ABMsim.jl"))
    include(srcdir("OneFarm.jl"))
    include(srcdir("AddToAgents.jl"))
    #include((srcdir("ReportFncts.jl"))
    include(srcdir("ABCrun.jl"))
end

startat = 2
less_this = 0

if length(ARGS) > 1
    startat = parse(Int, ARGS[2]) + 1
    less_this = parse(Int, ARGS[3])
end

parameters = CSV.read(datadir("ABC", ARGS[1]), DataFrame, skipto = startat, footerskip = less_this)

when_collect_csv = CSV.read(datadir("exp_pro/inputs/whentocollect_sun.csv"), DataFrame)
when_collect = Array{Int}(when_collect_csv[:, :x])

# read climate data
weather = CSV.read(datadir("exp_pro/inputs/Tur_Sun_Weather.csv"), DataFrame, footerskip = 1)
#weather[456, :meanTaTFS] = 23.0 # fix last temp value
rain_data = Array{Bool}(weather[:, :Rainy])
temp_data = Array{Float64}(weather[:, :meanTaTFS])

out_path = mkpath("/scratch/mvanega1/ABCveryraw")

#dummy run
d_mod = initialize_sim(; map_dims = 10, shade_percent = 0.0)
d_adata, _ = run!(d_mod, pre_step!, agent_step!, model_step!, 10, adata = [:pos])

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
