function step_model!(model::ABM)
    if model.current.ticks == 0
        kill_agent!(pop!(model.current.shade_ids), model)
    end
    pre_step!(model)

    for shade_i in model.current.shade_ids
        shade_step!(model[shade_i], model)
    end

    for cof_i in model.current.coffee_ids
        coffee_step!(model[cof_i], model)
    end

    for rust_i in shuffle(model.rng, model.current.rust_ids)
        rust_step!(model[rust_i], model)
    end

    post_step!(model)
end

## "Step" functions

function pre_step!(model)
    model.current.days += 1
    model.current.ticks += 1

    model.current.rain = model.weather.rain_data[model.current.ticks]
    model.current.wind = model.weather.wind_data[model.current.ticks]
    model.current.temperature = model.weather.temp_data[model.current.ticks]
    model.current.outpour = model.current.outpour * 0.9
    if model.pars.karma && rand(model.rng) < sqrt(model.current.outpour)/(model.pars.map_side^2)
        outside_spores!(model)
    end
    if (model.current.ticks - 1) in model.pars.switch_cycles
        # popfirst!(model.pars.switch_cycles)
        if model.current.cycle[1] == 5 && !isassigned(model.current.cycle, 2)
            push!(model.current.cycle, 6)
        else
            model.current.cycle .+= 1
        end
    end

    # println(median(getproperty.((model[id] for id in model.current.rust_ids), :n_lesions)))
end

function shade_step!(tree::Shade, model::ABM)
    grow_shade!(tree, model.pars.shade_g_rate)
end

function coffee_step!(coffee::Coffee, model::ABM)

    if coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    elseif coffee.exh_countdown == 1
        coffee.area = 1.0
        coffee.exh_countdown = 0
    else
        update_sunlight!(coffee, model)
        grow_coffee!(coffee, model.pars.max_cof_gr)
        acc_production!(coffee)
    end
end

function rust_step!(rust::Rust, model::ABM)

    host = model[rust.hg_id]

# TODO: CHECK effect of checking for host's area instead of exh_countdown

    if host.area > 0.0 # not exhausted
        if any(rust.spores .> 0.0)
            disperse!(rust, host, model)
        end
        parasitize!(rust, host, model)
        grow_rust!(rust, host, model)
    end
end

function post_step!(model)
    if model.current.days % model.pars.harvest_cycle === 0
        harvest!(model)
    end

    # if model.days % model.fungicide_period === 0
    #     fingicide!(model)
    # end
    # if model.days % model.prune_period === 0
    #     prune!(model)
    # end
    # if model.days % model.inspect_period === 0
    #     inspect!(model)
    # end
end

###
## Shade
###

function grow_shade!(tree::Shade, rate::Float64)
    tree.shade += tree.shade + rate * (1.0 - tree.shade / 0.95) * tree.shade
    tree.age += 1
end

###
## Coffee
###

function update_sunlight!(cof::Coffee, model::ABM)
    shade = 0.0
    for sh in cof.shade_neighbors
        shade += model[sh].shade
    end
    # shades::Array{Float64} = getproperty.(model[cof.shade_neighbors],:shade)
    # shade = sum(shades)

    #cof.sunlight = 1.0 - shade / 8.0
    # cof.sunlight = exp(-(sum(cof.shade_neighbors.shade) / 8))
end

function grow_coffee!(cof::Coffee, max_cof_gr)
    # coffee plants can recover healthy tissue (dilution effect for sunlit plants)

"This growth function has to change"
    if 0.0 < cof.area < 1.0
        cof.area += max_cof_gr * (cof.area * cof.sunlight)
    elseif cof.area > 1.0
        cof.area = 1.0
    end

    cof.age += 1
end

function acc_production!(cof::Coffee) # accumulate production
    cof.production += cof.area * cof.sunlight
end

###
## Rust
###

function disperse!(rust::Rust, cof::Coffee, model::ABM)
    #prog = 1 / (1 + (0.25 / (rust.area + (rust.n_lesions / 25.0)))^4)

    # if model.current.rain && rand(model.rng) < model.pars.p_density * rust.spores
    if model.current.rain && rand(model.rng) < maximum(rust.spores)
        # model.p_density * prog  #(rust.n_lesions * rust.area) / (2 + rust.n_lesions * rust.area)
        # (rust.n_lesions * rust.spores / (25.0 * model.spore_pct)) * model.p_density

        # option 1
        events = sum(rust.spores) >= 0.5 ? Int(div(sum(rust.spores), 0.5)) : 1
        # println("rain : rust $(rust.id) has $events disps")
        for ns in 1:events

            r_rust_dispersal!(model, rust, cof.sunlight)
        end

        # option 2 is put for outside if rand
        if model.current.rain
            for lesion in 1:rust.n_lesions
                 if rand(model.rng) < rust.spores[lesion]
                 end
             end
         end
    end

    # if model.current.wind && rand(model.rng) < model.pars.p_density * rust.spores
    if model.current.wind && rand(model.rng) < maximum(rust.spores)
        # model.p_density * prog
        # (rust.n_lesions * rust.spores / (25.0 * model.spore_pct)) * model.p_density
        # option 1
        events = sum(rust.spores) >= 0.5 ? Int(div(sum(rust.spores), 0.5)) : 1
        for ns in 1:events

            w_rust_dispersal!(model, rust, cof.sunlight)
        end

        # option 2 is put for outside if rand
        if model.current.rain
            for lesion in 1:rust.n_lesions
                 if rand(model.rng) < rust.spores[lesion]
                 end
             end
         end
    end
end

function parasitize!(rust::Rust, cof::Coffee, model::ABM)

    if any(rust.germinated)
        # bal = rust.area + (rust.n_lesions / 25.0) # between 0.0 and 2.0
    # # cof.progression = 1 / (1 + (0.75 / bal)^4)
    #     prog = 1 / (1 + (0.25 / bal)^4) # Hill function with steep increase
    #     cof.area = 1.0 - prog
        cof.area = 1.0 - (sum(rust.area) / model.pars.max_lesions)
        #if rust.area * rust.n_lesions >= model.pars.exhaustion #|| bal >= 2.0
        if (sum(rust.area) / model.pars.max_lesions) >= model.pars.exhaustion
            cof.area = 0.0
            cof.exh_countdown = (model.pars.harvest_cycle * 2) + 1
            kill_rust!(rust, cof, model)
        end
    end
end

function grow_rust!(rust::Rust, cof::Coffee, model::ABM)

    local_temp = model.current.temperature - (model.pars.temp_cooling * (1.0 - cof.sunlight))
    for les in 1:rust.n_lesions
        if rust.germinated[les]
            if rust.age[les] < model.pars.steps
                rust.age[les] += 1
            end
            if 14 < local_temp < 30 # grow and sporulate

                #  logistic growth (K=1) * rate due to fruit load * rate due to temperature
                rust.area[les] += rust.area[les] * (1 - rust.area[les]) *
                    #(model.fruit_load * (1 / (1 + (30 / cof.production))^2)) *
                    model.pars.fruit_load * cof.production / model.pars.harvest_cycle *
                    (-0.0178 * ((local_temp - model.pars.opt_g_temp) ^ 2.0) + 1.0)

                if rust.spores[les] == 0.0
                    if rand(model.rng) < (rust.area[les] * (local_temp + 5) / 30) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
                        rust.spores[les] = rust.area[les] * model.pars.spore_pct
                    end
                else
                    rust.spores[les] = rust.area[les] * model.pars.spore_pct
                end
            end

        else # try to germinate + penetrate tissue
            let r = rand(model.rng)
                if r < (cof.sunlight * model.pars.uv_inact) || r <  (cof.sunlight * (model.current.rain ? model.pars.rain_washoff : 0.0))
                    # higher % sunlight means more chances of inactivation by UV or rain
                    if rust.n_lesions > 1
                        "fix this"#TODO
                        rust.n_lesions -= 1
                    else
                        kill_rust!(rust, cof, model)
                    end
                else
                    if rand(model.rng) < calc_wetness_p(local_temp - (model.current.rain ? 6.0 : 0.0))
                        rust.germinated[les] = true
                        rust.area[les] = 0.01
                        rust.age[les] = 0
                    end
                end
            end
        end
    end
end


###
## Farmer
###

function harvest!(model::ABM)
    harvest = 0.0
    ids = model.current.coffee_ids
    for id in ids
        harvest += model[id].production / model.pars.harvest_cycle
        model[id].production = 1.0
        # if plant.fung_this_cycle
        #     plant.fung_this_cycle = false
        #     plant.productivity = plant.productivity / 0.8
        # end
        # if plant.pruned_this_cycle
        #     plant.pruned_this_cycle = false
        #     plant.productivity = plant.productivity / 0.9
        # end
    end
    model.current.net_rev += (model.pars.coffee_price * harvest) - model.current.costs
    # model.current.gains += model.coffee_price * harvest * model.pars.p_density
    model.current.yield += harvest / length(model.current.coffee_ids)
end

function fungicide!(model::ABM)
    # apply fungicide
    # add to costs
end

function prune!(model::ABM)
    n_pruned = trunc(model.pars.prune_effort * length(model.current.shade_ids))
    model.current.costs += n_pruned * model.pars.prune_cost
    pruned = partialsort(model.current.shade_ids, 1:n_pruned, rev=true, by = x -> model[x].shade)
    for pr in pruned
        model[pr].shade = model.pars.target_shade
    end
end

function inspect!(model::ABM)
    n_inspected = trunc(model.pars.inspect_effort * length(model.current.coffee_ids))
    cofs = sample(model.rng, model.current.coffee_ids, n_inspected, replace = false)
    for c in cofs
        here = collect(agents_in_position(model[c].pos, model))
        if length(here) > 1
            here[2].n_lesions = round(Int, here[2].n_lesions * 0.1)
            here[2].area = round(Int, here[2].area * 0.1)
        end
    end
end

####
## Secondary functions
####

function outside_spores!(model::ABM)
    starting = Tuple(shuffle(model.rng, [sample(model.rng, 1:100), sample(model.rng, [1,100])]))
    if starting[1] == 1
        heading = 0.0
    elseif starting[2] == 1
        heading = 270.0
    elseif starting[1] == 100
        heading = 180.0
    else
        heading = 90.0
    end

    distance = abs(2 * randn(model.rng)) * model.pars.wind_distance * model.pars.diff_wind # sunlight is taken as 1.0
    # path = unique!([(round(Int, cosd(heading) * h), round(Int, sind(heading) * h)) for h in 0.5:0.5:distance])
    wind_travel!(model, starting, travel_path(distance, heading, 0.5))
end

function r_rust_dispersal!(model::ABM, rust::Rust, sunlight::Float64)

    # path = unique!([(round(Int, cosd(heading) * h), round(Int, sind(heading) * h)) for h in 0.5:0.5:distance])
    path = rain_path(model, sunlight)

    # println("path length $(length(path))")
    if length(path) <= 1 && rust.n_lesions < model.pars.max_lesions  # self-infected
        rust.n_lesions += 1
        # println("nlesions: $(rust.n_lesions)")
    else
        for s in path[2:end]
            trees = try collect(agents_in_position(add_tuples(s, rust.pos), model))
            catch
                model.current.outpour += 1
                # println("out")
                break
            end
            if isempty(trees)
                # println("empty at $s")
                continue
            elseif first(trees) isa Coffee &&
                (s == last(path) || rand(model.rng) < model.pars.disp_block * 0.5)
                # the coffee is where the spore was supposed to land || it blocked the dispersal
                # println(first(trees))
                # println(last(trees))
                inoculate_rust!(model, trees)
                # println("new rust: $(last(model.current.rust_ids))")
                break
            elseif rand(model.rng) < model.pars.disp_block * 0.5
                # println("blocked at: $(add_tuples(s, rust.pos))")
                break
            end
        end
    end
end

function w_rust_dispersal!(model::ABM, rust::Rust, sunlight::Float64)
    path = wind_path(model, sunlight)

    if length(path) <= 1 && rust.n_lesions < model.pars.max_lesions # self-infected
        rust.n_lesions += 1
    else
        wind_travel!(model, rust.pos, path)
    end
end

function wind_travel!(model::ABM, pos::NTuple{2,Int}, path::Vector{NTuple{2,Int}})
    let pos = pos, path = path
        blockedwind = false
        for s in path[2:end]
            trees = try collect(agents_in_position(add_tuples(s, pos), model))
            catch
                model.current.outpour += 1
                break
            end
            if blockedwind
                if !isempty(trees) && first(trees) isa Coffee
                    inoculate_rust!(model, trees)
                    break
                else
                    break
                end
            else
                if isempty(trees)
                    continue
                elseif first(trees) isa Coffee &&
                    (s == last(path) || rand(model.rng) < model.pars.disp_block * 0.1)
                    # *0.1 because they are not great windbreaks, but can happen
                    inoculate_rust!(model, collect(trees))
                    break
                elseif rand(model.rng) < model.pars.disp_block # blocked by shade
                    blockedwind = true
                    continue
                end
            end
        end
    end
end

function inoculate_rust!(model::ABM, target::AbstractAgent) # inoculate target coffee
    here = collect(agents_in_position(target, model))
    if length(here) > 1
        if here[2].n_lesions < model.pars.max_lesions
            here[2].n_lesions += 1
            here[2].age[here[2].n_lesions] = 0
        end
    elseif target isa Coffee
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

function inoculate_rust!(model::ABM, trees::Vector{A}) where {A <: AbstractAgent}
    # here = collect(trees)
    if length(trees) > 1
        if trees[2].n_lesions < model.pars.max_lesions
            trees[2].n_lesions += 1
            trees[2].age[trees[2].n_lesions] = 0
        end
    else
        new_id = add_agent!(trees[1].pos, Rust, model, model.pars.max_lesions, model.pars.steps;
            hg_id = trees[1].id, sample_cycle = trees[1].sample_cycle).id
        trees[1].hg_id = new_id
        push!(model.current.rust_ids, new_id)
    end
end

function kill_rust!(rust::Rust, cof::Coffee, model::ABM)
    cof.hg_id = 0
    rm_id = rust.id
    delete!(model.agents, rust.id)
    deleteat!(model.space.s[rust.pos...], 2)
    deleteat!(model.current.rust_ids, findfirst(i -> i == rm_id, model.current.rust_ids))
end

function add_tuples(t_a::Tuple{Int, Int}, t_b::Tuple{Int, Int})
    return (t_a[1] + t_b[1], t_a[2] + t_b[2])
end

function calc_wetness_p(local_temp)
    w = (-0.5/16.0) * local_temp + (0.5*30.0/16.0)
end

function rain_path(model::ABM, sunlight)
    distance = abs(2 * randn(model.rng) * model.pars.rain_distance) *
    ((sunlight - 0.55)^2 * ((1 - model.pars.diff_splash) / 0.2025) + model.pars.diff_splash)

    return travel_path(distance, (rand(model.rng) * 360), 0.5)
end

function wind_path(model::ABM, sunlight)
    distance = abs(2 * randn(model.rng)) * model.pars.wind_distance * model.pars.diff_wind * sunlight

    return travel_path(distance, rand(model.rng) * 360, 0.5)
end

travel_path(distance::Float64, heading::Float64, x::Float64)::Vector{NTuple{2, Int}} = unique!([(round(Int, cosd(heading) * h), round(Int, sind(heading) * h)) for h in x:x:distance])
