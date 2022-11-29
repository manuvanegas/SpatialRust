#=
This is an exploratory script, written to find the cause of a periodic dip
in rust severity that was seen in the mean of several runs.
Conclusion: the effect of the inspect function is not well calibrated to reality.
=#

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


###
## Isolated Rust fnctns and struct
###
struct modelStruct
    rain::Bool
    temperature::Float64
    temp_cooling::Float64
    fruit_load::Float64
    spore_pct::Float64
end

function r_acc_production!(cof::Coffee) # accumulate production
    cof.production += (cof.area / 25.0) * cof.sunlight
end

function r_parasitize!(rust::Rust, cof::Coffee, model::modelStruct, t::Int)

    #if rust.germinated
        # bal = rust.area + (rust.n_lesions / 25.0) # between 0.0 and 2.0
    # # cof.progression = 1 / (1 + (0.75 / bal)^4)
    #     prog = 1 / (1 + (0.25 / bal)^4) # Hill function with steep increase
    #     cof.area = 1.0 - prog
        cof.area = 25.0 - (t * rust.area)
        if cof.area <= 0.0 #|| bal >= 2.0
            cof.area = 0.0
            cof.exh_countdown = (182 * 2) + 1

            #rm_id = rust.id
            #kill_agent!(rust, model)
            #model.rust_ids = filter(i -> i != rm_id, model.rust_ids)
        end
    #end
end


function r_grow!(rust::Rust, cof::Coffee, model::modelStruct)

    local_temp = model.temperature - (model.temp_cooling * (1.0 - cof.sunlight))

    # if rust.germinated && 14 < local_temp < 30 # grow and sporulate

        #  logistic growth (K=1) * rate due to fruit load * rate due to temperature
        rust.area += rust.area * (1 - rust.area) *
            #(model.fruit_load * (1 / (1 + (30 / cof.production))^2)) *
            model.fruit_load * cof.production / 182 *
            (-0.0178 * ((local_temp - 22.5) ^ 2.0) + 1.0)

        if rust.spores === 0.0
            if rand() < (rust.area * (local_temp + 5) / 30) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
                rust.spores = rust.area * model.spore_pct
            end
        else
            rust.spores = rust.area * model.spore_pct
        end

    # else # try to germinate + penetrate tissue
    #     let r = rand()
    #         if r < (cof.sunlight * model.light_inh) || r <  (cof.sunlight * (model.rain ? model.rain_washoff : 0.0))
    #             # higher % sunlight means more chances of inactivation by UV or rain
    #             rm_id = rust.id
    #             kill_agent!(rust, model)
    #             model.rust_ids = filter(i -> i != rm_id, model.rust_ids)
    #         else
    #             if rand() < calc_wetness_p(local_temp - (model.rain ? 6.0 : 0.0))
    #                 rust.germinated = true
    #                 rust.area = 0.01
    #             end
    #         end
    #     end
    # end
end

###
##
###

function simplest()
    days = collect(1:30)
    size = zeros(length(days)+1)
    size[1] = 0.01
    local_temp = 22.5

    for day in 2:length(days)+1
        size[day] = size[day - 1] + 0.5 * (-0.0178 * ((local_temp - 22.5) ^ 2) + 1) * size[day - 1] * (1 - size[day - 1])
    end

    plot(days, size[2:31])
end




function create_and_run(time::Int64, reps::Int64)
    model = modelStruct(true, 22.5, 2.0, 1.0, 0.6)
    areas = Array{Float64, 2}(undef, time, reps)
    prod = Array{Float64, 2}(undef, time, reps)
    for r in 1:reps
        the_rust = Rust(r, (1,1), true, 0.01, 0.0, 1)
        the_coffee = Coffee(r+reps, (1,1), 25.0, 1.0, Int[], 0.0, 1.0, 0)

        for t in 1:time
            r_acc_production!(the_coffee)
            r_parasitize!(the_rust, the_coffee, model, t)
            r_grow!(the_rust, the_coffee, model)
            areas[t, r] = the_rust.area
            prod[t, r] = the_coffee.production
        end
    end
    return areas, prod
end

aa, pp = create_and_run(100,1)

plot(aa)
plot(pp)

###
## Using original functions

adata = [ind_area, ind_lesions, typeof]
mdata = [count_rusts, mean_rust_sev, mean_rust_sev_tot, rust_incid, mean_production, std_production]

function run_once_plot_severity(dims, steps)
    ii = initialize_sim(; map_dims=dims, shade_percent = 0.1, light_inh = 0.1, rain_washoff = 0.1)
    aadd, mmdd = run!(ii, pre_step!, agent_step!, model_step!, steps; adata = adata, mdata=mdata)
    return aadd, mmdd
end

run_once_plot_severity(10,10) # just to get Julia started

# agentd, modeld = run_once_plot_severity(100,500)
# rust_agents = filter(:typeof => x -> x == Rust, agentd)
#
# # length(unique(rust_agents.id))
#
# function nunique(a)
#     last = first(a)
#     n = 1
#     for x in a
#         if isless(last, x)
#             n += 1
#             last = x
#         end
#     end
#     n
# end
# nunique(rust_agents.id)
# #13215 with inspect
# #16994 no inspect
#
# first_rusts = filter(:id => id -> id < 10101, rust_agents)
# inspect_p_ind = plot(first_rusts.step, first_rusts.ind_area,
#     group = first_rusts.id, legend = false)
#
# no_inspect_p_mod = plot(modeld.step, modeld.mean_rust_sev_tot)


all_data = DataFrame()


# Need to check that inspect function is commented out
for rep in 1:10
    local _, modeldata = run_once_plot_severity(100, 500)
    modeldata.repetition = rep
    append!(all_data, modeldata)
end

plot(all_data.step, all_data.mean_rust_sev, group = all_data.repetition,
    legend = false)

agg_data = combine(groupby(all_data, :step), :mean_rust_sev_tot => mean => :sev_mean)
plot(agg_data.step, agg_data.sev_mean)


all_data_insp = DataFrame()

# Need to go back and include inspect function to see diff
for rep in 1:10
    local _, modeldata = run_once_plot_severity(100, 500)
    modeldata.repetition = rep
    append!(all_data_insp, modeldata)
end

plot(all_data_insp.step, all_data_insp.mean_rust_sev, group = all_data_insp.repetition,
    legend = false)

agg_data_insp = combine(groupby(all_data_insp, :step), :mean_rust_sev_tot => mean => :sev_mean)
plot(agg_data_insp.step, agg_data_insp.sev_mean)


#= Indeed inspect creates periodic dips in rust severity. Can be seen in mean
of 10 runs =#
