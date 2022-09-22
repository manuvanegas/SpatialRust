using Pkg
Pkg.activate(".")
using Agents

## Agent types and constructor fcts
mutable struct Coffee <: AbstractAgent
    id::Int
    pos::NTuple{2, Int}
    area::Float64 # healthy foliar area (= 25 - rust.area * rust.n_lesions/25)
    sunlight::Float64 # let through by shade trees
    shade_neighbors::Vector{Int} # remember which neighbors are shade trees
    progression::Float64
    production::Float64
    exh_countdown::Int
    age::Int
    hg_id::Int # "host-guest id": coffee is host, then this stores corresponding rust's id
    sample_cycle::Vector{Int} # vector with cycles where coffee should be sampled
    #fung_countdown::Int
end

function dist(pos1::CartesianIndex, pos2::CartesianIndex)
    caths = pos1 - pos2
    dist = sqrt(caths[1]^2 + caths[2]^2)
    return dist + 0.05
end

function dist(pos1::Tuple, pos2::Tuple)
    caths = pos1 .- pos2
    dist = sqrt(caths[1]^2 + caths[2]^2)
    return dist + 0.05
end
side = 100
farm_map = create_farm_map(Parameters(map_side = side, shade_d = 6, row_d = 2, barriers = (0,0), barrier_rows = 1))
# heatmap(farm_map)

myfarmmap = zeros(side,side); myfarmmap[2,2] = 2; myfarmmap[4,4] = 2

tmodel = ABM(Coffee, GridSpace((side, side), periodic = false, metric = :chebyshev); properties = farm_map)

function shade_map!(model, shade_r)
    shades = Tuple.(findall(x -> x == 2, model.properties))
    shade_map = zeros(size(model.properties))
    # counts = zeros(shade_r)
    for sh in shades
        # shade_map[sh...] += (shade_r * 2 + 1) ^ 2 - ((shade_r - 1) * 2 + 1) ^ 2
        shade_map[sh...] += 1.0
        # counts[sh...] += 1
        neighs = nearby_positions(sh, model, shade_r)
        for n in neighs
            if n ∉ shades
                # shade_map[n...] += 1 / (maximum(abs.(sh .- n)) + 0.05)
                # shade_map[n...] += 1
                shade_map[n...] += (1 / (dist(sh, n)))
                # counts[n...] += 1
            end
        end
    end
    shade_map = min.(1.0, shade_map)
    # shade_map .= shade_map ./ counts
    # shade_map /= (shade_r * 2 + 1) ^ 2 - ((shade_r - 1) * 2 + 1) ^ 2
    # model.shade_map .*= 0
    # model.shade_map .+= shade_map
    return shade_map
end

shade_map1 = shade_map!(tmodel, 1)
shade_map2 = shade_map!(tmodel, 2)
shade_map3 = shade_map!(tmodel, 3)
shade_map4 = shade_map!(tmodel, 4)

using Plots
heatmap(shade_map3)
heatmap(farm_map)
