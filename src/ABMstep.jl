function step_model!(model::ABM)
    pre_step!(model)

    for shade_i in model.current.shade_ids
        shade_step!(model.agents[shade_i], model)
    end

    for cof_i in model.current.coffee_ids
        coffee_step!(model.agents[cof_i], model)
    end

    for rust_i in shuffle(model.rng, model.current.rust_ids)
        rust_step!(model.agents[rust_i], model)
    end

    model_step!(model)
end

## "Step" functions

function pre_step!(model)
    model.current.rain = model.rain_data[model.current.ticks]
    model.current.wind = model.wind_data[model.current.ticks]
    model.current.temperature = model.temp_data[model.current.ticks]
    if model.karma && rand(model.rng) < sqrt(model.current.outpour)/(model.dims^2)
        inoculate_rand_rust!(model, 1)
    end
end

function shade_step!(tree::Shade, model::ABM)
    grow!(tree, model.shade_rate)
end

function coffee_step!(coffee::Coffee, model::ABM)

    if coffee.exh_countdown > 1
        coffee.exh_countdown -= 1
    elseif coffee.exh_countdown == 1
        coffee.area = 25
        coffee.exh_countdown = 0
    else
        update_sunlight!(coffee, model)
        grow!(coffee, model.max_cof_gr)
        acc_production!(coffee)
    end
end

function rust_step!(rust::Rust, model::ABM)

    host = collect(agents_in_position(rust, model))[1]
    if host.area > 0.0 # not exhausted
        if rust.spores > 0.0
            disperse!(rust, host, model)
        end
        parasitize!(rust, host, model)
        grow!(rust, host, model)
    end
end

function model_step!(model)
    if model.current.days % model.harvest_cycle === 0
        harvest!(model)
    end

    model.current.days += 1
    model.current.ticks += 1
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

function grow!(tree::Shade, rate::Float64)
    tree.shade += rate * (1.0 - tree.shade / 0.9)
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

    cof.sunlight = 1.0 - shade / 8.0
    # cof.sunlight = exp(-(sum(cof.shade_neighbors.shade) / 8))
end

function grow!(cof::Coffee, max_cof_gr)
    # coffee plants can recover healthy tissue (dilution effect for sunlit plants)
    if 0.0 < cof.area < 25.0
        cof.area += max_cof_gr * (cof.area * cof.sunlight)
    elseif cof.area > 25.0
        cof.area = 25.0
    end

    cof.age += 1
end

function acc_production!(cof::Coffee) # accumulate production
    cof.production += (cof.area / 25.0) * cof.sunlight
end

###
## Rust
###

function disperse!(rust::Rust, cof::Coffee, model::ABM)
    #prog = 1 / (1 + (0.25 / (rust.area + (rust.n_lesions / 25.0)))^4)

    if model.current.rain && rand(model.rng) < model.p_density * rust.spores
        # model.p_density * prog  #(rust.n_lesions * rust.area) / (2 + rust.n_lesions * rust.area)
        # (rust.n_lesions * rust.spores / (25.0 * model.spore_pct)) * model.p_density
        target = try_travel(rust, cof.sunlight, model, "r")
        # println("obt")
        # println(target)
        if target !== rust
            inoculate_rust!(model, target)
        end
    end

    if model.current.wind && rand(model.rng) < model.p_density * rust.spores
        # model.p_density * prog
        # (rust.n_lesions * rust.spores / (25.0 * model.spore_pct)) * model.p_density
        target = try_travel(rust, cof.sunlight, model, "w")
        if target !== rust
            inoculate_rust!(model, target)
        end
    end
end

function parasitize!(rust::Rust, cof::Coffee, model::ABM)

    if rust.germinated
        # bal = rust.area + (rust.n_lesions / 25.0) # between 0.0 and 2.0
    # # cof.progression = 1 / (1 + (0.75 / bal)^4)
    #     prog = 1 / (1 + (0.25 / bal)^4) # Hill function with steep increase
    #     cof.area = 1.0 - prog
        cof.area = 25.0 - (rust.n_lesions * rust.area)
        if cof.area <= 0.0 #|| bal >= 2.0
            cof.area = 0.0
            cof.exh_countdown = (model.harvest_cycle * 2) + 1

            rm_id = rust.id
            kill_agent!(rust, model)
            cof.hg_id = 0
            model.current.rust_ids = filter(i -> i != rm_id, model.current.rust_ids)
        end
    end
end

function grow!(rust::Rust, cof::Coffee, model::ABM)

    local_temp = model.current.temperature - (model.temp_cooling * (1.0 - cof.sunlight))

    if rust.germinated && 14 < local_temp < 30 # grow and sporulate

        rust.age += 1

        #  logistic growth (K=1) * rate due to fruit load * rate due to temperature
        rust.area += rust.area * (1 - rust.area) *
            #(model.fruit_load * (1 / (1 + (30 / cof.production))^2)) *
            model.fruit_load * cof.production / model.harvest_cycle *
            (-0.0178 * ((local_temp - model.opt_g_temp) ^ 2.0) + 1.0)

        if rust.spores === 0.0
            if rand(model.rng) < (rust.area * (local_temp + 5) / 30) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
                rust.spores = rust.area * model.spore_pct
            end
        else
            rust.spores = rust.area * model.spore_pct
        end

    else # try to germinate + penetrate tissue
        let r = rand(model.rng)
            if r < (cof.sunlight * model.uv_inact) || r <  (cof.sunlight * (model.current.rain ? model.rain_washoff : 0.0))
                # higher % sunlight means more chances of inactivation by UV or rain
                rm_id = rust.id
                kill_agent!(rust, model)
                model.current.rust_ids = filter(i -> i != rm_id, model.current.rust_ids)
            else
                if rand(model.rng) < calc_wetness_p(local_temp - (model.current.rain ? 6.0 : 0.0))
                    rust.germinated = true
                    rust.area = 0.01
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
        harvest += model[id].production / model.harvest_cycle
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
    model.current.gains += model.coffee_price * harvest * model.p_density
    model.current.yield += harvest / (model.dims^2)
end

function fungicide!(model::ABM)
    # apply fungicide
    # add to costs
end

function prune!(model::ABM)
    model.current.costs += model.n_pruned * model.prune_cost
    pruned = partialsort(model.current.shade_ids, 1:model.n_pruned, rev=true, by = x -> model[x].shade)
    for pr in pruned
        model[pr].shade = model.target_shade
    end
end

function inspect!(model::ABM)
    cofs = sample(model.current.coffee_ids, model.n_inspected, replace = false)
    for c in cofs
        here = collect(agents_in_position(model[c].pos, model))
        if length(here) > 1
            here[2].n_lesions = round(Int, here[2].n_lesions * 0.1)
            here[2].area = round(Int, here[2].area * 0.1)
        end
    end
end

####
## Secondary fnctns
####

function try_travel(rust::AbstractAgent, sun::Float64, model::ABM, factor::String)
    if factor == "r"
        distance = abs(2 * randn(model.rng) * model.rain_distance * model.diff_splash / (1.0 + sun)) # more sun means less kinetic energy
    else
        distance = abs(2 * randn(model.rng) * model.wind_distance * model.wind_protec * sun) # more sun means more wind speed
    end
    heading = rand(model.rng) * 365
    blocked = false
    bound = model.dims
    potential_landing = rust
    position = rust.pos
    if heading == 90.0 || heading == 270.0
        final = round(Int, distance)
        Ys = 0:final
        if final < 0
            Ys = 0:-1:final
        end
        y = 1
        while y <= length(Ys) && !blocked
            if 0 < (position[2] + Ys[y]) <= bound
                potential_landing = collect(agents_in_position((position[1], position[2] + Ys[y]), model))[1]
                # position = potential_landing.pos
                if potential_landing isa Shade && rand(model.rng) < 0.8
                    blocked = true
                    potential_landing = rust
                    break
                else
                    y += 1
                end
            else
                model.current.outpour += 1.0
                potential_landing = rust
                blocked = true
                break
            end
        end
    else
        Ca = abs(cosd(heading) * distance)
        Co = abs(sind(heading) * distance)
        if Ca > Co
            slope = tand(heading)
            final = round(Int, cosd(heading) * distance)
            Xs = 0:final
            if final < 0
                Xs = 0:-1:final
            end
            # println(heading)
            # println(distance)
            x = 1
            # println(Xs)
            while x <= (length(Xs) - 1) && !blocked
                # println("hola")
                yi = round(Int, slope * Xs[x])
                yf = round(Int, slope * Xs[x + 1])
                # println(yi)
                # println(yf)
                for y = yi : yf
                    if 0 < position[2] + y <= bound
                        xcor = position[1] + Xs[x]
                        ycor = position[2] + y
                        if 0 < xcor <= bound
                            potential_landing = collect(agents_in_position((xcor, ycor), model))[1]
                            # println(potential_landing)
                            # position = potential_landing.pos
                        else
                            model.current.outpour += 1.0
                            potential_landing = rust
                            blocked = true
                            break
                        end
                    else
                        model.current.outpour += 1.0
                        potential_landing = rust
                        blocked = true
                        break
                    end
                    if potential_landing isa Shade && rand(model.rng) < 0.8
                        blocked = true
                        potential_landing = rust
                        break
                    end
                end
                x += 1
            end
        else
            slope = tand(heading)
            final = round(Int, sind(heading) * distance)
            Ys = 0:final
            if final < 0
                Ys = 0:-1:final
            end
            # println(heading)
            # println(distance)
            # println(Ys)
            y = 1
            while y <= (length(Ys) - 1) && !blocked
                # println("hola2")
                xi = round(Int, slope * Ys[y])
                xf = round(Int, slope * Ys[y + 1])
                for x = xi : xf
                    if 0 < position[1] + x <= bound
                        xcor = position[1] + x
                        ycor = position[2] + Ys[y]
                        if 0 < ycor <= bound
                            potential_landing = collect(agents_in_position((xcor, ycor), model))[1]
                            # println(potential_landing)
                            # position = potential_landing.pos
                        else
                            model.current.outpour += 1.0
                            potential_landing = rust
                            blocked = true
                            break
                        end
                    else
                        model.current.outpour += 1.0
                        potential_landing = rust
                        blocked = true
                        break
                    end
                    if potential_landing isa Shade && rand(model.rng) < 0.8
                        blocked = true
                        potential_landing = rust
                        break
                    end
                end
                y += 1
            end
        end

    end

    # future upgrade: if by wind, go to the cell after the found shade and deposit there
    return potential_landing
end

function inoculate_rand_rust!(model::ABM, n_rusts::Int) # inoculate random coffee plants
    # move from a random cell outside
    # need to update the path function

    rusted_ids = sample(model.current.coffee_ids, n_rusts, replace = false)

    for rusted in rusted_ids
        here = collect(agents_in_position(model[rusted], model))
        if length(here) > 1
            here[2].n_lesions += 1
        else
            new_id = nextid(model)
            add_agent_pos!(Rust(new_id, here[1].pos, true, 0.01, 0.0, 1, 0, here[1].id), model)
            here[1].hg_id = new_id
            push!(model.current.rust_ids, new_id)
        end
    end
end

function inoculate_rust!(model::ABM, target::AbstractAgent) # inoculate target coffee
    #println("new rust")
    # print("dep")
    # println(target)
    here = collect(agents_in_position(target, model))
    if length(here) > 1
        # println("nlesion")
        if here[2].n_lesions < 26
            here[2].n_lesions += 1
        end
    elseif target isa Coffee
        # println("new")
        new_id = nextid(model)
        add_agent_pos!(Rust(new_id, target.pos, false, 0.0, 0.0, 1, 0, target.id), model)
        target.hg_id = new_id
        push!(model.current.rust_ids, new_id)
    end
end

function calc_wetness_p(local_temp)
    w = (-0.5/16.0) * local_temp + (0.5*30.0/16.0)
end

## Needed to modify it so I could start without Shade agents

function Agents.multi_agent_types!(
    types::Vector{Vector{T} where T},
    utypes::Tuple,
    model::ABM,
    properties::AbstractArray,
)
    types[3] = Symbol[]

    for (i, k) in enumerate(properties)
        current_types = DataType[]
        for atype in utypes
            allatype = Iterators.filter(a -> a isa atype, allagents(model))
            if !isempty(allatype)
                a = first(allatype)
            else
                a = atype(1, (1,1), 0.2, 1.0, 1, 1) # specific to Shades
            end
            if k isa Symbol
                current_type =
                    hasproperty(a, k) ? typeof(Agents.get_data(a, k, identity)) : Missing
            else
                current_type = try
                        typeof(get_data(a, k, identity))
                catch
                    Missing
                end
            end

            isconcretetype(current_type) || warn(
                "Type is not concrete when using $(k) " *
                "on $(atype) agents. Consider narrowing the type signature of $(k).",
            )
            push!(current_types, current_type)
        end
        unique!(current_types)
        if length(current_types) == 1
            current_types[1] <: Missing &&
                error("$(k) does not yield a valid agent property.")
            types[i+3] = current_types[1][]
        else
            types[i+3] = Union{current_types...}[]
        end
    end
end
