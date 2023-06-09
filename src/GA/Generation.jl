# function startstops()
#     # starts = [2; 1; 2; 1; 1; fill(5, 3); fill(5,3); 4; 5; fill(5, 3); 1; 5]
#     # stops = [1; 1 .+ cumsum(starts[1:end-1])] 
#     return [2, 1, 2, 1, 1, 5, 5, 5, 5, 5, 5, 4, 5, 5, 5, 5, 1, 5], [1, 3, 4, 6, 7, 8, 13, 18, 23, 28, 33, 38, 42, 47, 52, 57, 62, 63]
# end

# loci() = [1:2, 3:3, 4:5, 6:6, 7:7, 8:12, 13:17, 18:22, 23:27, 28:32, 33:37, 38:41, 42:46, 47:51, 52:56, 57:61, 62:62, 63:67]

function tourn_select(pop::BitMatrix, fitnesses::Vector{Float64}, popsize::Int, rng::Random.Xoshiro)
    # n = length(fitnesses)
    # (length(fitnesses) == size(pop)[2] == popsize) || error("population and fitnesses dont match. fitn = $(length(fitnesses)), size(pop) = $(size(pop)), popsize = $popsize")
    selected = zeros(Int, popsize)
    # pair_select.(repr, Ref(fitnesses), n)
    ex = round(Int, popsize * 0.05, RoundUp)
    @inbounds for i in 1:(popsize - ex - 1) # set 1 slot aside for elitism and 5 for random indivs
        c1, c2 = sample(rng, 1:popsize, 2, replace = false)
        selected[i] = fitnesses[c1] > fitnesses[c2] ? c1 : c2
    end
    @inbounds selected[popsize - ex] = argmax(fitnesses)
    remaining = setdiff(1:popsize, selected)
    @inbounds selected[popsize - ex + 1:popsize] = sample(rng, remaining, ex, replace = false)
    shuffle!(selected) # to allow xover to operate over contiguous pairs
    return pop[:, selected]
end

function xover!(pop::BitMatrix, p_c::Float64, popsize::Int, rng::Random.Xoshiro)
    lastp = size(pop, 1)
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
            pop[p] = !pop[p]
        end
    end
end

bits_to_int(bits) = 1 + sum(bit * 2 ^ (pos - 1) for (pos,bit) in enumerate(bits))

function transcribe(pop::BitMatrix, trfolder::String)
    # loci = [1:2, 3:3, 4:5, 6:6, 7:7, 8:12, 13:17, 18:22, 23:27, 28:32, 33:37, 38:41, 42:46, 47:51, 52:56, 57:61, 62:62, 63:67]
    # loci = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:19, 20:25, 26:31, 32:37, 38:43, 44:48, 49:54, 55:60, 61:66, 67:72, 73:73, 74:79]
    # loci = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:14, 15:20, 21:21, 22:27, 28:28, 29:34, 35:40, 41:46, 47:51, 52:57, 58:63, 64:64, 65:70, 71:71, 72:77, 78:78, 79:80, 81:86]
    loci = [1:7, 8:14, 15:21, 22:27, 28:33, 34:39, 40:41, 42:45, 46:46, 47:53, 54:54, 55:56, 57:57, 58:64, 65:71, 72:78, 79:80, 81:87]
    for (i,indiv) in enumerate(eachcol(pop))
        transcripts = [bits_to_int(indiv[l]) for l in loci]
        # transcripts[[1:3; 5]] .+= 1
        writedlm(joinpath(trfolder, string("i-", lpad(i, 3, "0"),".csv")), transcripts)
    end
end

function newgen(expfolder::String, pastgen0s::String, gen0s::String, popsize::Int, rng::Xoshiro)
    # read past gen's pop and fitnesses
    pastpop = BitMatrix(readdlm(joinpath(expfolder,"pops", string("g-", pastgen0s,".csv")), ',', Bool))
    fitnfiles = readdir(joinpath(expfolder,"fitns", string("g-", pastgen0s,"/")), join = true)
    fitns = zeros(popsize)
    for f in fitnfiles
        ind = parse(Int, f[end-6:end-4])
        fitns[ind] = only(readdlm(f, ','))
    end

    # copy fitnesses to single file and create dir for next generation
    writedlm(joinpath(expfolder,"histftns", string("g-", pastgen0s,".csv")), fitns, ',')
    mkpath(joinpath(expfolder, "fitns", string("g-", gen0s)))

    # progeny
    newpop = tourn_select(pastpop, fitns, popsize, rng)
    xover!(newpop, pcross, popsize, rng)
    mutate!(newpop, pmut, rng)

    # write new gen's pop
    writedlm(joinpath(expfolder,"pops", string("g-", gen0s,".csv")), newpop, ',')

    # transcribe from pop (produce Ints) and write files
    trfolder = mkpath(joinpath(expfolder, "transcs", string("g-", gen0s)))
    transcribe(newpop, trfolder)
end

function finalize(expfolder::String, pastgen0s::String, popsize::Int)
    # read past gen's fitnesses to copy them in a single file
    fitnfiles = readdir(joinpath(expfolder,"fitns", string("g-", pastgen0s,"/")), join = true)
    fitns = zeros(popsize)
    for f in fitnfiles
        ind = parse(Int, f[end-6:end-4])
        fitns[ind] = only(readdlm(f, ','))
    end
    writedlm(joinpath(expfolder,"histftns", string("g-", pastgen0s,".csv")), fitns, ',')
    
    p = mkpath(joinpath("results/GA4", rsplit(expfolder, "/", limit = 2)[2]))
    hfitnsfiles = readdir(joinpath(expfolder, "histftns"), join = true)
    hfitns = fill(Float64[], maxgens)
    for f in hfitnsfiles
        g = parse(Int, f[end-6:end-4])
        if g <= maxgens
            hfitns[g] = vec(readdlm(f, ',', Float64))
        end
    end
    histfitness = reduce(hcat, hfitns)
    writedlm(joinpath(p,"fitnesshistory-$(pastgen).csv"), hfitns, ',')
end

