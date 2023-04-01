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



# Shade map explorations
# (Treating the space below as a scratchpad)

samplemap = zeros(Int, 20,20)
for (i, j) in Iterators.product(1:6:20, 1:6:20)
    samplemap[i,j] = 2
end

eudist(d) = d == (0,0) ? 1.0 : sqrt(d[1]^2 + d[2]^2) + 0.0
stepdist(d) = sum(d)
chebdist(d) = max(d)

poss = Matrix{NTuple{2, Int}}(undef, 4, 4)
shading = zeros(4, 4)
justd = zeros(4, 4)
justsh = zeros(4, 4)
for (i, d) in enumerate(Iterators.product(0:3, 0:3))
    # println(d)
    poss[i] = d
    shading[i...] = (1 / (stepdist(d) + 1.0)) * (1 / eudist(d))
    justd[i...] = (1 / (stepdist(d) + 1.0))
    justsh[i...] = (1 / eudist(d)^2)
end

scatter(1:length(shading[1,:]), shading[1,:])

fig, ax, hm = heatmap(shading);
Colorbar(fig[:, end+1], hm)
fig


eudist((0,0))

(1 / (stepdist((0,0)) + 1.0)) * (1 / eudist((0,0)))

heatmap(SpatialRust.create_farm_map(100, 2, 1, 6, :regular, 1, (1,0)))

tvdists = sqrt.([1,2,4,5,8,9,10,13,18])
lines(tvdists, (1 .+ 1 ./ tvdists) ./ 2)
lines(tvdists, (1 ./ [1,1,2,2,2,3,3,3,3]) .* (1 ./ tvdists))
lines(tvdists, 1 ./ tvdists.^2)
lines(tvdists, 1 .- (tvdists.^2 ./ 25))
barplot(1 .- (tvdists.^2 ./ 25))

barplot(tvdists)


block1 = Iterators.product(-1:1, -1:1)
block2 = Iterators.product(-2:2, -2:2)
block3 = Iterators.product(-3:3, -3:3)

radius3 = Iterators.filter(c -> c ∉ block2, block3)
radius2 = Iterators.filter(c -> c ∉ block1, block2)
radius1 = Iterators.filter(c -> c != (0,0), block1)


function usecoords(matr,n)
    m = copy(matr)
    cs = CartesianIndices((1:n, 1:n))
    for c in cs
        m[c] = 1 / mydist(Tuple(c))
    end
    m
end

function usetup(matr,n)
    m = copy(matr)
    cs = Iterators.product(1:n, 1:n)
    for c in cs
        m[c...] = 1 / mydist(c)
    end
    m
end

mydist(c) = sum(abs.(c))

thematr = rand(100,100);
usecoords(thematr, 100);
usetup(thematr, 100);

@benchmark usecoords($thematr, 100)
@benchmark usetup($thematr, 100)

# BenchmarkTools.Trial: 10000 samples with 9 evaluations.
#  Range (min … max):  2.750 μs …  4.104 ms  ┊ GC (min … max):  0.00% … 99.83%
#  Time  (median):     5.750 μs              ┊ GC (median):     0.00%
#  Time  (mean ± σ):   7.834 μs ± 78.516 μs  ┊ GC (mean ± σ):  20.03% ±  2.00%

#                         █▇                                    
#   ▂▂▂▂▁▂▂▂▂▂▁▂▂▂▂▂▂▂▂▁▂▄██▄▇█▄▅▆▄▃▃▂▂▂▂▃▄▄▄▄▄▄▄▃▃▃▃▃▃▃▃▂▂▂▂▂ ▃
#   2.75 μs        Histogram: frequency by time        9.29 μs <

#  Memory estimate: 78.17 KiB, allocs estimate: 2.

# BenchmarkTools.Trial: 10000 samples with 3 evaluations.
#  Range (min … max):   7.458 μs …  12.895 ms  ┊ GC (min … max):  0.00% … 99.87%
#  Time  (median):     10.736 μs               ┊ GC (median):     0.00%
#  Time  (mean ± σ):   12.518 μs ± 128.842 μs  ┊ GC (mean ± σ):  10.29% ±  1.00%

#   ▃                ▂▆█▇▅▄▅▅▄▅▅▃▂▂▂▃▅▅▅▄▄▃▃▃▂▂▂▂▂▂▁▁▁     ▁     ▂
#   █▃▁▆▇▃▄▃▅▃▃▅▅▃▅▄▄███████████████████████████████████████▇█▇▇ █
#   7.46 μs       Histogram: log(frequency) by time      15.8 μs <

#  Memory estimate: 78.17 KiB, allocs estimate: 2.

# Using cartesian indices is way faster than splatting a tuple

block1 = CartesianIndices((-1:1, -1:1))
block2 = CartesianIndices((-2:2, -2:2))
block3 = CartesianIndices((-3:3, -3:3))

radius3 = Iterators.filter(c -> c ∉ block2, block3)
radius2 = Iterators.filter(c -> c ∉ block1, block2)
radius1 = Iterators.filter(c -> c != CartesianIndex(0,0), block1)


neighs1 = (n for n in Iterators.filter(
    r -> checkbounds(Bool, samplemap, r), (CartesianIndex(2,1) + d for d in radius1)
) if samplemap[n] == 2)



tpos = CartesianIndex(4,2)

neighs1 = (n for n in Iterators.filter(
    r -> checkbounds(Bool, samplemap, tpos + r), radius1
) if samplemap[tpos + n] == 2)
if isempty(neighs1)
    neighs2 = (n for n in Iterators.filter(
        r -> checkbounds(Bool, samplemap, tpos + r), radius2
    ) if samplemap[tpos + n] == 2)
    if isempty(neighs2)
        neighs3 = (n for n in Iterators.filter(
            r -> checkbounds(Bool, samplemap, tpos + r), radius3
        ) if samplemap[tpos + n] == 2)
        if isempty(neighs3)
        else
            ns = 0
            sh = 0.0
            for n in neighs3
                sh += 1 / eudist(n)^2
                ns += 1
                ns == 2 && break
            end
            println(collect(neighs3))
            print(sh)
            println(collect(neighs3))
            print(sum(1 / eudist(n)^2 for n in neighs3))
        end
    else
        ns = 0
        sh = 0.0
        for n in neighs2
            sh += 1 / eudist(n)^2
            ns += 1
            ns == 2 && break
        end
        if ns < 2
        end
        println(collect(neighs2))
        print(sh)
        # print(sum(1 / eudist(n)^2 for n in neighs2))
    end
else
    print(maximum(1 / eudist(n) for n in neighs1))
end

sampleout = copy(samplemap)
for coord in CartesianIndices(samplemap)
    neighs1 = (n for n in Iterators.filter(
        r -> checkbounds(Bool, samplemap, tpos + r), radius1
    ) if samplemap[tpos + n] == 2)
    if isempty(neighs1)
        neighs2 = (n for n in Iterators.filter(
            r -> checkbounds(Bool, samplemap, tpos + r), radius2
        ) if samplemap[tpos + n] == 2)
        if isempty(neighs2)
            neighs3 = (n for n in Iterators.filter(
                r -> checkbounds(Bool, samplemap, tpos + r), radius3
            ) if samplemap[tpos + n] == 2)
            if isempty(neighs3)
            else
                sampleout[coord] = sum(1 / eudist(n) for n in neighs3)
            end
        else
            sampleout[coord] = sum(1 / eudist(n) for n in neighs2)
        end
    else
        sampleout[coord] = maximum(1 / eudist(n) for n in neighs1)
    end
end

f1, ax1, hm1 = heatmap(create_shade_map(SpatialRust.create_farm_map(), 3, 100));
Colorbar(f1[1, 2], hm1)
f1
f2, ax2, hm2 = heatmap(create_shade_map2(SpatialRust.create_farm_map(), 3, 100));
Colorbar(f2[1, 2], hm2)
f2
f3, ax3, hm3 = heatmap(create_myf_map(SpatialRust.create_farm_map(100,2,1,6), 3, 100));
Colorbar(f3[1, 2], hm3)
f3
f3, ax3, hm3 = heatmap(create_myf_map(samplemap, 3, 20));
Colorbar(f3[1, 2], hm3)
f3

f3, ax3, hm3 = heatmap(SpatialRust.create_shade_map(SpatialRust.create_farm_map(100,2,1,6), 3, 100));
Colorbar(f3[1, 2], hm3)
f3

function in_farm(coord::CartesianIndex, side::Int)::Bool
    @inbounds for d in 1:2
        1 <= coord[d] <= side || return false
    end
    return true

    # all(1 .<= coord .<= side) # (can't broadcast over a cartesian index)
end

eucdist(d::CartesianIndex{2})::Float64 = d[1]^2 + d[2]^2

function create_myf_map(farm_map::Matrix{Int}, shade_r::Int, side::Int)
    block1 = CartesianIndices((-1:1, -1:1))
    # block2 = CartesianIndices((-2:2, -2:2))
    block3 = CartesianIndices((-shade_r:shade_r, -shade_r:shade_r))

    radius23 = Iterators.filter(c -> c ∉ block1, block3)
    # radius2 = Iterators.filter(c -> c ∉ block1, block2)
    radius1 = Iterators.filter(c -> c != CartesianIndex(0,0), block1)
    fmap = copy(farm_map)
    shades = findall(==(2), fmap)
    shade_map = zeros(size(farm_map))
    # for sh in shades
    maxdist = (2 * shade_r)^2
    for coord in CartesianIndices(farm_map)
        if farm_map[coord] == 2
            shade_map[coord] = 1.0
        else
            neighs  = (n for n in Iterators.filter(
                r -> in_farm(coord + r, side), block3
                ) if farm_map[coord + n] == 2)
            if !isempty(neighs)
                shade_map[coord] = 1.0 - minimum(eucdist(n) for n in neighs) / maxdist
                # 0.38 + 0.6 / minimum(eudist(n) for n in neighs)
            end
            # # neighs = Iterators.filter(x -> in_farm(x, side), sh + n for n in crown)
            # neighs1  = (n for n in Iterators.filter(
            #     r -> in_farm(coord + r, side), radius1
            #     ) if farm_map[coord + n] == 2)

            # if isempty(neighs1)
            #     neighs23 = (n for n in Iterators.filter(
            #         r -> in_farm(coord + r, side), radius23
            #         ) if farm_map[coord + n] == 2)
            #     if !isempty(neighs23)
            #         # print(neighs23)
            #         # nearbyshades = collect(1.0 / (eudist(n) * maximum(abs.(Tuple(n)))) for n in neighs23)   
            #         # nearbyshades = collect(0.7 / eudist(n) for n in neighs23)   
            #         nearbyshades = collect(2.0 / eudist(n)^2 for n in neighs23)   
            #         if length(nearbyshades) > 2
            #             shade_map[coord] = sum(sort!(nearbyshades, rev = true)[1:2])
            #         else
            #             shade_map[coord] = sum(nearbyshades)
            #         end
            #         # ns = 0
            #         # sh = 0.0
            #         # for n in neighs23
            #         #     sh += 1 / eudist(n)^2
            #         #     ns += 1
            #         #     ns == 2 && break
            #         # end
            #     end
            # else
            #     shade_map[coord] = maximum(0.95 / eudist(n) for n in neighs1)
            #     # print(collect(neighs1))
            # end
            # # for n in neighs
            # #     diff = n - sh
            # #     if n in shades
            # #         @inbounds shade_map[n] = 1.0
            # #         @inbounds influence_map[n] = 1.0
            # #     else
            # #         @inbounds shade_map[n] += 1.0 / (shade_dist(diff) ^ 2)
            # #         @inbounds influence_map[n] += 1.0 / cmax(diff) 
            # #     end
            # # end
        end
    end
    return shade_map
end

create_myf_map(samplemap, 3, 20)


fmap0_nb = SpatialRust.create_farm_map(100, 2, 1, 100, :regular, 2, (0,0))
fmap6_nb = SpatialRust.create_farm_map(100, 2, 1, 6, :regular, 2, (0,0))
fmap9_nb = SpatialRust.create_farm_map(100, 2, 1, 9, :regular, 2, (0,0))
fmap12_nb = SpatialRust.create_farm_map(100, 2, 1, 12, :regular, 2, (0,0))

fmap0_b = SpatialRust.create_farm_map(100, 2, 1, 100, :regular, 2, (1,0))
fmap6_b = SpatialRust.create_farm_map(100, 2, 1, 6, :regular, 2, (1,0))
fmap9_b = SpatialRust.create_farm_map(100, 2, 1, 9, :regular, 2, (1,0))
fmap12_b = SpatialRust.create_farm_map(100, 2, 1, 12, :regular, 2, (1,0));

s6 = create_myf_map(fmap6_nb, 3, 100);
s9 = create_myf_map(fmap9_nb, 3, 100);
s12 = create_myf_map(fmap12_nb, 3, 100);
s100 = create_myf_map(fmap0_nb, 3, 100);

sb6 = create_myf_map(fmap6_b, 3, 100);
sb9 = create_myf_map(fmap9_b, 3, 100);
sb12 = create_myf_map(fmap12_b, 3, 100);
sb100 = create_myf_map(fmap0_b, 3, 100);


f3, ax3, hm3 = heatmap(create_myf_map(fmap12_nb, 3, 100));
Colorbar(f3[1, 2], hm3)
f3

f3, ax3, hm3 = heatmap(SpatialRust.create_shade_map(fmap6_b, 3, 100));
Colorbar(f3[1, 2], hm3)
f3

@benchmark create_shade_map($fmap9_b, 3, 100)
@benchmark SpatialRust.create_shade_map($fmap12_b, 3, 100, :regshaded)
mean(SpatialRust.create_shade_map(fmap12_b, 3, 100, :regshaded))

# , colormap = Reverse(:viridis)

f4ds, ax4ds1, hm4ds1 = heatmap(create_myf_map(fmap0_nb, 3, 100),  colorrange = (0,0.999), highclip = :red);
ax4ds2, hm4ds2 = heatmap(f4ds[1,2], create_myf_map(fmap12_nb, 3, 100),  colorrange = (0,0.999), highclip = :black, colormap = :speed);
ax4ds3, hm4ds3 = heatmap(f4ds[2,1], create_myf_map(fmap9_nb, 3, 100),  colorrange = (0,0.999), highclip = :red);
ax4ds4, hm4ds4 = heatmap(f4ds[2,2], create_myf_map(fmap6_nb, 3, 100),  colorrange = (0,0.999), highclip = :red);
Colorbar(f4ds[:, 3], hm4ds1)
f4ds

heatmap(create_myf_map(fmap12_nb, 3, 100),  colorrange = (0,0.999), highclip = :black, colormap = Reverse(:bamako))
heatmap(create_myf_map(fmap12_nb, 3, 100),  colorrange = (0,0.999), highclip = :black, colormap = :speed)
heatmap(create_myf_map(fmap12_nb, 3, 100),  colorrange = (0,0.999), highclip = :black, colormap = Reverse(:imola))
heatmap(create_myf_map(fmap12_nb, 3, 100),  colorrange = (0,0.999), highclip = :black, colormap = Reverse(:lapaz))
fh, axh, hm = heatmap(create_myf_map(fmap12_b, 3, 100) .+ fmap12_b,  colorrange = (0.3999,1.999), highclip = :black, lowclip = :brown, colormap = Reverse((:nuuk, 0.8)))
heatmap!(fh[1,1], fmap12_nb, colormap = Reverse((:speed, 0.6)))
fh
heatmap(fmap12_nb, colormap = Reverse((:BrBG_4, 0.5)))
heatmap(create_myf_map(fmap12_nb, 3, 100),  colorrange = (0,0.999), highclip = :black, colormap = :BrBG_4)





fh, axh, hm = heatmap(create_myf_map(fmap12_b, 3, 100) .+ fmap12_b,  colorrange = (0.3999,1.999), highclip = :black, lowclip = :brown, colormap = Reverse((:nuuk, 0.8)))


