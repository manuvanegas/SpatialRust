# Spore dispersal and deposition

## Rust inoculation

function inoculated_coffees(model::ABM, nrusts::Int)
    side = model.pars.map_side
    n_plants_v = side / (model.pars.plant_d * 2)
    n_plants_h = side / (model.pars.row_d * 2)
    quadrant = rand(model.rng, 1:4)
    if quadrant == 1 # following the same order as in outside_spores!()
    #     cof_ids =
    #     model.space.s
    # elseif quadrant == 2
    #     cof_ids = [(i+1):(i+j) for i in 0:side:((n_plants_h - 1) * side) for j]
    # elseif quadrant == 3
    #     from = Tuple.(vcat.(100, sample(model.rng, 1:model.pars.map_side, nrusts)))
    #     headings = 180.0 .+ rand(model.rng, nrusts) .* 2.0 .- 1.0
    # else
    #     from = Tuple.(vcat.(sample(model.rng, 1:model.pars.map_side, nrusts), 100))
    #     headings = 90.0 .+ rand(model.rng, nrusts) .* 2.0 .- 1.0
    end
end

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
                    if all(1 .<= (new_pos = add_tuples(s, pos)) .<= model.pars.map_side)
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
        if length(path) <= 1 && rust.n_lesions < model.pars.max_lesions  # self-infected
            rust.n_lesions += 1
        else
            rain_travel!(model, rust.pos, path)
        end
    end
end

function w_rust_dispersal!(model::ABM, rust::Rust, wdistance::Float64)
    let path = wind_path(model, wdistance)
        if length(path) <= 1 && rust.n_lesions < model.pars.max_lesions # self-infected
            rust.n_lesions += 1
        else
            wind_travel!(model, rust.pos, path)
        end
    end
end

function rain_travel!(model::ABM, pos::NTuple{2,Int}, path::Vector{NTuple{2,Int}})
    let pos = pos, path = path
        @inbounds for s in path[2:end]
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
                # model.current.outpour += 1
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
                if isempty(trees)
                    if blockedwind
                        break
                    end
                elseif (c = first(trees)) isa Coffee &&
                    (blockedwind || s == last(path) || rand(model.rng) < model.pars.disp_block * 0.1)
                        inoculate_rust!(model, c)
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

## When dispersal is successful, create new Rusts

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

## Helper functions to calculate the path followed by each spore (lesion)

function rain_path(model::ABM, sunlight)::Vector{NTuple{2, Int}}
    let distance = abs(2 * randn(model.rng) * model.pars.rain_distance) *
        ((sunlight - 0.55)^2 * ((1 - model.pars.diff_splash) / 0.2025) + model.pars.diff_splash)

        return travel_path(distance, rand(model.rng) * 360)
    end
end

function wind_path(model::ABM, wdistance)::Vector{NTuple{2, Int}}
    # let distance = abs(2 * randn(model.rng)) * model.pars.wind_distance * model.pars.diff_wind * sunlight

        return travel_path(wdistance, (model.current.wind_h + (rand(model.rng) * 5) - 2.5))
    # end
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
        return unique(round.(Int, (ca * h, co * h)) for h in 0.5:0.5:distance)
    end
    # unique!((round.(Int, (cosd(heading) .* collect(0.5:0.5:distance))), round.(Int, (sind(heading) .* collect(0.5:0.5:distance)))))
end

# travel_path(distance::Float64, heading::Float64)::Vector{NTuple{2, Int}} = unique((round(Int, cosd(heading) * h), round(Int, sind(heading) * h)) for h in 0.5:0.5:distance)

add_tuples(t_a::Tuple{Int, Int}, t_b::Tuple{Int, Int}) = @inbounds (t_a[1] + t_b[1], t_a[2] + t_b[2])
add_tuples(t_a::Tuple{Int, Int}, t_b::Vector{Tuple{Int, Int}}) = @inbounds (t_a[1] .+ t_b[1], t_a[2] .+ t_b[2])
