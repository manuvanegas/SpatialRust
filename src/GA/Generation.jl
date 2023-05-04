# function startstops()
#     # starts = [2; 1; 2; 1; 1; fill(5, 3); fill(5,3); 4; 5; fill(5, 3); 1; 5]
#     # stops = [1; 1 .+ cumsum(starts[1:end-1])] 
#     return [2, 1, 2, 1, 1, 5, 5, 5, 5, 5, 5, 4, 5, 5, 5, 5, 1, 5], [1, 3, 4, 6, 7, 8, 13, 18, 23, 28, 33, 38, 42, 47, 52, 57, 62, 63]
# end

loci() = [1:2, 3:3, 4:5, 6:6, 7:7, 8:12, 13:17, 18:22, 23:27, 28:32, 33:37, 38:41, 42:46, 47:51, 52:56, 57:61, 62:62, 63:67]

bits_to_int(bits) = sum(bit * 2 ^ (pos - 1) for (pos,bit) in enumerate(bits))

function tourn_select(pop::BitMatrix, fitnesses::Vector{Float64}, popsize::Int, rng::Random.Xoshiro)
    # n = length(fitnesses)
    (length(fitnesses) == size(pop)[2] == popsize) && error("population and fitnesses dont match")
    selected = zeros(Int, popsize)
    # pair_select.(repr, Ref(fitnesses), n)
    @inbounds for i in 1:(popsize - 1) # set one slot aside for elitism
        c1, c2 = sample(rng, 1:popsize, 2, replace = false)
        selected[i] = fitnesses[c1] > fitnesses[c2] ? c1 : c2
    end
    @inbounds selected[popsize] = argmax(fitnesses)
    shuffle!(selected) # to allow xover to operate over contiguous pairs
    return pop[:, repr]
end

function xover!(pop::BitMatrix, p_c::Float64, popsize::Int, lastp::Int, rng::Random.Xoshiro)
    for i in 1:2:popsize
        if rand(rng) < p_c
            p1, p2 = sort!(sample(rng, 1:lastp, 2, replace = false))
            spliced = pop[p1:p2, i]
            pop[p1:p2, i] .= pop[p1:p2, i + 1]
            pop[p1:p2, i + 1] .= spliced
        end
    end
end

function mutate!(pop::BitMatrix, p_m::Float64, rng::Random.Xoshiro)
    @inbounds for p in eachindex(pop)
        if rand(rng) < p_m
            pop[p] .= !pop[p]
        end
    end
end

function transcribe(pop::BitMatrix, trfolder::String)
    # starts, stops = startstops()
    loci = loci()
    for indiv in eachcol(pop)
        transcripts = [bits_to_int(indiv[l]) for l in loci]
        transcripts[[1:3; 5]] .+= 1
        writedlm(joinpath(trfolder, string("i-", lpad(indiv, 3, "0"),".csv")), transcripts)
    end
end
