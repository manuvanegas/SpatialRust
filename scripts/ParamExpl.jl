
## this is just for the first time
# cd("/Users/manuvanegasferro/Documents/ASU/Coffee Rust/SpatialRust/")
# using Pkg
# Pkg.activate(".")
# Pkg.instantiate()
## I think

using DrWatson
@quickactivate "SpatialRust"

using Agents, CSV, DataFrames, Distributed, Random, StatsBase, Statistics
# import Dates.now

include(srcdir("FarmInit.jl"))
include(srcdir("ABMsim.jl"))
include(srcdir("OneFarm.jl"))
include(srcdir("AddToAgents.jl"))
include(srcdir("ReportFncts.jl"))


test_scan = Dict(:map_dims => [20, 30])


adata = [ind_area, ind_lesions]
mdata = [count_rusts, mean_rust_sev, mean_rust_sev_tot, rust_incid, mean_production, std_production]
mdata = [
    count_rusts, rust_incid, mean_sev, std_sev, mean_sev_tot, std_sev_tot,
    mean_production,std_production, mean_sunlight, std_sunlight,
    :yield, mean_r_area, mean_r_lesions, mean_r_prog, mean_ctdn]

param_mdata = [
    count_rusts, rust_incid, mean_sev_tot, std_sev_tot,
    mean_production, std_production, :yield]

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

# ii = initialize_sim(; fruit_load = 1.2, map_dims=50, shade_percent = 0.1, light_inh = 0.1, rain_washoff = 0.1)
# aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, 911; adata = adata, mdata=new_mdata)

function init_and_run(dims, steps)
    ii = initialize_sim(; map_dims=dims, shade_percent = 0.1, light_inh = 0.1, rain_washoff = 0.1)
    aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, steps; adata = adata, mdata=mdata)
end


# using Plots
# @df aadd plot(:step, :ind_area, group = :id, legend = false)
# @df aadd plot(:step, :ind_lesions, group = :id, legend = false)
# plot(mmdd.step, mmdd.mean_rust_sev_tot, xlims=(100,200))


function this()
    cn=0
    for i = 1:400
        if length(get_node_agents(i,ii)) == 1
            cn += 1
        end
    end
    return cn
end
