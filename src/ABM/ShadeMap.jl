
function create_shade_map(farm_map::Matrix{Int}, shade_r::Int, side::Int)
    possible_ns = CartesianIndices((-shade_r:shade_r, -shade_r:shade_r))
    shades = findall(==(2), farm_map)
    shade_map = zeros(size(farm_map))
    for sh in shades
        shade_map[sh] += 1.0
        neighs = Iterators.filter(x -> in_farm(x, side), sh + n for n in possible_ns)
        for n in neighs
            shade_map[n] += 1.0 / shade_dist(sh, n)
        end
    end
    clamp!(shade_map, 0.0, 1.0)
    return shade_map
end

function shade_dist(pos1::CartesianIndex{2}, pos2::CartesianIndex{2})::Float64
    caths = pos1 - pos2
    @inbounds dist = sqrt(caths[1]^2 + caths[2]^2)
    return dist + 0.05
end

function in_farm(coord::CartesianIndex, side::Int)::Bool
    @inbounds for d in 1:2
        1 <= coord[d] <= side || return false
    end
    return true
end