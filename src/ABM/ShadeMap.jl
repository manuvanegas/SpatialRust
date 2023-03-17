
function create_shade_map(farm_map::Matrix{Int}, shade_r::Int, side::Int)
    crown = CartesianIndices((-shade_r:shade_r, -shade_r:shade_r))

    fmap = copy(farm_map)
    fmap[[50, 51],:] .= 0
    fmap[:, [50, 51]] .= 0
    shades = findall(==(2), fmap)

    shade_map = zeros(size(farm_map))
    influence_map = zeros(size(farm_map))

    for sh in shades
        neighs = Iterators.filter(x -> in_farm(x, side), sh + n for n in crown)

        for n in neighs
            diff = n - sh
            if n in shades
                @inbounds shade_map[n] = 1.0
                @inbounds influence_map[n] = 1.0
            else
                @inbounds shade_map[n] += 1.0 / (shade_dist(diff) ^ 2)
                @inbounds influence_map[n] += 1.0 / cmax(diff) 
            end
        end
    end

    shade_map ./= ifelse.(influence_map .== 0.0, 1.0, influence_map ./ 2)
    clamp!(shade_map, 0.0, 1.0)

    if farm_map[50, 1] == 2
        @inbounds shade_map[50, :] .= 1.0
        @inbounds shade_map[49, :] .= max.(1.0 / (shade_dist(1) ^ 2), @inbounds shade_map[49, :])
        @inbounds shade_map[48, :] .= max.(1.0 / (shade_dist(2) ^ 2), @inbounds shade_map[48, :])
        @inbounds shade_map[:, 50] .= 1.0
        @inbounds shade_map[:, 49] .= max.(1.0 / (shade_dist(1) ^ 2), @inbounds shade_map[:, 49])
        @inbounds shade_map[:, 48] .= max.(1.0 / (shade_dist(2) ^ 2), @inbounds shade_map[:, 49])
        if farm_map[51, 1] == 2
            @inbounds shade_map[51, :] .= 1.0
            @inbounds shade_map[52, :] .= max.(1.0 / (shade_dist(1) ^ 2), @inbounds shade_map[52, :])
            @inbounds shade_map[53, :] .= max.(1.0 / (shade_dist(2) ^ 2), @inbounds shade_map[53, :])
            @inbounds shade_map[:, 51] .= 1.0
            @inbounds shade_map[:, 52] .= max.(1.0 / (shade_dist(1) ^ 2), @inbounds shade_map[:, 52])
            @inbounds shade_map[:, 53] .= max.(1.0 / (shade_dist(2) ^ 2), @inbounds shade_map[:, 53])
        else
            @inbounds shade_map[51, :] .= max.(1.0 / (shade_dist(1) ^ 2), @inbounds shade_map[51, :])
            @inbounds shade_map[52, :] .= max.(1.0 / (shade_dist(2) ^ 2), @inbounds shade_map[52, :])
            @inbounds shade_map[:, 51] .= max.(1.0 / (shade_dist(1) ^ 2), @inbounds shade_map[:, 51])
            @inbounds shade_map[:, 52] .= max.(1.0 / (shade_dist(2) ^ 2), @inbounds shade_map[:, 52])
        end
    end

    return shade_map
end
    

function in_farm(coord::CartesianIndex, side::Int)::Bool
    @inbounds for d in 1:2
        1 <= coord[d] <= side || return false
    end
    return true
end
cmax(c::CartesianIndex) = maximum(abs.(Tuple(c)))

shade_dist(d::Int)::Float64 = d + 0.05

function shade_dist(caths::CartesianIndex{2})::Float64
    @inbounds dist = sqrt(caths[1]^2 + caths[2]^2)
    return dist == 0.0 ? 1.0 : (dist + 0.05)
end

function shade_dist(pos1::CartesianIndex{2}, pos2::CartesianIndex{2})::Float64
    caths = pos1 - pos2
    @inbounds dist = sqrt(caths[1]^2 + caths[2]^2)
    return dist == 0.0 ? 1.0 : (dist + 0.05)
end