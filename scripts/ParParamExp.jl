using Distributed
addprocs(4)

@everywhere using DrWatson
@everywhere quickactivate("/Users/manuvanegasferro/Documents/ASU/Coffee Rust/SpatialRust", "SpatialRust")

@everywhere using Agents, CSV, DataFrames, Random, StatsBase, Statistics
@everywhere import Dates.now
#havent tested but equivalent to the version that worked in agave

# @everywhere using Pkg
# @everywhere Pkg.activate(".")
# @everywhere Pkg.instantiate()
# @everywhere using DrWatson
# @everywhere quickactivate(@__DIR__,"SpatialRust")
# @everywhere using Agents
# @everywhere using Random
# @everywhere using StatsBase
# @everywhere using Statistics
# @everywhere using DataFrames
# @everywhere using CSV
#@everywhere using DrWatson, Agents, CSV, DataFrames, Distributed, Random, StatsBase, Statistics

@everywhere include(srcdir("FarmInit.jl"))
@everywhere include(srcdir("ABMsim.jl"))
@everywhere include(srcdir("OneFarm.jl"))
@everywhere include(srcdir("AddToAgents.jl"))
@everywhere include(srcdir("ReportFncts.jl"))

param_scan = Dict(
    :map_dims => [20],
    :fragmentation => [true, false],
    :shade_percent => [0.1, 0.2, 0.3, 0.4, 0.5],
    :target_shade => [0.3, 0.6],
    :inspect_period => [7, 14, 30])

test_scan = Dict(:map_dims => [20, 30])

param_mdata = [
    count_rusts, rust_incid, mean_sev_tot, std_sev_tot,
    mean_production,std_production, :yield]

ad,md = paramscan(
    test_scan,
    initialize_sim;
    mdata = param_mdata,
    n = 200,
    pre_step! = pre_step!,
    agent_step! = agent_step!,
    model_step! = model_step!,
    replicates = 2,
    parallel = true)
