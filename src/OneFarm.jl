###
## Shade
###

function grow!(tree::Shade, rate::Float64)
    tree.shade += rate * (1.0 - tree.shade / 0.9)
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
end

function acc_production!(cof::Coffee) # accumulate production
    cof.production += (cof.area / 25.0) * cof.sunlight
end

###
## Rust
###

function disperse!(rust::Rust, cof::Coffee, model::ABM)
    prog = 1 / (1 + (0.25 / (rust.area + (rust.n_lesions / 25.0)))^4)

    if model.rain && rand() < model.p_density * prog
        # model.p_density * prog  #(rust.n_lesions * rust.area) / (2 + rust.n_lesions * rust.area)
        # (rust.n_lesions * rust.spores / (25.0 * model.spore_pct)) * model.p_density
        target = try_travel(rust, cof.sunlight, model, "r")
        # println("obt")
        # println(target)
        if target !== rust
            deposit_on!(target, model)
        end
    end

    if model.wind && rand() < model.p_density * prog
        # model.p_density * prog
        # (rust.n_lesions * rust.spores / (25.0 * model.spore_pct)) * model.p_density
        target = try_travel(rust, cof.sunlight, model, "w")
        if target !== rust
            deposit_on!(target, model)
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
            model.rust_ids = filter(i -> i != rm_id, model.rust_ids)
        end
    end
end

function grow!(rust::Rust, cof::Coffee, model::ABM)

    local_temp = model.temperature - (model.temp_cooling * (1.0 - cof.sunlight))

    if rust.germinated && 14 < local_temp < 30 # grow and sporulate

        #  logistic growth (K=1) * rate due to fruit load * rate due to temperature
        rust.area += rust.area * (1 - rust.area) *
            #(model.fruit_load * (1 / (1 + (30 / cof.production))^2)) *
            model.fruit_load * cof.production / model.harvest_cycle
            (-0.0178 * ((local_temp - 22.5) ^ 2.0) + 1.0)

        if rust.spores === 0.0
            if rand() < (rust.area * (local_temp + 5) / 30) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
                rust.spores = rust.area * model.spore_pct
            end
        else
            rust.spores = rust.area * model.spore_pct
        end

    else # try to germinate + penetrate tissue
        let r = rand()
            if r < (cof.sunlight * model.uv_inact) || r <  (cof.sunlight * (model.rain ? model.rain_washoff : 0.0))
                # higher % sunlight means more chances of inactivation by UV or rain
                rm_id = rust.id
                kill_agent!(rust, model)
                model.rust_ids = filter(i -> i != rm_id, model.rust_ids)
            else
                if rand() < calc_wetness_p(local_temp - (model.rain ? 6.0 : 0.0))
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
    ids = model.coffee_ids
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
    model.gains += model.coffee_price * harvest * model.p_density
    model.yield += harvest / (model.dims^2)
end

function fungicide!(model::ABM)
    # apply fungicide
    # add to costs
end

function prune!(model::ABM)
    model.costs += model.n_pruned * model.prune_cost
    pruned = partialsort(model.shade_ids, 1:model.n_pruned, rev=true, by = x -> model[x].shade)
    for pr in pruned
        model[pr].shade = model.target_shade
    end
end

function inspect!(model::ABM)
    cofs = sample(model.coffee_ids, round(Int,length(model.coffee_ids) * 0.05), replace = false)
    for c in cofs
        here = get_node_agents(model[c].pos, model)
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
        distance = abs(2 * randn() * model.rain_distance * model.diff_splash / (1.0 + sun)) # more sun means less kinetic energy
    else
        distance = abs(2 * randn() * model.wind_distance * model.wind_protec * sun) # more sun means more wind speed
    end
    heading = rand() * 365
    blocked = false
    bound = sqrt(nv(model))
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
                potential_landing = get_node_agents((position[1], position[2] + Ys[y]), model)[1]
                # position = potential_landing.pos
                if potential_landing isa Shade && rand() < 0.8
                    blocked = true
                    potential_landing = rust
                    break
                else
                    y += 1
                end
            else
                model.outpour += 1.0
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
                            potential_landing = get_node_agents((xcor, ycor), model)[1]
                            # println(potential_landing)
                            # position = potential_landing.pos
                        else
                            model.outpour += 1.0
                            potential_landing = rust
                            blocked = true
                            break
                        end
                    else
                        model.outpour += 1.0
                        potential_landing = rust
                        blocked = true
                        break
                    end
                    if potential_landing isa Shade && rand() < 0.8
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
                            potential_landing = get_node_agents((xcor, ycor), model)[1]
                            # println(potential_landing)
                            # position = potential_landing.pos
                        else
                            model.outpour += 1.0
                            potential_landing = rust
                            blocked = true
                            break
                        end
                    else
                        model.outpour += 1.0
                        potential_landing = rust
                        blocked = true
                        break
                    end
                    if potential_landing isa Shade && rand() < 0.8
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

function deposit_on!(target::AbstractAgent, model::ABM)
    # print("dep")
    # println(target)
    here = get_node_agents(target, model)
    if length(here) > 1
        # println("nlesion")
        if here[2].n_lesions < 26
            here[2].n_lesions += 1
        end
    elseif target isa Coffee
        # println("new")
        new_id = nextid(model)
        add_agent_pos!(Rust(new_id, target.pos, false, 0.0, 0.0, 1), model)
        push!(model.rust_ids, new_id)
    end
end

function calc_wetness_p(local_temp)
    w = (-0.5/16.0) * local_temp + (0.5*30.0/16.0)
end


function tryyy(n)
    for i = 1:n
        for j = 2:4
            if j == 3 continue end
            println(i,j)
        end
    end
end
