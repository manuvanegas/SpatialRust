
function create_farm_map(pars::Parameters)::Array{Int,2}
    side = pars.map_side
    # base
    farm_map = zeros(Int, side, side)

    # add coffees
    for r in 1:pars.row_d:side # these are farm "rows", but in the array they are columns
        for p in 1:pars.plant_d:side
            @inbounds farm_map[p, r] = 1
        end
    end

    # add shades
    if pars.shade_d != 0 && pars.shade_d != side
        if pars.shade_pattern == :regular
            for si in 1:pars.shade_d:side
                for sj in 1:pars.shade_d:side
                    @inbounds farm_map[sj, si] = 2
                end
            end
        else
            nshades = round(Int, (side / pars.shade_d)^2)
            @inbounds farm_map[sample(1:side^2, nshades, replace=false)] .= 2
        end
    end

    arr = pars.barriers
    if @inbounds arr[1] > 0
        placements = @inbounds barr_places(side, arr[1], pars.barrier_rows)

        # internal horizontal barriers
        if pars.barrier_rows == 1 && pars.plant_d == 2 
        # if suggested placement is odd, change it to even to place
        # shades between coffee plants
            @inbounds for pb in placements
                if isodd(pb)
                    @inbounds farm_map[(pb+1), :] .= 2
                else
                    @inbounds farm_map[pb, :] .= 2
                end
            end
        else
            @inbounds farm_map[pb, :] .= 2
        end

        # internal vertical barriers (along coffee rows)
        if pars.row_d == 2 && pars.barrier_rows == 1
            # if suggested placement is odd, change it to even to place
            # shades between coffee rows
            @inbounds for pb in placements
                if isodd(pb)
                    @inbounds farm_map[:, (pb+1)] .= 2
                else
                    @inbounds farm_map[:, pb] .= 2
                end
            end
        elseif pars.row_d == 3
            if pars.barrier_rows == 1
                @inbounds for pb in placements
                    if pb % 3 == 1
                        farm_map[:, (pb+1)] .= 2
                    else
                        @inbounds farm_map[:, pb] .= 2
                    end
                end
            else
                conflicting = findall(x -> (x % 3 == 1), placements)
                for cn in conflicting
                    # determine if cn is in 1st or 2nd half of placements:
                    # 1st half -> initial x's (equal to the result when pars.barrier_rows is 1) 
                    # 2nd half -> extra x's because pars.barrier_rows is 2
                    # eg, barr_places(100,2,1) = [33,66]; barr_places(100,2,2) = [33,66,34,67]
                    @inbounds if cn <= length(placements) / 2
                        placements[[cn, (cn + arr[1])]] .+= 1
                    else
                        placements[[cn, (cn - arr[1])]] .-= 1
                    end
                end
                @inbounds for pb in placements
                    @inbounds farm_map[:, pb] .= 2
                end
            end
        else
            @inbounds for pb in placements
                @inbounds farm_map[:, pb] .= 2
            end
        end
    end

    if arr[2] == 1
        if pars.barrier_rows == 1
            @inbounds farm_map[[1, side], :] .= 2
            @inbounds farm_map[:, [1, side]] .= 2
        else
            @inbounds farm_map[[1, 2, side - 1, side], :] .= 2
            @inbounds farm_map[:, [1, 2, side - 1, side]] .= 2
        end
    end

    return farm_map
end

function create_fullsun_farm_map(side)::Array{Int,2}
    farm_map = zeros(Int, side, side)
    for c in 1:2:side
        @inbounds farm_map[:, c] .= 1
    end
    return farm_map
end

function create_midshade_farm_map()::Array{Int,2}
    farm_map = create_fullsun_farm_map(side)
    for si in 1:6:side
        for sj in 1:6:side
            @inbounds farm_map[sj, si] = 2
        end
    end
    return farm_map
end

## Helper
function barr_places(side::Int, num::Int, singledouble::Int)::Vector{Int}
    spacing = fld(side, (num + 1))
    placements = spacing .* collect(1:num)
    if singledouble == 2
        placements = vcat(placements, (placements .+ 1))
    end
    return placements
end

# function create_bitmap(dims::Int, shade_percent::Float64, fragmentation::Bool = false, random::Bool = true)::BitArray
#     n_shades = round(Int, shade_percent * dims ^ 2)
#     if random == true # random placement of shade trees
#         b_map = trues(dims, dims) # all coffees
#         b_map[sample(1:(dims^2), n_shades, replace = false)] .= false
#     else # produce structured layout
#         if fragmentation == true
#         # TODO: turn fragmentation into Int? -> different levels of fragmentation
#             if (n_shades) > (dims * 6 - 9) # if shade trees are enough to separate space into 4 microlots
#                 b_map = falses(dims,dims)
#                 q_side = dims / 4
#                 coffees_lot, extra = fldmod(((1 - shade_percent) * dims^2)::Float64, 4.0::Float64)
#                 microlot_half_side = (floor(sqrt(coffees_lot)) / 2)
#                 first_q = Int(ceil(q_side))
#                 second_q = Int(ceil(q_side * 3))
#
#                 if microlot_half_side == 0.0 # "radius" of microlot is 0
#                     for x in [first_q, second_q]
#                         for y in [first_q, second_q]
#                             b_map[x, y] = true
#                         end
#                     end
#                 elseif microlot_half_side == 1.0
#                     for x in [first_q, second_q]
#                         for y in [first_q, second_q]
#                             b_map[(x - 1) : x, (y - 1) : y] .= true
#                         end
#                     end
#
#                 elseif microlot_half_side % 1 != 0.0 # "radius" is odd
#                     microlot_half_side = Int(ceil(microlot_half_side - 1))
#                     for x in [first_q, second_q]
#                         for y in [first_q, second_q] # get the (approx) center of each quadrant
#                             b_map[(x - microlot_half_side) : (x + microlot_half_side), (y - microlot_half_side) : (y + microlot_half_side)] .= true
#
#                             rest = coffees_lot - ((microlot_half_side * 2) + 1)^2
#                             extra_x = 0
#                             extra_y = 1
#                             while rest > 0 #add rest of coffee plants
#                                 b_map[(x - microlot_half_side + extra_x), (y - microlot_half_side + extra_y)] = true
#                                 rest = rest - 1
#                                 extra_x = extra_x + 1
#                                 if extra_x > q_side
#                                     extra_x = 0
#                                     extra_y = extra_y + 1
#                                 end
#                             end
#                         end
#                     end
#                 else # "radius" is even
#                     microlot_half_side = Int(microlot_half_side - 1)
#                     for x in [first_q, second_q]
#                         for y in [first_q, second_q] # get the (approx) center of each quadrant
#                             b_map[(x - microlot_half_side - 1) : (x + microlot_half_side), (y - microlot_half_side - 1) : (y + microlot_half_side)] .= true
#
#                             rest = coffees_lot - ((microlot_half_side * 2) + 1)^2
#                             extra_x = 0
#                             extra_y = 1
#                             while rest > 0 #add rest of coffee plants
#                                 b_map[(x - microlot_half_side + extra_x), (y - microlot_half_side + extra_y)] = true
#                                 rest = rest - 1
#                                 extra_x = extra_x + 1
#                                 if extra_x > q_side
#                                     extra_x = 0
#                                     extra_y = extra_y + 1
#                                 end
#                             end
#                         end
#                     end
#                 end
#             else # if shade trees are not enough, divide quadrants until possible
#                 b_map = trues(dims, dims)
#                 half_side = Int(dims / 2)
#                 line_coord = half_side # gets to max 2
#                 x_coor = 1 # gets to max half_side
#                 y_coor = 1
#                 while n_shades > 0
#                     if x_coor <= dims
#                         b_map[x_coor, line_coord] = false
#                         x_coor = x_coor + 1
#                     elseif y_coor <= dims
#                         b_map[line_coord, y_coor] = false
#                         y_coor = y_coor + 1
#                     elseif line_coord == half_side
#                         x_coor = 1
#                         y_coor = 1
#                         line_coord = 1
#                         b_map[x_coor, line_coord] = false
#                         x_coor = x_coor + 1
#                     elseif line_coord == 1
#                         x_coor = 1
#                         y_coor = 1
#                         line_coord = dims
#                         b_map[x_coor, line_coord] = false
#                         x_coor = x_coor + 1
#                     end
#                     n_shades = n_shades - 1
#                 end
#             end
#         else
#             b_map = trues(dims, dims)
#         end
#     end
#     return b_map
# end
