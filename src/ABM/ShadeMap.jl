
# function create_shade_map(farm_map::Matrix{Int}, shade_r::Int, side::Int)
#     possible_ns = CartesianIndices((-shade_r:shade_r, -shade_r:shade_r))
#     shades = findall(==(2), farm_map)
#     shade_map = zeros(size(farm_map))
#     for sh in shades
#         shade_map[sh] += 1.0
#         neighs = Iterators.filter(x -> in_farm(x, side), sh + n for n in possible_ns)
#         for n in neighs
#             shade_map[n] += 1.0 / shade_dist(sh, n)
#         end
#     end
#     clamp!(shade_map, 0.0, 1.0)
#     return shade_map
# end

# function shade_dist(pos1::CartesianIndex{2}, pos2::CartesianIndex{2})::Float64
#     caths = pos1 - pos2
#     @inbounds dist = sqrt(caths[1]^2 + caths[2]^2)
#     return dist + 0.05
# end

# function in_farm(coord::CartesianIndex, side::Int)::Bool
#     @inbounds for d in 1:2
#         1 <= coord[d] <= side || return false
#     end
#     return true
# end



# function create_shade_map(farm_map::Matrix{Int}, shade_r::Int, side::Int)
#     crown = CartesianIndices((-shade_r:shade_r, -shade_r:shade_r))
#
#     fmap = copy(farm_map)
#     fmap[[50, 51],:] .= 0
#     fmap[:, [50, 51]] .= 0
#     shades = findall(==(2), fmap)
#
#     shade_map = zeros(size(farm_map))
#     influence_map = zeros(size(farm_map))
#
#     for sh in shades
#         neighs = Iterators.filter(x -> in_farm(x, side), sh + n for n in crown)
#
#         for n in neighs
#             diff = n - sh
#             if n in shades
#                 @inbounds shade_map[n] = 1.0
#                 @inbounds influence_map[n] = 1.0
#             else
#                 @inbounds shade_map[n] += 1.0 / (shade_dist(diff) ^ 2)
#                 @inbounds influence_map[n] += 1.0 / cmax(diff) 
#             end
#         end
#     end
#
#     shade_map ./= ifelse.(influence_map .== 0.0, 1.0, influence_map ./ 2)
#     clamp!(shade_map, 0.0, 1.0)
#
#     if farm_map[50, 1] == 2
#         @inbounds shade_map[50, :] .= 1.0
#         @inbounds shade_map[49, :] .= max.(1.0 / (1.05 ^ 2), @inbounds shade_map[49, :])
#         @inbounds shade_map[48, :] .= max.(1.0 / (2.05 ^ 2), @inbounds shade_map[48, :])
#         @inbounds shade_map[:, 50] .= 1.0
#         @inbounds shade_map[:, 49] .= max.(1.0 / (1.05 ^ 2), @inbounds shade_map[:, 49])
#         @inbounds shade_map[:, 48] .= max.(1.0 / (2.05 ^ 2), @inbounds shade_map[:, 49])
#         if farm_map[51, 1] == 2
#             @inbounds shade_map[51, :] .= 1.0
#             @inbounds shade_map[52, :] .= max.(1.0 / (1.05 ^ 2), @inbounds shade_map[52, :])
#             @inbounds shade_map[53, :] .= max.(1.0 / (2.05 ^ 2), @inbounds shade_map[53, :])
#             @inbounds shade_map[:, 51] .= 1.0
#             @inbounds shade_map[:, 52] .= max.(1.0 / (1.05 ^ 2), @inbounds shade_map[:, 52])
#             @inbounds shade_map[:, 53] .= max.(1.0 / (2.05 ^ 2), @inbounds shade_map[:, 53])
#         else
#             @inbounds shade_map[51, :] .= max.(1.0 / (1.05 ^ 2), @inbounds shade_map[51, :])
#             @inbounds shade_map[52, :] .= max.(1.0 / (2.05 ^ 2), @inbounds shade_map[52, :])
#             @inbounds shade_map[:, 51] .= max.(1.0 / (1.05 ^ 2), @inbounds shade_map[:, 51])
#             @inbounds shade_map[:, 52] .= max.(1.0 / (2.05 ^ 2), @inbounds shade_map[:, 52])
#         end
#     end
#
#     return shade_map
# end
    
# cmax(c::CartesianIndex) = maximum(abs.(Tuple(c)))

# shade_dist(d::Int)::Float64 = d + 0.05

# function shade_dist(caths::CartesianIndex{2})::Float64
#     @inbounds dist = sqrt(caths[1]^2 + caths[2]^2)
#     return dist == 0.0 ? 1.0 : (dist + 0.05)
# end

# function shade_dist(pos1::CartesianIndex{2}, pos2::CartesianIndex{2})::Float64
#     caths = pos1 - pos2
#     @inbounds dist = sqrt(caths[1]^2 + caths[2]^2)
#     return dist == 0.0 ? 1.0 : (dist + 0.05)
# end

function in_farm(coord::CartesianIndex, side::Int)::Bool
    @inbounds for d in 1:2
        1 <= coord[d] <= side || return false
    end
    return true
end

function create_shade_map(farm_map::Matrix{Int}, shade_r::Int, side::Int, common_map::Symbol)

    shade_map = zeros(size(farm_map))
    
    if common_map != :fullsun
        maxdist = (2 * shade_r)^2
        crown = Iterators.filter(c -> c != CartesianIndex(0,0), CartesianIndices((-shade_r:shade_r, -shade_r:shade_r)))

        for coord in CartesianIndices(farm_map)
            if farm_map[coord] == 2
                shade_map[coord] = 1.0
            else
                neighs = (n for n in Iterators.filter(r -> in_farm(coord + r, side),
                    crown) if farm_map[coord + n] == 2
                )
                if !isempty(neighs)
                    shade_map[coord] = 1.0 - minimum(eucdist(n) for n in neighs) / maxdist
                end
            end
        end

    end

    return shade_map
end

eucdist(d::CartesianIndex{2})::Float64 = d[1]^2 + d[2]^2
