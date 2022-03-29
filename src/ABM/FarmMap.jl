

function create_farm_map(parameters::Parameters)
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


function create_fullsun_farm_map()
    farm_map = zeros(Int,100,100)
    for c in 1:2:100
        farm_map[:,c] .= 1
    end
    return farm_map
end
