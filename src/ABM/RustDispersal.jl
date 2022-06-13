# Spore dispersal and deposition

## Rust agents' dispersal

# function disperse!(model::ABM, rust::Rust, sunlight::Float64)
    #prog = 1 / (1 + (0.25 / (rust.area + (rust.n_lesions / 25.0)))^4)
function disperse_rain!(model::ABM, rust::Rust, sunlight::Float64)
    # option 2 is put for outside if rand
    # if model.current.rain
        for lesion in 1:rust.n_lesions
            if @inbounds rust.state[3, lesion] == 1.0 &&
                @inbounds rand(model.rng) < (rust.state[2, lesion] * model.pars.spore_pct)
                r_rust_dispersal!(model, rust, sunlight)
            end
        end
    # end
end

function disperse_wind!(model::ABM, rust::Rust, sunlight::Float64)
    # if rand(model.rng) < model.pars.wind_disp_prob
    # if model.current.wind
        let wdistance = abs(2 * randn(model.rng)) * model.pars.wind_distance * model.pars.diff_wind * sunlight
            for lesion in 1:rust.n_lesions
                if @inbounds rust.state[3, lesion] == 1.0 &&
                    @inbounds rand(model.rng) < (rust.state[2, lesion] * model.pars.spore_pct)
                    w_rust_dispersal!(model, rust, wdistance)
                end
            end
        end
    # end

    # # if model.current.rain && rand(model.rng) < model.pars.p_density * rust.spores
    # if model.current.rain && rand(model.rng) < (maximum(rust.area) * model.pars.spore_pct)
    #     # model.p_density * prog  #(rust.n_lesions * rust.area) / (2 + rust.n_lesions * rust.area)
    #     # (rust.n_lesions * rust.spores / (25.0 * model.spore_pct)) * model.p_density
    #
    #     # option 1
    #     events = Int(div(sum(rust.area) * model.pars.spore_pct, 0.5))
    #     # println("rain : rust $(rust.id) has $events disps")
    #     for ns in 1:(events - 1)
    #         # r_rust_dispersal!(model, rust, cof.sunlight)
    #     end
    #     # at least one dispersal event has to happen
    #     # r_rust_dispersal!(model, rust, cof.sunlight)
    # end
    #
    # # if model.current.wind && rand(model.rng) < model.pars.p_density * rust.spores
    # if model.current.wind && rand(model.rng) < (maximum(rust.area) * model.pars.spore_pct)
    #     # model.p_density * prog
    #     # (rust.n_lesions * rust.spores / (25.0 * model.spore_pct)) * model.p_density
    #     # option 1
    #     events = Int(div(sum(rust.area) * model.pars.spore_pct, 0.5))
    #     for ns in 1:(events - 1)
    #         # w_rust_dispersal!(model, rust, cof.sunlight)
    #     end
    #     # w_rust_dispersal!(model, rust, cof.sunlight)
    # end
end

## Dispersal at lesion level (each Rust can have several lesion-level disps)

function outside_spores!(model::ABM)
    let starting = Tuple(shuffle(model.rng,
            [sample(model.rng, 1:model.pars.map_side),
            sample(model.rng, [1, model.pars.map_side])])),
        distance = abs(2 * randn(model.rng)) *
            model.pars.wind_distance * model.pars.diff_wind # sunlight is assumed to be 1.0

        if starting[1] == 1
            heading = rand(model.rng, [359.0, 1.0])
        elseif starting[2] == 1
            heading = rand(model.rng, [269.0, 271.0])
        elseif starting[1] == 100
            heading = rand(model.rng, [179.0, 181.0])
        else
            heading = rand(model.rng, [89.0, 91.0])
        end

        if length(travel_path(distance, heading)) <= 1
            if !isempty(starting, model) && (c = first(agents_in_position(starting, model))) isa Coffee
                inoculate_rust!(model, c)
            end
            # inoculate_rust!(model, coffee_here(starting, model))
        else
            wind_travel!(model, starting, travel_path(distance, heading))
        end
    end
end

function r_rust_dispersal!(model::ABM, rust::Rust, sunlight::Float64)
    let path = rain_path(model, sunlight)
        if length(path) <= 1 # self-infected
            if rust.n_lesions < model.pars.max_lesions
                rust.n_lesions += 1
            end
        else
            rain_travel!(model, rust.pos, path)
        end
    end
end

function w_rust_dispersal!(model::ABM, rust::Rust, wdistance::Float64)
    let path = wind_path(model, wdistance)
        if length(path) <= 1 # self-infected
            if rust.n_lesions < model.pars.max_lesions
                rust.n_lesions += 1
            end
        else
            wind_travel!(model, rust.pos, path)
        end
    end
end

function rain_travel!(model::ABM, pos::NTuple{2,Int}, path::Vector{NTuple{2,Int}})
    # let pos = pos, path = path
    #     @inbounds for s in path[2:end]
    #         if all(1 .<= (new_pos = s .+ pos) .<= model.pars.map_side)
    #             trees = agents_in_position(new_pos, model)
    #             if isempty(trees)
    #                 continue
    #             elseif (c = first(trees)) isa Coffee &&
    #                 (s == last(path) || rand(model.rng) < model.pars.disp_block * 0.5)
    #                 # if the coffee is where the spore was supposed to land || it blocked the dispersal
    #                 inoculate_rust!(model, c)
    #                 break
    #             elseif model.farm_map[new_pos...] == 2 && rand(model.rng) < model.pars.disp_block * 0.5
    #                 break
    #             end
    #         else
    #             # model.current.outpour += 1
    #             break
    #         end
    #     end
    # end

    # let pos = pos, path = path
    #     @inbounds for s in path[2:end]
    #         if all(1 .<= (new_pos = s .+ pos) .<= model.pars.map_side)
    #             if model.farm_map[new_pos...] == 1 &&
    #                 (s == last(path) || rand(model.rng) < model.pars.disp_block * 0.5)
    #                 inoculate_rust!(model, first(agents_in_position(new_pos,model)))
    #                 break
    #             elseif model.farm_map[new_pos...] == 2 && rand(model.rng) < model.pars.disp_block * 0.5
    #                 break
    #             end
    #         else
    #             # model.current.outpour += 1
    #             break
    #         end
    #     end
    # end

    let pos = pos, path = path, pathlength = length(path), prob_block = model.pars.disp_block * 0.5
        notlanded = true
        infarm = true
        pathstep = 1 # doesn't start at 0 because the case of pathlength == 1 is already contemplated
        new_pos = pos

        while notlanded && infarm
            pathstep += 1
            new_pos = pos .+ path[pathstep]
            if all(1 .<= new_pos .<= model.pars.map_side)
                if pathstep == pathlength || rand(model.rng) < prob_block
                    notlanded = false
                end
            else
                infarm = false
            end
        end

        if !infarm
            # placeholder for future functionality: keep track of outpour to 8 neighbors
        end

        if !notlanded
            trees = agents_in_position(new_pos, model)
            if !isempty(trees)
                inoculate_rust!(model, first(trees))
            end
        end
    end

    # probs, landings = r_coffee_probs(model.farm_map, model.pars.disp_block, pos, path)
    # r = rand(model.rng)
    # # i = findfirst(p -> r < p, probs)
    # # if !(isnothing(i))
    # for (i, p) in enumerate(probs)
    #     if r < p
    #         if landings[i] == (-1, -1)
    #             # placeholder for future functionality: keep track of outpour to 8 neighbors
    #         else
    #             inoculate_rust!(model, first(agents_in_position(landings[i], model)))
    #         end
    #         break
    #     end
    # end
end

function wind_travel!(model::ABM, pos::NTuple{2,Int}, path::Vector{NTuple{2,Int}})
    # let pos = pos, path = path
    #     blockedwind = false
    #     for s in path[2:end]
    #         if all(1 .<= (new_pos = s .+ pos) .<= model.pars.map_side)
    #             trees = agents_in_position(new_pos, model)
    #             if isempty(trees)
    #                 if blockedwind
    #                     break
    #                 end
    #             elseif (c = first(trees)) isa Coffee &&
    #                 (blockedwind || s == last(path) || rand(model.rng) < model.pars.disp_block * 0.1)
    #                     inoculate_rust!(model, c)
    #                     break
    #             elseif model.farm_map[new_pos...] == 2 && rand(model.rng) < model.pars.disp_block # blocked by shade
    #                 blockedwind = true
    #                 continue
    #             end
    #         else
    #             # model.current.outpour += 1
    #             break
    #         end
    #     end
    # end

    # let pos = pos, path = path, shade_block = model.current.ind_shade * model.pars.disp_block
    #     blockedwind = false
    #     for s in path[2:end]
    #         if all(1 .<= (new_pos = s .+ pos) .<= model.pars.map_side)
    #             if model.farm_map[new_pos...] == 1 &&
    #                 (blockedwind || s == last(path) || rand(model.rng) < model.shade_map[new_pos...] * shade_block)
    #                     inoculate_rust!(model, first(agents_in_position(new_pos,model)))
    #                     break
    #             elseif model.farm_map[new_pos...] == 2 && rand(model.rng) < model.shade_map[new_pos...] * shade_block # blocked by shade
    #                 blockedwind = true
    #                 # continue
    #             end
    #         else
    #             # model.current.outpour += 1
    #             break
    #         end
    #     end
    # end

    let pos = pos, path = path, pathlength = length(path)
        notlanded = true
        notblocked = true
        infarm = true
        pathstep = 1 # doesn't start at 0 because the case of pathlength == 1 is already contemplated
        new_pos = pos

        while notlanded && infarm
            pathstep += 1
            new_pos = pos .+ path[pathstep]
            if all(1 .<= new_pos .<= model.pars.map_side)
                if notblocked
                    if pathstep == pathlength
                        notlanded = false
                    elseif rand(model.rng) < (model.shade_map[new_pos...] * model.current.ind_shade * model.pars.disp_block)
                        notblocked = false
                    end
                else
                    notlanded = false
                end
            else
                infarm = false
            end
        end

        if !infarm
            # placeholder for future functionality: keep track of outpour to 8 neighbors
        end

        if !notlanded
            trees = agents_in_position(new_pos, model)
            if !isempty(trees)
                inoculate_rust!(model, first(trees))
            end
        end
    end

    # probs, landings = w_coffee_probs(
    #     model.farm_map,
    #     model.shade_map,
    #     (model.current.ind_shade * model.pars.disp_block),
    #     pos, path
    # )
    # r = rand(model.rng)
    # # i = findfirst(p -> r < p, probs)
    # # if !(isnothing(i))
    # for (i, p) in enumerate(probs)
    #     if r < p
    #         if landings[i] == (-1, -1)
    #             # placeholder for future functionality: keep track of outpour to 8 neighbors
    #         else
    #             inoculate_rust!(model, first(agents_in_position(landings[i], model)))
    #         end
    #         break
    #     end
    # end
end

## When dispersal is successful, create new Rusts

function inoculate_rust!(model::ABM, target::Coffee) # inoculate target coffee
    # here = collect(agents_in_position(target, model))
    if target.hg_id != 0
        if model[target.hg_id].n_lesions < model.pars.max_lesions
            model[target.hg_id].n_lesions += 1
        end
    else
        new_id = add_agent!(target.pos, Rust, model, model.pars.max_lesions, model.pars.steps;
            hg_id = target.id, sample_cycle = target.sample_cycle).id
        target.hg_id = new_id
        push!(model.current.rust_ids, new_id)
    end
end

# function inoculate_rust!(model::ABM, trees::Vector{A}) where {A<:AbstractAgent}
#     # here = collect(trees)
#     if length(trees) > 1
#         if trees[2].n_lesions < model.pars.max_lesions
#             trees[2].n_lesions += 1
#         end
#     else
#         new_id = add_agent!(trees[1].pos, Rust, model, model.pars.max_lesions, model.pars.steps;
#             hg_id = trees[1].id, sample_cycle = trees[1].sample_cycle).id
#         trees[1].hg_id = new_id
#         push!(model.current.rust_ids, new_id)
#     end
# end

# inoculate_rust!(model::ABM, none::Bool) = nothing

## Path-dependent probabilities

# function r_coffee_probs(farm_map::Array{Int}, disp_block::Float64, pos::Tuple, path::Vector{NTuple{2, Int}})::Tuple{Vector{Float64},Vector{NTuple{2,Int}}}
#     probs = Float64[]
#     landings = NTuple{2,Int}[] # landing positions
#     cumulative_p = 1.0
#     side = size(farm_map)[1]
#     for s in path[2:end]
#         if all(1 .<= (new_pos = s .+ pos) .<= side)
#             if farm_map[new_pos...] == 1
#                 if s == path[end]
#                     pushfirst!(probs, cumulative_p)
#                     pushfirst!(landings, new_pos)
#                 else
#                     landing_p = cumulative_p * disp_block * 0.5
#                     pushfirst!(probs, landing_p)
#                     pushfirst!(landings, new_pos)
#                     cumulative_p *= (1 - disp_block * 0.5)
#                 end
#             else
#                 cumulative_p *= (1 - disp_block * 0.5)
#             end
#         else
#             pushfirst!(probs, cumulative_p)
#             pushfirst!(landings, (-1, -1))
#             break
#         end
#     end
#     return probs, landings
# end
#
# function w_coffee_probs(farm_map::Array{Int}, shade_map::Array{Float64}, shade_block::Float64, pos::Tuple, path::Vector{NTuple{2, Int}})::Tuple{Vector{Float64},Vector{NTuple{2,Int}}}
#     probs = Float64[]
#     landings = NTuple{2,Int}[] # landing positions
#     cumulative_p = 1.0
#     side = size(farm_map)[1]
#     for s in path[2:end]
#         if all(1 .<= (new_pos = s .+ pos) .<= side)
#             if farm_map[new_pos...] == 1
#                 if s == path[end]
#                     pushfirst!(probs, cumulative_p)
#                     pushfirst!(landings, new_pos)
#                 else
#                     landing_p = cumulative_p * shade_map[new_pos...] * shade_block
#                     pushfirst!(probs, landing_p)
#                     pushfirst!(landings, new_pos)
#                     cumulative_p *= (1 - shade_map[new_pos...] * shade_block)
#                 end
#             else
#                 cumulative_p *= (1 - shade_map[new_pos...] * shade_block)
#             end
#         else
#             pushfirst!(probs, cumulative_p)
#             pushfirst!(landings, (-1, -1))
#             break
#         end
#     end
#     return probs, landings
# end

## Helper functions to calculate the path followed by each spore (lesion)

function rain_path(model::ABM, sunlight)::Vector{NTuple{2, Int}}
    let distance = abs(2 * randn(model.rng) * model.pars.rain_distance) *
        ((sunlight - 0.55)^2 * ((1 - model.pars.diff_splash) / 0.2025) + model.pars.diff_splash)

        return travel_path(distance, rand(model.rng) * 360)
    end
end

function wind_path(model::ABM, wdistance)::Vector{NTuple{2, Int}}
    return travel_path(wdistance, (model.current.wind_h + (rand(model.rng) * 5) - 2.5))
end

# function coffee_here(pos::NTuple{2,Int}, model::ABM)::Union{Coffee, Bool}
#     if isempty(pos, model)
#         return false
#     elseif (c = first(collect(agents_in_position(starting, model)))) isa Coffee
#         return c
#     else
#         return false
#     end
# end

function travel_path(distance::Float64, heading::Float64)::Vector{NTuple{2, Int}}
    let ca = cosd(heading), co = sind(heading)
        return unique!(collect(round.(Int, (ca * h, co * h)) for h in 0.5:0.5:distance))
    end
    # unique!((round.(Int, (cosd(heading) .* collect(0.5:0.5:distance))), round.(Int, (sind(heading) .* collect(0.5:0.5:distance)))))
end

# travel_path(distance::Float64, heading::Float64)::Vector{NTuple{2, Int}} = unique((round(Int, cosd(heading) * h), round(Int, sind(heading) * h)) for h in 0.5:0.5:distance)

# add_tuples(t_a::Tuple{Int, Int}, t_b::Tuple{Int, Int}) = @inbounds (t_a[1] + t_b[1], t_a[2] + t_b[2])
add_tuples(t_a::Tuple{Int, Int}, t_b::Vector{Tuple{Int, Int}}) = @inbounds (t_a[1] .+ t_b[1], t_a[2] .+ t_b[2])



## Rust initial inoculation (optional function, not in use currently)
# This one assumes that rust epidemic has to come from an influx of wind-dispersed spores

function inoculate_farm(model::ABM, nrusts::Int) #PROBLEM: increased variability because each sim starts with != #rusts
    # byrain = rand(model.rng, 1:nrusts)
    # bywind = nrusts - byrain
    inoc_ids = Int[]

    from_side = rand(model.rng, 1:4) #N,E,S,W <-> 1,2,3,4
    if from_side == 4 # following the same order as in outside_spores!()
        from = Tuple.(vcat.(1, sample(model.rng, 1:model.pars.map_side, nrusts)))
        headings = 360.0 .+ rand(model.rng, nrusts) .* 2.0 .- 1.0
    elseif from_side == 1
        from = Tuple.(vcat.(sample(model.rng, 1:model.pars.map_side, nrusts), 1))
        headings = 270.0 .+ rand(model.rng, nrusts) .* 2.0 .- 1.0
    elseif from_side == 2
        from = Tuple.(vcat.(100, sample(model.rng, 1:model.pars.map_side, nrusts)))
        headings = 180.0 .+ rand(model.rng, nrusts) .* 2.0 .- 1.0
    else
        from = Tuple.(vcat.(sample(model.rng, 1:model.pars.map_side, nrusts), 100))
        headings = 90.0 .+ rand(model.rng, nrusts) .* 2.0 .- 1.0
    end

    wdistances = abs.(2 .* randn(model.rng, nrusts)) .* model.pars.wind_distance .* model.pars.diff_wind

    for (starting, heading, distance) in zip(from, headings, wdistances)
        if length(travel_path(distance, heading)) <= 1
            if !isempty(starting, model) && (c = first(agents_in_position(starting, model))) isa Coffee
                push!(inoc_ids, c.id)
            end
        else
            # wind_travel!(model, starting, travel_path(distance, heading))
            let pos = starting, path = travel_path(distance, heading)
                blockedwind = false
                for s in path[2:end]
                    if all(1 .<= (new_pos = s .+ pos) .<= model.pars.map_side)
                        trees = agents_in_position(new_pos, model)
                        if isempty(trees)
                            if blockedwind
                                break
                            end
                        elseif (c = first(trees)) isa Coffee &&
                            (blockedwind || s == last(path) || rand(model.rng) < model.pars.disp_block * 0.1)
                                push!(inoc_ids, c.id)
                                break
                        elseif rand(model.rng) < model.pars.disp_block # blocked by shade
                            blockedwind = true
                            continue
                        end
                    else
                        # model.current.outpour += 1
                        break
                    end
                end
            end
        end
    end
end
