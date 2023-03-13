# function create_chromosome_pop(chroml::Int, popsize::Int)
#     bitrand(chroml, popsize) #68
# end

function genes(lnths::Vector{Int})
    inits = [1; 1 .+ cumsum(lnths[1:end-1])]
    function f(chr)
        return collect(chr[i:(i + l - 1)] for (i, l) in zip(inits, lnths))
    end
    return f
end

# lnths = [2, 1, 2, 1, 1, 5, 5, 5, 5, 5, 5, 4, 5, 5, 5, 5, 1, 5]
# tinits = cumsum(lnths)
# gnfun = genes(lnths)
# tparnames = collect(Symbol(n) for n in Char.(1:12))
# finalpop, histbest, histfit = GA(lnths, tparnames, 10, 20, 3, 0.5, 0.1, sum);
# tphenos =  gen_phenotypes(bitrand(68,10), tparnames, gnfun)

function gen_phenotypes(popchrs::BitMatrix, parnames::Vector{Symbol}, genes::Function) 
    # mapreduce(extrema, vcat,eachcol([1 0;2 0]))
    # pop_genes = map(genes, eachcol(popchrs))
    # pop_pars = map(eachcol(popchrs)) do chr
    #     decode_chromosome(chr, genes, add1)
    # end
    popgenes = mapreduce(vcat, eachcol(popchrs)) do chr
        permutedims(bits_to_ints(chr, genes))
    end
    popdf = DataFrame(popgenes, :auto)
    popdf[!, [1:3; 5]] .+= 1
    popdf[!, 4] = ifelse.(Bool.(popdf[!, 4]), [(1,1)], [(0,0)])
    select!(popdf, 1:5,
        6:8 => ByRow(DoY) => :a,
        9:11 => ByRow(propto08) => :b,
        12 => ByRow(perioddays) => :c,
        13 => ByRow(proportion) => :d,
        14:16 => ByRow(DoY) => :e,
        17 => ByRow(Bool) => :f,
        18 => ByRow(proportion) => :g,
    )
    rename!(popdf, parnames)
    return popdf
end

#=
0.1to1 = 32. Unit: 1/32 (n/32) - min is 1/32
DoY = 32. Unit: round(365/32) (n*365/32) - min is 0/31 (there'll be no 32 (no day 365) but it's fine)
dayperiod = 16. Unit: 4 (n*4) - min is 1/16

Coffees:                                | bits
- row_d -- 4                            | 2
- plant_d -- 2                          | 1
Shades:
- shade_d -- 4                          | 2
- barriers -- 2                         | 1
- barrier_rows -- 2                     | 1
Shade Management:
- prune_sch -- 3X DoY                   | 3x5
- target_shade -- 3X 0.1to1             | 3x5
Inspection:
- inspect_period -- dayperiod           | 4
- inspect_effort -- 0.1to1              | 5
Fungicide:
- fungicide_sch -- 3X DoY               | 3x5
- incidence_as_thr -- 2                 | 1
- incidence_thr -- 0.1to1               | 5

lnths = [2, 1, 2, 1, 1, 5, 5, 5, 5, 5, 5, 4, 5, 5, 5, 5, 1, 5]
=#

function bits_to_ints(chr, genes)
    raws = map(genes(chr)) do t
        sum(t .* 2 .^ (eachindex(t) .- 1))
    end
    return raws
end

DoY(x::Vararg{Int}) = collect(@. round(Int, 365 * x * inv(32)))
proportion(x::Vararg{Int}) = collect(@. (x + 1) * inv(32))
propto08(x::Vararg{Int}) = collect(@. (x + 1) * 0.8 * inv(32))
perioddays(x::Int) = (x + 1) * 4




# parse(Int, bitstring(4), base = 2)
# parse(Int, bitstring(2.1), base = 2)

# bitstring(33)
# ∘
# DataFrame([1 2; 3 4], (:a, :b))

# DataFrame(mapreduce(permutedims ∘ collect ∘ extrema, vcat,eachcol([1 2; 3 4; 5 6])), [:min, :max])
# mapreduce(permutedims ∘ collect ∘ extrema, vcat, eachcol([1 2; 3 4; 5 6]))
# [1 2; 3 4; 5 6]

# mapreduce(hcat,1:4) do i
#     i * 2
# end