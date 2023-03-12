function tourn_select!(pop::BitMatrix, fitnesses::Vector{Float64}, n::Int, rng::Random.Xoshiro)
    # n = length(fitnesses)
    repr = zeros(Int, (n - 1))
    # pair_select.(repr, Ref(fitnesses), n)
    for i in 1:(n - 1) # set one slot aside for elitism
        contestants = sample(rng, 1:n, 2, replace = false)
        winner = argmax(fitnesses[contestants])
        repr[i] = contestants[winner]
    end
    push!(repr, argmax(fitnesses))
    shuffle!(repr) # to allow xover to operate over contiguous pairs
    pop .= pop[:, repr]
end

function xover!(pop::BitMatrix, p_c::Float64, n::Int, rng::Random.Xoshiro)
    wh = collect(1:2:n)[rand(rng, div(n, 2)) .< p_c]
    for i in wh
        p1, p2 = sort!(sample(rng, 1:n, 2, replace = false))
        spliced = pop[p1:p2, i]
        pop[p1:p2, i] .= pop[p1:p2, i + 1]
        pop[p1:p2, i + 1] .= spliced
    end
    # if rand(rng) < p_c
    #     p1, p2 = sort!(sample(rng, 1:n, 2, replace = false))
    #     spliced = chr[p1:p2, 1]
    #     chr[p1:p2, 1] = chr[p1:p2, 2]
    #     chr[p1:p2, 2] = spliced
    # end
end

function mutate!(pop::BitMatrix, p_m::Float64, rng::Random.Xoshiro)
    wh = rand(rng, length(pop)) .< p_m
    pop[wh] .= .!pop[wh]
end

function progeny!(pop::BitMatrix, fitnesses::Vector{Float64}, n::Int, p_c::Float64, p_m::Float64, rng::Random.Xoshiro)
    # progeny = similar(pop)
    # n = length(fitnesses)
    tourn_select!(pop, fitnesses, n, rng)
    xover!(pop, p_c, n, rng)
    mutate!(pop, p_m, rng)
end

# tpop = bitrand(3,2)

# twh = rand(length(tpop)) .< 0.4

# tpop[twh] .= .!tpop[twh]

# tA = [1 2; 3 4]

# function timessmt(x, a)
#     x = x * a
# end

# timessmt.(tA, 2)