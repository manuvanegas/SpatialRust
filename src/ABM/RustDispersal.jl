# Spore dispersal and deposition

function disperse_rain!(model::SpatialRustABM, rust::Coffee)
    d_mod = (4.0 - 4.0 * model.rustpars.diff_splash) * (rust.sunlight - 0.5)^2.0 + model.rustpars.diff_splash
    exp_dist = Exponential(model.rustpars.rain_distance)
    for area in @inbounds rust.areas[rust.spores]
        if rand(model.rng) < area * model.rustpars.spore_pct
            distance = rand(model.rng, exp_dist) * d_mod
            if distance < 1.0 #self-infected
                rust.newdeps += 1.0
            else
                # follow splash and return: Tuple > 0 -> Coffee pos, < 0 -> outpour direction (see setup for mappings), 0 -> nothing
                fin_pos = splash(model.rng, rust.pos, distance,rand(model.rng) * 360.0, model.farm_map, model.rustpars)
                if any(fin_pos .> 0) && 
                    (c = (@inbounds model[id_in_position(fin_pos,model)])).exh_countdown == 0
                    c.newdeps += 1.0
                    # existing = c in model.rusts
                    push!(model.rusts, c)
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


function disperse_wind!(model::SpatialRustABM, rust::Coffee)
    shading = @inbounds model.shade_map[rust.pos...]
    w_distance = rand(model.rng, Exponential(model.rustpars.wind_distance)) * (1 + rust.sunlight * model.rustpars.diff_wind)
    if w_distance < 1.0
        for area in @inbounds rust.areas[rust.spores]
            if rand(model.rng) < area * model.rustpars.spore_pct * shading
                rust.newdeps += 1.0
            end
        end
    else
        for area in @inbounds rust.areas[rust.spores]
            if rand(model.rng) < area * model.rustpars.spore_pct * shading
                fin_pos = gust(model.rng, rust.pos, w_distance,
                    (model.current.wind_h + (rand(model.rng) * 30.0) - 15.0),
                    model.farm_map, model.shade_map, model.rustpars)
                if any(fin_pos .> 0) && 
                    (c = (@inbounds model[id_in_position(fin_pos,model)])).exh_countdown == 0
                    c.newdeps += 1.0
                    # existing = c in model.rusts
                    push!(model.rusts, c)
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

function splash(rng, pos::NTuple{2,Int}, dist::Float64, heading::Float64, farm_map::Array{Int, 2}, rustpars::RustPars)
    let ca = cosd(heading), co = sind(heading), stepx = (1, 0), stepy = (0, 1),
        side = rustpars.map_side, prob_block = rustpars.tree_block, pos = pos

        notlanded = true
        infarm = true
        # traveled = 0.5
        onx = 0.0
        ony = 0.0
        advanced = false

        for traveled in 0.5:0.5:dist
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
                if any(withinbounds .< 0)
                    return withinbounds
                else
                # if all(1 .<= pos .<= side)
                    if @inbounds (id = farm_map[pos...]) == 1 && (rand(rng) < prob_block)
                        # notlanded = false
                        return pos
                    elseif id == 2 && (rand(rng) < prob_block)
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

function gust(rng, pos::NTuple{2,Int}, dist::Float64, heading::Float64, farm_map::Array{Int,2}, shade_map::Array{Float64, 2}, rustpars::RustPars)
    let ca = cosd(heading), co = sind(heading), stepx = (1, 0), stepy = (0, 1),
        side = rustpars.map_side, prob_block = rustpars.shade_block, pos = pos

        notlanded = true
        notblocked = true
        onx = 0.0
        ony = 0.0
        advanced = false

        for traveled in 0.5:0.5:dist
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
                if any(withinbounds .< 0)
                    return withinbounds
                else
                    if notblocked
                        if rand(rng) < @inbounds shade_map[pos...] * prob_block
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

function outside_spores!(model::SpatialRustABM)
    heading = model.current.wind_h
    side = model.rustpars.map_side
    expdist = Exponential(model.rustpars.wind_distance)
    outsp = model.outpour
    deposited = sizehint!(NTuple{2,Int}[], sum(trunc.(Int,outsp)))
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
        c = (model[id_in_position(dep, model)])
        if c.exh_countdown == 0
            # existing = c.id in model.rusts
            c.newdeps += 1.0
            push!(model.rusts, c)
        end
    end
end

function try_outside_disp!(rng, heading::Float64, farm_map::Array{Int},
    shade_map::Array{Float64}, rp::RustPars, expdist::Exponential{Float64}, q::Int)

    startpos = starting_pos(rng, rp.map_side, q)
    distance = rand(rng, expdist) * (1 + rp.diff_wind)
    return gust(rng, startpos, distance, (heading + (rand(rng) * 30.0) - 15.0), farm_map, shade_map, rp)
end

function starting_pos(rng, side::Int, q::Int)
    if q == 1 # quadrant to the left
        return (rand(rng, 1:side), 1)
    elseif q == 7 # quadrant in the down-left diagonal
        quarter = fld(side, 4)
        randcoor = rand(rng, [1,2])
        if randcoor == 1
            return (rand(rng, (3*quarter+1):side), side)
        else
            return (1, rand(rng, 1:quarter))
        end
    elseif q == 6 # quadrant below
        return (side, rand(rng, 1:side))
    elseif q == 8 # quadrant in the down-right diagonal
        quarter = fld(side, 4)
        return (rand(rng, (3*quarter+1):side), side)[shuffle!(rng, [1,2])]
    elseif q == 2 # quadrant to the right
        return (rand(rng, 1:side), side)
    elseif q == 5 # quadrant in the up-right diagonal
        quarter = fld(side, 4)
        randcoor = rand(rng, [1,2])
        if randcoor == 1
            return (rand(rng, 1:quarter), side)
        else
            return (1, rand(rng, (3*quarter+1):side))
        end
    elseif q == 3 # quadrant above
        return (1, rand(rng, 1:side))
    else # q = 4, quadrant in the up-left diagonal
        quarter = fld(side, 4)
        return (rand(rng, 1:quarter), 1)[shuffle!(rng, [1,2])]
    end
end