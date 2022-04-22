Pkg.activate(".")
using Agents, DrWatson, Random
using Statistics: median, mean
@time using Revise

include(projectdir("SpatialRust.jl"))
using .SpatialRust

# tmodel = SpatialRust.init_spatialrust(Parameters(), SpatialRust.create_fullsun_farm_map())
tmodel = justtwosteps()
SpatialRust.step_model!(tmodel)

# tnl = getproperty.((tmodel[id] for id in tmodel.current.rust_ids), :n_lesions)
# trusts = collect(tmodel[id] for id in tmodel.current.rust_ids)
# trusted = collect(tmodel[cid] for cid in getproperty.((tmodel[rid] for rid in tmodel.current.rust_ids), :hg_id))
# trareas = getproperty.(trusted, :area)

# median(getproperty.((tmodel[id] for id in tmodel.current.coffee_ids), :area))
# maximum(getproperty.(trusts,:spores))
# maximum.(getproperty.(trusts,:area))


# dm_adf, dm_mdf = dummyrun_spatialrust(10, 100)

tadf, tmdf = dummyrun_spatialrust(10, 100, 10)

using BenchmarkTools
Random.seed!(1234)
@btime a, m = dummyrun_spatialrust(500, 100, 25)


maxlesions = [1, 5, 10, 25, 50]
medians = []
mins = []
for (i, nl) in enumerate(maxlesions)
    t = @benchmark dummyrun_spatialrust(500, 100, $nl)
    println(nl)
    push!(medians, median(t))
    push!(mins, minimum(t))
end

@benchmark nlesions_spatialrust(500, 100, 1)

tadf, tmdf = nlesions_spatialrust(500, 100, 50)


# Juno.@profiler dummyrun_spatialrust(10, 100) #doesnt run (too many things happenning?)

ttmodel = init_spatialrust(Parameters(map_side = 100, max_lesions = 25), SpatialRust.create_fullsun_farm_map())
for i in 1:50
    SpatialRust.step_model!(ttmodel)
end

@time SpatialRust.step_model!(ttmodel)

using Profile
Profile.init()
Profile.init(n = 10^9)

Juno.@profiler for i in 1:2
    for rust_i in shuffle(ttmodel.rng, ttmodel.current.rust_ids)
        SpatialRust.rust_step!(ttmodel, ttmodel[rust_i], ttmodel[ttmodel[rust_i].hg_id])
    end
    # println("hi")
end

Juno.@profiler for i in 1:3
    SpatialRust.step_model!(ttmodel)
end

#type of median(t) is BenchmarkTools.TrialEstimate
#=
median(t)
BenchmarkTools.TrialEstimate:
  time:             30.818 μs
  gctime:           0.000 ns (0.00%)
  memory:           16.36 KiB
  allocs:           19
  =#

using Plots
plot(maxlesions, getproperty.(medians, :time), title = "time")
plot(maxlesions, getproperty.(medians, :gctime), title = "gctime")
plot(maxlesions, getproperty.(medians, :memory), title = "memory")

# medians[1]
# medians[4]
# medians[5]
#
# medians[1]
# medians[4]
# medians[5]
#
# # wo let
# medians[1]
# medians[4]
# medians[5]
#

#=
with @inbounds:
BenchmarkTools.TrialEstimate:
  time:             880.036 ms
  gctime:           32.643 ms (3.71%)
  memory:           464.74 MiB
  allocs:           22376915

  BenchmarkTools.TrialEstimate:
    time:             63.145 s
    gctime:           267.468 ms (0.42%)
    memory:           2.36 GiB
    allocs:           49575486

    BenchmarkTools.TrialEstimate:
      time:             118.795 s
      gctime:           386.945 ms (0.33%)
      memory:           3.77 GiB
      allocs:           61877902
=#

 # there is also a BenchmarkPlots. plot(t) shows timing results as violin plot
