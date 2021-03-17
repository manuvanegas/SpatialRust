using DrWatson
@quickactivate "SpatialRust"

using Agents, CSV, DataFrames, Random, StatsPlots, StatsBase, Statistics
# import Dates.now
# using Interact

include(srcdir("FarmInit.jl"))
include(srcdir("ABMsim.jl"))
include(srcdir("OneFarm.jl"))
include(srcdir("AddToAgents.jl"))
include(srcdir("ReportFncts.jl"))

adata = [ind_area, ind_lesions, typeof]
mdata = [count_rusts, mean_rust_sev, mean_rust_sev_tot, rust_incid, mean_production, std_production]

function run_once_plot_severity(dims, steps)
    ii = initialize_sim(; map_dims=dims, shade_percent = 0.1, uv_inact = 0.1, rain_washoff = 0.1)
    aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, steps; adata = adata, mdata=mdata)
    return aadd, mmdd
end

run_once_plot_severity(10,10) # just to get Julia started

all_data = DataFrame()


# Need to check that inspect function is commented out
for rep in 1:10
    local _, modeldata = run_once_plot_severity(100, 500)
    modeldata.repetition = rep
    append!(all_data, modeldata)
end

ori_data = all_data[1:5010, :] #original was new leaf area = sunlight
mod_data = all_data[5011:10020, :] #modified means using new leaf area = area * sunlight

plot(mod_data.step, mod_data.mean_rust_sev, group = mod_data.repetition,
    legend = false)

plot(mod_data.step, mod_data.rust_incid, group = mod_data.repetition,
    legend = false)

plot(ori_data.step, ori_data.mean_rust_sev, group = ori_data.repetition,
    legend = false)

plot(ori_data.step, ori_data.rust_incid, group = ori_data.repetition,
    legend = false)

agg_ori_data = combine(groupby(ori_data, :step), [:mean_rust_sev_tot => mean => :sev_mean, :rust_incid => mean => :incid_mean])
plot(agg_ori_data.step, agg_ori_data.sev_mean)
plot(agg_ori_data.step, agg_ori_data.incid_mean)

agg_mod_data = combine(groupby(mod_data, :step), [:mean_rust_sev_tot => mean => :sev_mean, :rust_incid => mean => :incid_mean])
plot(agg_mod_data.step, agg_mod_data.sev_mean)
plot(agg_ori_data.step, agg_ori_data.incid_mean)
