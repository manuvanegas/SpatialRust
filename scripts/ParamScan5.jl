@everywhere using DrWatson
@everywhere quickactivate("/home/mvanega1/SpatialRust/", "SpatialRust")
    
@everywhere using Agents, CSV, DataFrames, Distributed, Random, StatsBase, Statistics
@everywhere import Dates.now
#using BSON

@everywhere include(srcdir("FarmInit.jl"))
@everywhere include(srcdir("ABMsim.jl"))
@everywhere include(srcdir("OneFarm.jl"))
@everywhere include(srcdir("AddToAgents.jl"))
@everywhere include(srcdir("ReportFncts.jl"))

param_scan = Dict(
    :map_dims => [100],
    :fragmentation => [true, false],
    :shade_percent => [0.5],
    :target_shade => [0.3, 0.6],
    :inspect_period => [7, 14, 30])

test_scan = Dict(:map_dims => [20, 30])

param_mdata = [
    count_rusts, rust_incid, mean_sev_tot, std_sev_tot,
    mean_production,std_production, :yield]

@unpack map_dims, fragmentation, shade_percent, target_shade, inspect_period = param_scan
mkpath("/scratch/mvanega1/track05")
o_name = string("md-", shade_percent[1], ".csv")
b_name = string("md-", shade_percent[1], ".bson")

ad,md = paramscan(
    param_scan,
    initialize_sim;
    mdata = param_mdata,
    n = 910,
    pre_step! = pre_step!,
    agent_step! = agent_step!,
    model_step! = model_step!,
    replicates = 75,
    parallel = true)

CSV.write(projectdir("results", o_name), md)
#save(projectdir("results", b_name), md)

#cp(string("/scratch/mvanega1/", scratch_name), string("/home/mvanega1/SpatialRust/results/", scratch_name))
#rm(string("/scratch/mvanega1/", scratch_name), recursive = true)
