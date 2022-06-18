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
    let wdistance = abs(2.0 * randn(model.rng)) * model.pars.wind_distance * model.pars.diff_wind * sunlight
        for lesion in 1:rust.n_lesions
            if @inbounds rust.state[3, lesion] == 1.0 &&
                @inbounds rand(model.rng) < (rust.state[2, lesion] * model.pars.spore_pct)
                w_rust_dispersal!(model, rust, wdistance)
            end
        end
    end
end

## Dispersal at lesion level (each Rust can have several lesion-level disps)

function outside_spores!(model::ABM)
    let starting = CartesianIndex((
            sample(model.rng, 1:model.pars.map_side),
            sample(model.rng, [1, model.pars.map_side])
            )[shuffle(model.rng, 1:2)]),
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

        if distance < 1.0
            if !isempty(Tuple(starting), model) && (c = first(agents_in_position(Tuple(starting), model))) isa Coffee
                inoculate_rust!(model, c)
            end
            # inoculate_rust!(model, coffee_here(starting, model))
        else
            # wind_travel!(model, starting, travel_path(distance, heading))
            wind_travel!(model, starting, distance, heading)
        end
    end
end

function r_rust_dispersal!(model::ABM, rust::Rust, sunlight::Float64)
    let distance = abs(2.0 * randn(model.rng) * model.pars.rain_distance) *
        ((sunlight - 0.55)^2.0 * ((1.0 - model.pars.diff_splash) * inv(0.2025)) + model.pars.diff_splash)

        rain_travel!(model, CartesianIndex(rust.pos), distance, rand(model.rng) * 360.0)
    end
end

function w_rust_dispersal!(model::ABM, rust::Rust, wdistance::Float64)
    wind_travel!(model, CartesianIndex(rust.pos), wdistance, (model.current.wind_h + (rand(model.rng) * 5) - 2.5))
end

function rain_travel!(model::ABM, pos::CartesianIndex{2}, dist::Float64, heading::Float64)
    let ca = cosd(heading), co = sind(heading), prob_block = model.pars.disp_block * 0.5
        notlanded = true
        infarm = true
        traveled = 0.5
        onx = 0.0
        ony = 0.0
        advanced = false
        new_pos = pos
        side = model.pars.map_side

        if dist < 1.0 # then it will stay in the same coffee
            notlanded = false
        end

        while notlanded && infarm
            traveled += 0.5
            if traveled < dist
                # new_pos = next_pos(pos, ca, co, traveled)
                newx = floor(ca * traveled)
                newy = floor(co * traveled)
                if newx != onx
                    onx = newx
                    new_pos += CartesianIndex(1,0)
                    advanced = true
                end
                if newy != ony
                    ony = newy
                    new_pos += CartesianIndex(0,1)
                    advanced = true
                end
                if advanced
                    if in_farm(new_pos, side)
                        if is_droplet_blocked(model.rng, new_pos, model.farm_map, prob_block)
                            notlanded = false
                        end
                    else
                        infarm = false
                    end
                end
                advanced = false
            else
                notlanded = false
            end
        end

        if !infarm
            # placeholder for future functionality: keep track of outpour to 8 neighbors
        end

        if !notlanded
            trees = agents_in_position(Tuple(new_pos), model)
            if !isempty(trees)
                inoculate_rust!(model, first(trees))
            end
        end
    end
end

function wind_travel!(model::ABM, pos::CartesianIndex{2}, dist::Float64, heading::Float64)
    let ca = cosd(heading), co = sind(heading), shade_block = model.pars.disp_block
        notlanded = true
        infarm = true
        notblocked = true
        traveled = 0.5
        onx = 0.0
        ony = 0.0
        advanced = false
        new_pos = pos
        side = model.pars.map_side

        while notlanded && infarm
            traveled += 0.5
            if traveled < dist
                # new_pos = next_pos(pos, ca, co, traveled)
                newx = floor(ca * traveled)
                newy = floor(co * traveled)
                if newx != onx
                    onx = newx
                    new_pos += CartesianIndex(1,0)
                    advanced = true
                end
                if newy != ony
                    ony = newy
                    new_pos += CartesianIndex(0,1)
                    advanced = true
                end
                if advanced
                    if in_farm(new_pos, side)
                        if notblocked
                            if is_wind_blocked_shade(model.rng, new_pos, model.shade_map, shade_block)
                                notblocked = false
                            end
                        else
                            notlanded = false
                        end
                    else
                        infarm = false
                    end
                end
                advanced = false
            else
                notlanded = false
            end
        end

        if !infarm
            # placeholder for future functionality: keep track of outpour to 8 neighbors
        end

        if !notlanded
            trees = agents_in_position(Tuple(new_pos), model)
            if !isempty(trees)
                inoculate_rust!(model, first(trees))
            end
        end
    end
end

## Helpers

function next_pos(pos::CartesianIndex{2}, ca::Float64, co::Float64, traveled::Float64)::CartesianIndex{2}
    return pos + CartesianIndex(ca * traveled, co * traveled)
end

function is_droplet_blocked(rng, pos::CartesianIndex{2}, farm_map::Matrix{Int}, shade_block::Float64)
    if @inbounds farm_map[pos] == 0
        return false
    else
        return rand(rng) < shade_block
    end
end

function is_wind_blocked_shade(rng, pos::CartesianIndex{2}, shade_map::Matrix{Float64}, shade_block::Float64)
    return rand(rng) < (@inbounds shade_map[pos]) * shade_block
end

## When dispersal is successful, create new Rusts

function inoculate_rust!(model::ABM, target::Coffee) # inoculate target coffee
    # here = collect(agents_in_position(target, model))
    if target.hg_id != 0
        if model[target.hg_id].n_lesions < model.pars.max_lesions
            model[target.hg_id].n_lesions += 1
        end
    else
        new = add_agent!(target.pos, Rust, model, model.pars.max_lesions, model.pars.steps;
            hg_id = target.id, sample_cycle = target.sample_cycle)
        target.hg_id = new.id
        push!(model.current.rusts, new)
    end
end

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
