Pkg.activate(".")
using Agents, DrWatson
using Statistics: median, mean

include(projectdir("SpatialRust.jl"))
using .SpatialRust

tpars = Parameters(steps = 50, map_side = 60, max_lesions = 25)
tmodel = init_spatialrust(tpars, Main.SpatialRust.create_fullsun_farm_map())

tnl = getproperty.((tmodel[id] for id in tmodel.current.rust_ids), :n_lesions)
trusts = collect(tmodel[id] for id in tmodel.current.rust_ids)
trusted = collect(tmodel[cid] for cid in getproperty.((tmodel[rid] for rid in tmodel.current.rust_ids), :hg_id))
trareas = getproperty.(trusted, :area)

step!(tmodel, dummystep, Main.SpatialRust.step_model!,1)

tmodel[1815]

tmempt = collect(agents_in_position((43,27),tmodel))

eltype(tmempt) == Vector{A} where {A <: AbstractAgent}

function telfun(v::Vector{A}) where {A <: AbstractAgent}
    print(v[1])
end

function telfun2(v::Vector{AbstractAgent})
    print(v[1])
end

median(getproperty.((tmodel[id] for id in tmodel.current.coffee_ids), :area))

maximum.(getproperty.(trusts,:spores))
maximum.(getproperty.(trusts,:area))


dm_adf, dm_mdf = dummyrun_spatialrust(10)

dummyrun_spatialrust(500, 100)

using BenchmarkTools
maxlesions = [2, 5, 10, 25, 50, 100]
medians = []
for (i, nl) in enumerate(maxlesions)
    t = @benchmark nlesions_spatialrust(500, 100, $nl)
    println(nl)
    push!(medians, median(t))
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
plot(maxlesions, getproperty.(medians[:], :time), title = "time")
plot(maxlesions, getproperty.(medians[:], :gctime), title = "gctime")
plot(maxlesions, getproperty.(medians[:], :memory), title = "memory")


 # there is also a BenchmarkPlots. plot(t) shows timing results as violin plot
