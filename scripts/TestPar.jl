@everywhere using DrWatson
@everywhere quickactivate("/home/mvanega1/SpatialRust/", "SpatialRust")


@everywhere using Agents, CSV, DataFrames, Distributed, Random, StatsBase, Statistics

@everywhere include(srcdir("FarmInit.jl"))
@everywhere include(srcdir("ABMsim.jl"))
@everywhere include(srcdir("OneFarm.jl"))
@everywhere include(srcdir("AddToAgents.jl"))
@everywhere include(srcdir("ReportFncts.jl"))

pmap(i -> println("I'm worker $(myid()), working on i=$i"), 1:10)

@everywhere printsquare(i) = println("working on i=$i: its square it $(i^2)")
@sync @distributed for i in 1:10
  printsquare(i)
end

