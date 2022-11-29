# Spore dispersal and deposition

function disperse_rain!(model::ABM, rust::Rust)
    d_mod = (4.0 - 4.0 * model.rustpars.diff_splash) * (rust.sunlight - 0.5)^2.0 + model.rustpars.diff_splash
    exp_dist = Exponential(model.rustpars.rain_distance)
    for area in @inbounds rust.areas[rust.spores]
        if rand(model.rng) < area * model.rustpars.spore_pct
            distance = rand(model.rng, exp_dist) * d_mod
            if distance < 1.0 #self-infected
                @inbounds rust.deposited += 1.0
            else
                # follow splash and return: Tuple > 0 -> Coffee pos, < 0 -> outpour direction (see setup for mappings), 0 -> nothing
                fin_pos = splash(rust.pos, distance, rand(model.rng) * 360.0, model.farm_map, model.rustpars)
                if any(fin_pos .> 0) && (c = @inbounds model[fin_pos]).exh_countdown == 0
                    c.deposited += 1.0
                    push!(model.current.rusts, c)
                elseif any(fin_pos .< 0) 
                    model.outpour[sum(fin_pos .* (-3,-1))] += 1.0
                end
            end
        end
    end


    # for lesion in 1:rust.n_lesions
    #     if @inbounds rust.spores &&
    #         @inbounds rand(model.rng) < (rust.state[2, lesion] * model.pars.spore_pct)
    #         r_rust_dispersal!(model, rust, sunlight)
    #     end
    # end
end


function disperse_wind!(model::ABM, rust::Rust)
    shading = @inbounds model.shade_map[rust.pos...]
    w_distance = rand(model.rng, Exponential(model.rustpars.wind_distance)) * (1 + rust.sunlight * rust.rustpars.diff_wind)
    if w_distance < 1.0
        for area in @inbounds rust.areas[rust.spores]
            if rand(model.rng) < area * model.rustpars.spore_pct * shading
                @inbounds rust.deposited += 1.0
            end
        end
    else
        for area in @inbounds rust.areas[rust.spores]
            if rand(model.rng) < area * model.rustpars.spore_pct * shading
                fin_pos = gust(rust.pos, w_distance,
                    (model.current.wind_h + (rand(model.rng) * 30.0) - 15.0),
                    model.farm_map, model.shade_map, model.rustpars)

                if any(fin_pos .> 0) && (c = @inbounds model[fin_pos]).exh_countdown == 0
                    c.deposited += 1.0
                    push!(model.current.rusts, c)
                elseif any(fin_pos .< 0) 
                    model.outpour[sum(fin_pos .* (-3,-1))] += 1.0
                end
            end
        end
    end

    # if rand(model.rng) < model.pars.wind_disp_prob
    # if model.current.wind
    # let wdistance = abs(2.0 * randn(model.rng)) * model.pars.wind_distance * model.pars.diff_wind * sunlight
    #     for lesion in 1:rust.n_lesions
    #         if @inbounds rust.state[3, lesion] == 1.0 &&
    #             @inbounds rand(model.rng) < (rust.state[2, lesion] * model.pars.spore_pct)
    #             w_rust_dispersal!(model, rust, wdistance)
    #         end
    #     end
    # end
end

function splash(pos::NTuple{2,Int}, dist::Float64, heading::Float64, farm_map::Array{Int, 2}, rustpars::RustPars)
    let ca = cosd(heading), co = sind(heading), stepx = (1, 0), stepy = (0, 1),
        side = rustpars.map_side, prob_block = rustpars.tree_block, pos = pos

        notlanded = true
        infarm = true
        # traveled = 0.5
        onx = 0.0
        ony = 0.0
        advanced = false

        for traveled in 0.5:0.5:distance
            # traveled += 0.5
            # if traveled < dist
            newx = floor(ca * traveled)
            newy = floor(co * traveled)
            if newx != onx
                onx = newx
                pos = pos .+ stepx
                advanced = true
            end
            if newy != ony
                ony = newy
                pos = pos .+ stepy
                advanced = true
            end
            if advanced
                withinbounds = (pos .< 1) .* -1 .+ (pos .> side) .* -2
                if any(withinbounds < 0)
                    return withinbounds
                else
                # if all(1 .<= pos .<= side)
                    if @inbounds (id = farm_map[pos...]) == 1 && rand(rng) < prob_block
                        # notlanded = false
                        return pos
                    elseif id == 2 && rand(rng) < prob_block
                        return (0,0)
                    end
                end
            end
            advanced = false
        end

        if @inbounds farm_map[pos...] == 1
            return pos
        else
            return (0,0)
        end

    end
end

function gust(pos::NTuple{2,Int}, dist::Float64, heading::Float64, farm_map::Array{Int,2}, shade_map::Array{Float64, 2}, rustpars::RustPars)
    let ca = cosd(heading), co = sind(heading), stepx = (1, 0), stepy = (0, 1),
        side = rustpars.map_side, prob_block = rustpars.shade_block, pos = pos

        notlanded = true
        notblocked = true
        onx = 0.0
        ony = 0.0
        advanced = false

        for traveled in 0.5:0.5:distance
            # traveled += 0.5
            # if traveled < dist
            newx = floor(ca * traveled)
            newy = floor(co * traveled)
            if newx != onx
                onx = newx
                pos = pos .+ stepx
                advanced = true
            end
            if newy != ony
                ony = newy
                pos = pos .+ stepy
                advanced = true
            end
            if advanced
                withinbounds = (pos .< 1) .* -1 .+ (pos .> side) .* -2
                if any(withinbounds < 0)
                    return withinbounds
                else
                    if notblocked
                        if rand(rng) < @inbounds shade_map[pos...] * shade_block
                            notblocked = false
                        end
                    else
                        if @inbounds farm_map[pos...] == 1
                            return pos
                        else
                            return (0,0)
                        end
                    end
                end
            end
            advanced = false
        end

        if @inbounds farm_map[pos...] == 1
            return pos
        else
            return (0,0)
        end
    end
end

## Dispersal from outside the farm

function outside_spores!(model::ABM)
    heading = model.current.wind_h
    side = model.rustpars.map_side
    expdist = Exponential(model.rustpars.wind_distance)
    outsp = model.outpour
    deposited = sizehint!(NTuple{2,Int}[], sum(outsp))
    if isapprox(heading, 360.0; atol = 2.0) || isapprox(heading, 0.0; atol = 2.0)
        # cosd(2) ≈ 0.99939, which is just horizontal for a 100x100 farm
        for i in 1.0:outsp[1]
            push!(deposited, try_outside_disp!(model.rng, heading, model.farm_map, model.shade_map,
            model.rustpars, expdist, 1))
        end
    elseif heading < 90.0
        for q in (1,7,6), sp in 1.0:outsp[q]
            push!(deposited, try_outside_disp!(model.rng, heading, model.farm_map, model.shade_map,
            model.rustpars, expdist, q))
        end
    elseif isapprox(heading, 90.0; atol = 2.0) 
        for i in 1.0:outsp[6]
            push!(deposited, try_outside_disp!(model.rng, heading, model.farm_map, model.shade_map,
            model.rustpars, expdist, 6))
        end
    elseif heading < 180.0
        for q in (6,8,2), sp in 1.0:outsp[q]
            push!(deposited, try_outside_disp!(model.rng, heading, model.farm_map, model.shade_map,
            model.rustpars, expdist, q))
        end
    elseif isapprox(heading, 180.0; atol = 2.0)
        for i in 1.0:outsp[2]
            push!(deposited, try_outside_disp!(model.rng, heading, model.farm_map, model.shade_map,
            model.rustpars, expdist, 2))
        end
    elseif heading < 270.0
        for q in (2,5,3), sp in 1.0:outsp[q]
            push!(deposited, try_outside_disp!(model.rng, heading, model.farm_map, model.shade_map,
            model.rustpars, expdist, q))
        end
    elseif isapprox(heading, 270.0; atol = 2.0)
        for i in 1.0:outsp[3]
            push!(deposited, try_outside_disp!(model.rng, heading, model.farm_map, model.shade_map,
            model.rustpars, expdist, 3))
        end
    else
        for q in (3,4,1), sp in 1.0:outsp[q]
            push!(deposited, try_outside_disp!(model.rng, heading, model.farm_map, model.shade_map,
            model.rustpars, expdist, q))
        end
    end

    for dep in filter!(t -> any(t .> 0), deposited)
        c = @inbounds model[dep]
        if c.exh_countdown == 0
            c.deposited += 1.0
            push!(model.current.rusts, c)
        end
    end
end

function try_outside_disp!(rng, heading::Float64, farm_map::Array{Int},
    shade_map::Array{Float64}, rp::RustPars, expdist::Exponential{Float64}, q::Int)

    startpos = starting_pos(rng, side, q)
    distance = rand(rng, expdist) * (1 + model[startpos...].sunlight * rp.diff_wind)
    return gust(startpos, distance, (heading + (rand(rng) * 30.0) - 15.0), farm_map, shade_map, rp)
end

function starting_pos(rng, side::Int, q::Int)
    if q == 1 # quadrant to the left
        return (sample(rng, 1:side), 1)
    elseif q == 7 # quadrant in the down-left diagonal
        quarter = fld(side, 4)
        randcoor = sample(rng, [1,2])
        if randcoor == 1
            return (sample(rng, (3*quarter+1):side), side)
        else
            return (1, sample(rng, 1:quarter))
        end
    elseif q == 6 # quadrant below
        return (side, sample(rng, 1:side))
    elseif q == 8 # quadrant in the down-right diagonal
        quarter = fld(side, 4)
        return (sample(rng, (3*quarter+1):side), side)[shuffle!(rng, [1,2])]
    elseif q == 2 # quadrant to the right
        return (sample(rng, 1:side), side)
    elseif q == 5 # quadrant in the up-right diagonal
        quarter = fld(side, 4)
        randcoor = sample(rng, [1,2])
        if randcoor == 1
            return (sample(rng, 1:quarter), side)
        else
            return (1, sample(rng, (3*quarter+1):side))
        end
    elseif q == 3 # quadrant above
        return (1, sample(rng, 1:side))
    else # q = 4, quadrant in the up-left diagonal
        quarter = fld(side, 4)
        return (sample(rng, 1:quarter), 1)[shuffle!(rng, [1,2])]
    end
end


# function r_rust_dispersal!(model::ABM, rust::Rust, sunlight::Float64)
#     let distance = abs(2.0 * randn(model.rng) * model.pars.rain_distance) *
#         ((sunlight - 0.55)^2.0 * ((1.0 - model.pars.diff_splash) * inv(0.2025)) + model.pars.diff_splash)

#         rain_travel!(CartesianIndex(rust.pos), distance, rand(model.rng) * 360.0)
#     end
# end

# function w_rust_dispersal!(model::ABM, rust::Rust, wdistance::Float64)
#     wind_travel!(model, CartesianIndex(rust.pos), wdistance, (model.current.wind_h + (rand(model.rng) * 5) - 2.5))
# end

# function rain_travel!(pos::CartesianIndex{2}, dist::Float64, heading::Float64)
#     let ca = cosd(heading), co = sind(heading), prob_block = model.pars.tree_block * 0.5
#         notlanded = true
#         infarm = true
#         traveled = 0.5
#         onx = 0.0
#         ony = 0.0
#         stepx = CartesianIndex(1, 0)
#         stepy = CartesianIndex(0, 1)
#         advanced = false
#         new_pos = pos
#         side = model.pars.map_side

#         if dist < 1.0 # then it will stay in the same coffee
#             notlanded = false
#         end

#         while notlanded && infarm
#             traveled += 0.5
#             if traveled < dist
#                 # new_pos = next_pos(pos, ca, co, traveled)
#                 newx = floor(ca * traveled)
#                 newy = floor(co * traveled)
#                 if newx != onx
#                     onx = newx
#                     new_pos += stepx
#                     advanced = true
#                 end
#                 if newy != ony
#                     ony = newy
#                     new_pos += stepy
#                     advanced = true
#                 end
#                 if advanced
#                     if in_farm(new_pos, side)
#                         here = @inbounds model.farm_map[new_pos]
#                         if here == 2 || (here == 1 && first(agents_in_position(Tuple(new_pos),model)).exh_countdown == 0)
#                             if rand(model.rng) < prob_block
#                                 notlanded = false
#                             end
#                         end
#                     else
#                         infarm = false
#                     end
#                 end
#                 advanced = false
#             else
#                 notlanded = false
#             end
#         end

#         if !infarm
#             # placeholder for future functionality: keep track of outpour to 8 neighbors
#         end

#         if !notlanded
#             trees = agents_in_position(Tuple(new_pos), model)
#             if !isempty(trees)
#                 inoculate_rust!(model, first(trees))
#             end
#         end
#     end
# end

# function wind_travel!(model::ABM, pos::CartesianIndex{2}, dist::Float64, heading::Float64)
#     let ca = cosd(heading), co = sind(heading), shade_block = model.pars.tree_block
#         notlanded = true
#         infarm = true
#         notblocked = true
#         traveled = 0.5
#         onx = 0.0
#         ony = 0.0
#         stepx = CartesianIndex(1,0)
#         stepy = CartesianIndex(0,1)
#         advanced = false
#         new_pos = pos
#         side = model.pars.map_side

#         while notlanded && infarm
#             traveled += 0.5
#             if traveled < dist
#                 # new_pos = next_pos(pos, ca, co, traveled)
#                 newx = floor(ca * traveled)
#                 newy = floor(co * traveled)
#                 if newx != onx
#                     onx = newx
#                     new_pos += stepx
#                     advanced = true
#                 end
#                 if newy != ony
#                     ony = newy
#                     new_pos += stepy
#                     advanced = true
#                 end
#                 if advanced
#                     if in_farm(new_pos, side)
#                         if notblocked
#                             if is_wind_blocked_shade(model.rng, new_pos, model.shade_map, shade_block)
#                                 notblocked = false
#                             end
#                         else
#                             notlanded = false
#                         end
#                     else
#                         infarm = false
#                     end
#                 end
#                 advanced = false
#             else
#                 notlanded = false
#             end
#         end

#         if !infarm
#             # placeholder for future functionality: keep track of outpour to 8 neighbors
#         end

#         if !notlanded
#             trees = agents_in_position(Tuple(new_pos), model)
#             if !isempty(trees)
#                 inoculate_rust!(model, first(trees))
#             end
#         end
#     end
# end

## Helpers

# function next_pos(pos::CartesianIndex{2}, ca::Float64, co::Float64, traveled::Float64)::CartesianIndex{2}
#     return pos + CartesianIndex(ca * traveled, co * traveled)
# end #not in use

# function is_droplet_blocked(rng, pos::CartesianIndex{2}, farm_map::Matrix{Int}, shade_block::Float64)
#     if @inbounds farm_map[pos] == 0
#         return false
#     else
#         return rand(rng) < shade_block
#     end
# end # not in use

# function is_wind_blocked_shade(rng, pos::CartesianIndex{2}, shade_map::Matrix{Float64}, shade_block::Float64)
#     return rand(rng) < (@inbounds shade_map[pos]) * shade_block
# end

## When dispersal is successful, create new Rusts

# function inoculate_rust!(model::ABM, target::Coffee) # inoculate target coffee
#     # here = collect(agents_in_position(target, model))
#     if target.hg_id != 0
#         if model[target.hg_id].n_lesions < model.pars.max_lesions
#             model[target.hg_id].n_lesions += 1
#         end
#     elseif target.exh_countdown == 0
#     # else
#         new = add_agent!(target.pos, Rust, model, model.pars.max_lesions, model.pars.steps;
#             hg_id = target.id, sample_cycle = target.sample_cycle)
#         target.hg_id = new.id
#         push!(model.current.rusts, new)
#     end
# end

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
                            (blockedwind || s == last(path) || rand(model.rng) < model.pars.tree_block * 0.1)
                                push!(inoc_ids, c.id)
                                break
                        elseif rand(model.rng) < model.pars.tree_block # blocked by shade
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
