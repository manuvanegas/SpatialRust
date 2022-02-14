using CSV: write as cwrt
using Statistics: median

## Sampler struct and functions
struct Sampler
    cycle::Vector{Int}
    #initial_list::Vector{Coffee}
    all_cofs::Array{Int}
    all_rusts::Array{Int}
    #current_cofs::Vector{Int}
    # current_rusts::Vector{Int}
end

function coffee_sampling(model::ABM)
    sampled_cof_ids = zeros(Int, 405, 11)
    sampled_rust_ids = zeros(Int, 405, 11)
    central_coffees = collect(Iterators.filter(a -> all(5 .< a.pos .<= 95) & isa(a, Coffee), allagents(model)))
    sampled_coffees::Vector{Coffee} = central_coffees[sample(model.rng, 1:8100, 810, replace = false)]

    for (i, c) in enumerate(sampled_coffees)

        if i <= 405
            sampled_cof_ids[i, 1] = c.id
            #sampled_rust_ids[i, 1] = c.hg_id
            let s_cycle = 2
                for neigh::Coffee in shuffle(model.rng, collect(Iterators.filter(n -> isa(n, Coffee), nearby_agents(c, model))))
                    if s_cycle == 5
                        break
                    elseif neigh.id ∉ sampled_cof_ids
                        sampled_cof_ids[i, s_cycle] = neigh.id
                        #sampled_rust_ids[i, s_cycle] = neigh.hg_id
                        s_cycle += 1
                    end
                end
                if s_cycle != 5
                    for neigh::Coffee in collect(Iterators.filter(n -> isa(n, Coffee), nearby_agents(c, model, 2)))
                        if s_cycle == 5
                            break
                        elseif neigh.id ∉ sampled_cof_ids
                            sampled_cof_ids[i, s_cycle] = neigh.id
                            #sampled_rust_ids[i, s_cycle] = neigh.hg_id
                            s_cycle += 1
                        end
                    end
                end
            end
        elseif i <= 608
            sampled_cof_ids[i - 405, 5:6] .= c.id
            #sampled_rust_ids[i - 405, 5:6] .= c.hg_id
            let s_cycle = 7
                for neigh::Coffee in shuffle(model.rng, collect(Iterators.filter(n -> isa(n, Coffee), nearby_agents(c, model))))
                    if s_cycle > 11
                        break
                    elseif neigh.id ∉ sampled_cof_ids
                        if s_cycle == 11
                            sampled_cof_ids[i - 405, s_cycle] = neigh.id
                            #sampled_rust_ids[i - 405, s_cycle] = neigh.hg_id
                            s_cycle += 1
                            break
                        else
                            sampled_cof_ids[i - 405, s_cycle:s_cycle + 1] .= neigh.id
                            #sampled_rust_ids[i - 405, s_cycle:s_cycle + 1] .= neigh.hg_id
                            s_cycle += 2
                        end
                    end
                end
                if !(s_cycle > 11)
                    for neigh::Coffee in collect(Iterators.filter(n -> isa(n, Coffee), nearby_agents(c, model, 2)))
                        if s_cycle > 11
                            break
                        elseif neigh.id ∉ sampled_cof_ids
                            if s_cycle == 11
                                sampled_cof_ids[i - 405, s_cycle] = neigh.id
                                #sampled_rust_ids[i - 405, s_cycle] = neigh.hg_id
                                s_cycle += 1
                                break
                            else
                                sampled_cof_ids[i - 405, s_cycle:s_cycle + 1] .= neigh.id
                                #sampled_rust_ids[i - 405, s_cycle:s_cycle + 1] .= neigh.hg_id
                                s_cycle += 2
                            end
                        end
                    end
                end
            end
        else
            sampled_cof_ids[i - 405, 6:7] .= c.id
            #sampled_rust_ids[i - 405, 6:7] .= c.hg_id
            let s_cycle = 8
                for neigh::Coffee in shuffle(model.rng, collect(Iterators.filter(n -> isa(n, Coffee), nearby_agents(c, model))))
                    if s_cycle > 11
                        break
                    elseif neigh.id ∉ sampled_cof_ids
                        sampled_cof_ids[i - 405, s_cycle:s_cycle + 1] .= neigh.id
                        #sampled_rust_ids[i - 405, s_cycle:s_cycle + 1] .= neigh.hg_id
                        s_cycle += 2
                    end
                end
                if !(s_cycle > 11)
                    for neigh::Coffee in collect(Iterators.filter(n -> isa(n, Coffee), nearby_agents(c, model, 2)))
                        if s_cycle > 11
                            break
                        elseif neigh.id ∉ sampled_cof_ids
                            sampled_cof_ids[i - 405, s_cycle:s_cycle + 1] .= neigh.id
                            #sampled_rust_ids[i - 405, s_cycle:s_cycle + 1] .= neigh.hg_id
                            s_cycle += 2
                        end
                    end
                end
            end
        end
    end

    return Sampler([1], sampled_cof_ids, Int[])
end

function update_r_sampling!(model::ABM, sampler::Sampler)
    empty!(sampler.all_rusts)
    for c in filter(id -> id > 0, sampler.all_cofs[:, sampler.cycle[1]])
        rust_id = model[c].hg_id
        if rust_id !== 0 && rust_id ∈ model.current.rust_ids
            push!(sampler.all_rusts, rust_id)
        end
    end
end



## Report functions

# Helpers

# function myf(a::Int, one::Vector{Int})
#     println(a)
#     isthis = a < 5
#     println(isthis)
#     function thef(x)
#         if isthis
#             return x * one[1]
#         else
#             println("hi")
#             return x ^ one[3]
#         end
#     end
#
#     return thef
# end

function appr_area(a::Rust)::Float64
    return a.area * a.n_lesions
end

function area_age(a::Rust)::Vector{Float64}
    return [a.area::Float64, round(a.age::Int / 7.0)]
end

# Functions using Sampler
function fallen_pct(model::ABM, sampler::Sampler)::Float64
    let current_c_sampling = filter(id -> id > 0, sampler.all_cofs[:, sampler.cycle[1]])
        return length(collect(Iterators.filter(i -> model[i].exh_countdown > 0, current_c_sampling))) / length(current_c_sampling)
    end
end

function fallen_pct(model::ABM)::Float64
    0.0
end

function med_appr_area(model::ABM, sampler::Sampler)::Float64
    let current_r_sampling = sampler.all_rusts
        if isempty(current_r_sampling)
            return 0.0
        else
            return median(map(i -> appr_area(model[i]::Rust), current_r_sampling))
        end
    end
end

function med_appr_area(model::ABM)::Float64
    0.0
end

function area_age(model::ABM, sampler::Sampler)::Array{Float64}
    # raw_areas = Float64[]
    # raw_ages = Int[]
    # med_areas = Float64[]
    # found_ages = Int[]

    let current_r_sampling = sampler.all_rusts
        if isempty(current_r_sampling)
            return [-1.0, -1.0]
        else
            raw_areas = reduce(hcat, map(i -> area_age(model[i]::Rust), current_r_sampling))
            areas = Array{Float64}(undef, 2, length(unique(raw_areas[2,:])))
            for (i, age) in enumerate(sort(unique(raw_areas[2,:])))
                areas[1, i] = median(getindex(raw_areas[1, :], raw_areas[2, :] .== age))
                areas[2, i] = age
                # push!(med_areas, median(raw_areas[raw_ages .== age]))
                # push!(found_ages, age)
            end
            return areas
        end
    end
end

function area_age(model::ABM)::Float64
    0.0
end

function age(model::ABM, sampler::Sampler)::Nothing
    # let current_r_sampling = filter(id -> id > 0, sampler.all_rusts[:, sampler.cycle[1]])
    #     if isempty(current_r_sampling)
    #         return 0
    #     elseif length(current_r_sampling) == 1
    #         area_age!(model.agents[current_r_sampling[1]])
    #         return raw_ages
    #     else
    #         return found_ages
    #     end
    # end
    nothing
end

function age(model::ABM)::Float64
    0.0
end

function med_cof_prod(model::ABM, sampler::Sampler)::Float64
    let current_c_sampling = #if sampler.cycle[1] == 0
            #filter(id -> id > 0, sampler.all_cofs[:, 1])
        #else
            filter(id -> id > 0,
                sampler.cycle[1] < 5 ? sampler.all_cofs[:, sampler.cycle[1]] :
                isodd(sampler.cycle[1]) ? sampler.all_cofs[1:203, sampler.cycle[1]] :
                sampler.all_cofs[204:405, sampler.cycle[1]])
        #end

    #sampler.cycle[1] += 1
    return median(map(i -> model[i].production, current_c_sampling))
    end
end

function med_cof_prod(model::ABM)::Float64
    return 0.0
end

# Closure generators (each step, a function is generated that uses the current sampling ids)

# function report_step_data(model::ABM; sampler::Sampler)
#     # s_c_ids::Vector{Int} = sampled_cof_ids
#     # s_r_ids::Vector{Int} = sampled_rust_ids
#
#     if sampler.cycle[1] == 0
#         current_c_sampling = filter(id -> id > 0, sampler.all_cofs[:, 1])
#         current_r_sampling = filter(id -> id > 0, sampler.all_rusts[:, 1])
#     else
#         current_c_sampling = filter(id -> id > 0, sampler.all_cofs[:, sampler.cycle[1]])
#         current_r_sampling = filter(id -> id > 0, sampler.all_rusts[:, sampler.cycle[1]])
#     end
#
#     fallen_pct = let current_c_sampling = current_c_sampling
#         function fallen_pct(model::ABM)::Float64
#             length(collect(Iterators.filter(i -> model[i].exh_countdown::Int > 0, current_c_sampling))) / length(current_c_sampling)
#         end
#     end
#     med_appr_area = let current_r_sampling = current_r_sampling
#         if isempty(current_r_sampling)
#             med_appr_area(model::ABM)::Float64 = 0.0
#         elseif length(current_r_sampling) == 1
#             function med_appr_area2(model::ABM)::Float64
#                 appr_area(model[current_r_sampling[1]]::Rust)
#             end
#         else
#             function med_appr_area3(model::ABM)::Float64
#                 median(map(i -> appr_area(model[i]::Rust), current_r_sampling))
#             end
#         end
#     end
#
#     return [fallen_pct, med_appr_area]
#
#
# # these functions were used for agent_df
#     #         return agent.id ∈ s_c_ids[406:810]
#     #     end
#     # end
#     # current_c_ids(agent::Rust) = false
#     # current_c_ids(agent::Shade) = false
#     #
#     #
#     # function current_r_ids(agent::Rust)::Bool
#     #     if model.ticks <= 230
#     #         return agent.id ∈ s_r_ids[1:405]
#     #     else
#     #         return agent.id ∈ s_r_ids[406:810]
#     #     end
#     # end
#     # current_r_ids(agent::Coffee) = false
#     # current_r_ids(agent::Shade) = false
#
#     # function cof_fallen(agent::Coffee)::Bool
#     #     return agent.exh_countdown > 0
#     # end
#
#     # function rust_appr(agent::Rust)::NTuple{2, Float64}
#     #     return agent.area, Float64(agent.n_lesions)
#     # end
#     #
#     # function area_age()
#     # end
#     #
#     # function medarea(rusts::Vector{NTuple{2, Float64}})
#     #     if isempty(rusts)
#     #         return missing
#     #     elseif length(rusts) == 1
#     #         return reduce(*,rusts)
#     #     else
#     #         return median(reduce.(*, rusts))
#     #     end
#     # end
#     #
#     # # function pct(cofs::Vector{Bool})::Float64
#     # #     return sum(cofs)/length(cofs)
#     # # end
#     #
#     # function cof_prod()
#     # end
#
#     # function iscentral(agent)
#     #     return all(5 .< agent.pos .<= 95)
#     # end
#     #
#     # function rust_lesions(agent)
#     #     return agent isa Rust ? agent.n_lesions : -1
#     # end
#     #
#     # function rust_area(agent)
#     #     return agent isa Rust ? agent.area : -1.0
#     # end
#     #
#     # function a_age(agent)
#     #     return agent.age
#     # end
#     #
#     # function coffee_prod(agent)
#     #     return agent isa Coffee ? agent.production : -1.0
#     # end
#     #
#     # function host_guest(agent)
#     #     return agent.hg_id
#     # end
#     #
#     # function x_pos(agent)
#     #     return agent.pos[1]
#     # end
#     #
#     # function y_pos(agent)
#     #     return agent.pos[2]
#     # end
#
# end
#
# function report_substep_data(model::ABM; sampler::Sampler)
#     if sampler.cycle[1] == 0
#         current_r_sampling = filter(id -> id > 0, sampler.all_rusts[:, 1])
#     else
#         current_r_sampling = filter(id -> id > 0, sampler.all_rusts[:, sampler.cycle[1]])
#     end
#     raw_areas = Float64[]
#     raw_ages = Int[]
#     med_areas = Float64[]
#     found_ages = Int[]
#
#     function med_area_age(model::ABM)::Vector{Float64}
#         med_areas = let current_r_sampling = current_r_sampling
#             if isempty(current_r_sampling)
#                 return 0.0
#             elseif length(current_r_sampling) == 1
#                 area_age!(model.agents[current_r_sampling[1]], raw_areas, raw_ages)
#                 return raw_areas
#             else
#                 map(i -> area_age!(model[i]::Rust, raw_areas, raw_ages), current_r_sampling)
#                 for age in sort(unique(raw_ages))
#                     push!(med_areas, median(raw_areas[raw_ages .== age]))
#                     push!(found_ages, age)
#                 end
#                 return med_areas
#             end
#         end
#     end
#
#     function ages(model::ABM)::Vector{Int}
#         if isempty(current_r_sampling)
#             return 0
#         elseif length(current_r_sampling) == 1
#             area_age!(model.agents[current_r_sampling[1]])
#             return raw_ages
#         else
#             return found_ages
#         end
#     end
#
#
#     return [med_area_age, ages]
# end
#
# function report_cycle_data(model::ABM; sampler::Sampler)
#     if sampler.cycle[1] == 0
#         current_c_sampling = filter(id -> id > 0, sampler.all_cofs[:, 1])
#     else
#         current_c_sampling = filter(id -> id > 0,
#                         sampler.cycle[1] < 5 ? sampler.all_cofs[:, sampler.cycle[1]] :
#                             isodd(sampler.cycle[1]) ? sampler.all_cofs[1:203, sampler.cycle[1]] :
#                             sampler.all_cofs[204:405, sampler.cycle[1]])
#     end
#
#     function med_cof_prod(model::ABM)::Float64
#         return median(map(i -> model[i].production, current_c_sampling))
#     end
#
#
#     sampler.cycle[1] += 1
#
#     return [med_cof_prod]
# end
## plant selection function

# function plant_sampler(df::DataFrame)
#     xy_pos = unique(df[(df.agent_type .== "Coffee") .& (5 .< df.x_pos .<= 95) .& (5 .< df.y_pos .<= 95), [:x_pos, :y_pos, :id]])
#     # sample size is 10% of coffees within the 5-row limit (= 810)
#     # times 2 because of the new sampling in Jan
#     selected_ids = sample(xy_pos.id, 1620, replace = false)
#     first_half = selected_ids[1:810]
#     second_half = selected_ids[811:end]
#     sampled = df[(df.step .<= 230) .& ((df.id .∈ Ref(first_half)) .| (df.host_guest .∈ Ref(first_half))), :]
#     append!(sampled, df[(df.step .> 230) .& ((df.id .∈ Ref(second_half)) .| (df.host_guest .∈ Ref(second_half))), :])
#     return sampled
# end

## ABC distance functions
# 1. nlesions, area, prod, both plant sets

# 2. nlesions, area, prod, second plant set only (2018)

# 3. nlesions * area, prod, both sets

# 4. nlesions * area, prod, second set

# 5. same but without prod

function calc_ABC_distances(args)
    body
end



## Run fnc

function run_for_abc(parameters::DataFrameRow,
    rain_data::Vector{Bool},
    temp_data::Vector{Float64},
    when_collect::Vector{Int},
    when_cycle::Vector{Int},
    out_path::String)

    b_map = trues(100, 100)
    #emp_data = true
    steps = length(rain_data)

    model = initialize_sim(; steps = steps, map_dims = 100, shade_percent = 0.0,
    harvest_cycle = 365, start_at = 132, n_rusts = 100,
    farm_map = b_map, rain_data = rain_data, temp_data = temp_data,
    #emp_data = emp_data,
    opt_g_temp = parameters[:opt_g_temp],
    spore_pct = parameters[:spore_pct],
    fruit_load = parameters[:fruit_load],
    uv_inact = parameters[:uv_inact],
    rain_washoff = parameters[:rain_washoff],
    rain_distance = parameters[:rain_distance],
    wind_distance = parameters[:wind_distance])

    #areport = [agent_type, a_age, rust_area, rust_lesions, coffee_prod, x_pos, y_pos, host_guest]

    sampler = coffee_sampling(model)

    stepdata, substepdata, cycledata = custom_abc_run!(model, dummystep, step_model!, steps;
                    when = when_collect, when_cycle = when_cycle,
                    stepdata = [fallen_pct, med_appr_area],
                    substepdata = [area_age, age],
                    cycledata = [med_cof_prod],
                    sampler = sampler)
                    #cat ABC-9488559.o | wc -l

    #distance_metrics = calc_ABC_distances(adata)

    insertcols!(stepdata, :par_row => parameters[:RowN])
    insertcols!(substepdata, :par_row => parameters[:RowN])
    insertcols!(cycledata, :par_row => parameters[:RowN])

    outfilepath = string(out_path, "/out_", parameters[:RowN],".csv")
    cwrt(string(out_path, "/stepdata/o_", parameters[:RowN],".csv"), stepdata)
    cwrt(string(out_path, "/substepdata/o_", parameters[:RowN],".csv"), substepdata)
    cwrt(string(out_path, "/cycledata/o_", parameters[:RowN],".csv"), cycledata)


    # areas only for the rust.area, not multiplied by n_lesions
    # n.lesions only for the infected ones.


    return true
end
