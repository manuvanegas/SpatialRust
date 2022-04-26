## Spore dispersal and deposition

function outside_spores!(model::ABM)
    let starting = Tuple(shuffle(model.rng,
            [sample(model.rng, 1:model.pars.map_side),
            sample(model.rng, [1, model.pars.map_side])])),
        distance = abs(2 * randn(model.rng)) *
            model.pars.wind_distance * model.pars.diff_wind # sunlight is assumed to be 1.0

        if starting[1] == 1
            heading = 0.0
        elseif starting[2] == 1
            heading = 270.0
        elseif starting[1] == 100
            heading = 180.0
        else
            heading = 90.0
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
        if length(path) <= 1 && rust.n_lesions < model.pars.max_lesions  # self-infected
            rust.n_lesions += 1
        else
            rain_travel!(model, rust.pos, path)
        end
    end
end

function w_rust_dispersal!(model::ABM, rust::Rust, sunlight::Float64)
    let path = wind_path(model, sunlight)
        if length(path) <= 1 && rust.n_lesions < model.pars.max_lesions # self-infected
            rust.n_lesions += 1
        else
            wind_travel!(model, rust.pos, path)
        end
    end
end

function rain_travel!(model::ABM, pos::NTuple{2,Int}, path::Vector{NTuple{2,Int}})
    let pos = pos, path = path
        for s in path[2:end]
            if all(1 .<= (new_pos = add_tuples(s, pos)) .<= model.pars.map_side)
                trees = agents_in_position(new_pos, model)
                if isempty(trees)
                    continue
                elseif (c = first(trees)) isa Coffee &&
                    (s == last(path) || rand(model.rng) < model.pars.disp_block * 0.5)
                    # if the coffee is where the spore was supposed to land || it blocked the dispersal
                    inoculate_rust!(model, c)
                    break
                elseif rand(model.rng) < model.pars.disp_block * 0.5
                    break
                end
            else
                model.current.outpour += 1
                break
            end
        end
    end
end

function wind_travel!(model::ABM, pos::NTuple{2,Int}, path::Vector{NTuple{2,Int}})
    let pos = pos, path = path
        blockedwind = false
        for s in path[2:end]
            if all(1 .<= (new_pos = add_tuples(s, pos)) .<= model.pars.map_side)
                trees = agents_in_position(new_pos, model)
                if blockedwind
                    if !isempty(trees) && (c = first(trees)) isa Coffee
                        inoculate_rust!(model, c)
                        break
                    else
                        break
                    end
                else
                    if isempty(trees)
                        continue
                    elseif (c = first(trees)) isa Coffee &&
                        (s == last(path) || rand(model.rng) < model.pars.disp_block * 0.1)
                        # *0.1 because they are not great windbreaks, but can happen
                        inoculate_rust!(model, c)
                        break
                    elseif rand(model.rng) < model.pars.disp_block # blocked by shade
                        blockedwind = true
                        continue
                    end
                end
            else
                model.current.outpour += 1
                break
            end
        end
    end
end

function inoculate_rust!(model::ABM, target::Coffee) # inoculate target coffee
    # here = collect(agents_in_position(target, model))
    if target.hg_id != 0
        if model[target.hg_id].n_lesions < model.pars.max_lesions
            model[target.hg_id].n_lesions += 1
        end
    # if length(here) > 1
    #     if here[2].n_lesions < model.pars.max_lesions
    #         here[2].n_lesions += 1
    #     end
    else
        # if isdisjoint(target.sample_cycle, model.current.cycle)
        #     new_id = add_agent!(target.pos, Rust, model; age = (model.pars.steps + 1), hg_id = target.id, sample_cycle = target.sample_cycle).id
        # else
        new_id = add_agent!(target.pos, Rust, model, model.pars.max_lesions, model.pars.steps;
            hg_id = target.id, sample_cycle = target.sample_cycle).id
        # end
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

function rain_path(model::ABM, sunlight)::Vector{NTuple{2, Int}}
    let distance = abs(2 * randn(model.rng) * model.pars.rain_distance) *
        ((sunlight - 0.55)^2 * ((1 - model.pars.diff_splash) / 0.2025) + model.pars.diff_splash)

        return travel_path(distance, rand(model.rng) * 360)
    end
end

function wind_path(model::ABM, sunlight)::Vector{NTuple{2, Int}}
    let distance = abs(2 * randn(model.rng)) * model.pars.wind_distance * model.pars.diff_wind * sunlight

        return travel_path(distance, rand(model.rng) * 360)
    end
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
        return unique((round(Int, ca * h), round(Int, co * h)) for h in 0.5:0.5:distance)
    end
    # unique!((round.(Int, (cosd(heading) .* collect(0.5:0.5:distance))), round.(Int, (sind(heading) .* collect(0.5:0.5:distance)))))
end

# travel_path(distance::Float64, heading::Float64)::Vector{NTuple{2, Int}} = unique((round(Int, cosd(heading) * h), round(Int, sind(heading) * h)) for h in 0.5:0.5:distance)

add_tuples(t_a::Tuple{Int, Int}, t_b::Tuple{Int, Int}) = (t_a[1] + t_b[1], t_a[2] + t_b[2])