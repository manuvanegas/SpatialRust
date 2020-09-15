using DrWatson
@quickactivate "SpatialRust"

using Pkg
cd("/Users/manuvanegasferro/Documents/ASU/Coffee Rust/SpatialRust/")
Pkg.activate(".")
Pkg.instantiate()

using Distributed
addprocs(4; exeflags="--project")

@everywhere using Agents
# @everywhere

# @everywhere
@everywhere cd("/Users/manuvanegasferro/Documents/ASU/Coffee Rust/SpatialRust")
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere Pkg.instantiate()
@everywhere using DrWatson
@everywhere quickactivate(@__DIR__,"SpatialRust")
@everywhere using Agents, Random, StatsBase, Statistics, DataFrames, CSV

@everywhere include(srcdir("FarmInit.jl"))
@everywhere include(srcdir("ABMsim.jl"))
@everywhere include(srcdir("OneFarm.jl"))
@everywhere include(srcdir("AddToAgents.jl"))
@everywhere include(srcdir("ReportFncts.jl"))



param_scan = Dict(
    :dims => [20],
    :fragmentation => [true, false],
    :shade_percent => [0.1, 0.2, 0.3, 0.4, 0.5],
    :target_shade => [0.3, 0.6],
    :inspect_period => [7, 14, 30])







adata = [ind_area, ind_lesions]
mdata = [count_rusts, mean_rust_sev, mean_rust_sev_tot, rust_incid, mean_production, std_production]
mdata = [
    count_rusts, rust_incid, mean_sev, std_sev, mean_sev_tot, std_sev_tot,
    mean_production,std_production, mean_sunlight, std_sunlight,
    :yield, mean_r_area, mean_r_lesions, mean_r_prog, mean_ctdn]

param_mdata = [
    count_rusts, rust_incid, mean_sev_tot, std_sev_tot,
    mean_production,std_production, :yield]

ad,md = paramscan(
    param_scan,
    initialize_sim;
    mdata = param_mdata,
    n = 200,
    pre_step! = pre_step!,
    agent_step! = agent_step!,
    model_step! = model_step!,
    replicates = 2,
    parallel = true)

ii = initialize_sim(; fruit_load = 1.2, map_dims=50, shade_percent = 0.1, uv_inact = 0.1, rain_washoff = 0.1)
aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, 911; adata = adata, mdata=new_mdata)

function init_and_run(dims, steps)
    ii = initialize_sim(; map_dims=dims, shade_percent = 0.1, uv_inact = 0.1, rain_washoff = 0.1)
    aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, steps; adata = adata, mdata=new_mdata)
end


step!(ii, pre_step!, agent_step!, model_step!)


@df aadd plot(:step, :ind_area, group = :id, legend = false)
@df aadd plot(:step, :ind_lesions, group = :id, legend = false)


count(length(get_node_agents.(1:20,ii)) > 2)
function this()
    cn=0
    for i = 1:400
        if length(get_node_agents(i,ii)) == 1
            cn += 1
        end
    end
    return cn
end
