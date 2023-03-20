include("Progenies.jl")
include("Chromosomes.jl")


function GA(lnths::Vector{Int}, parnames::Vector{Symbol}, n::Int, gs::Int, reps::Int, p_c::Float64, p_m::Float64, steps::Int, cofprice::Float64, f::String)
    if occursin("profit", f)
        return profit_GA(lnths, parnames, n, gs, reps, p_c, p_m, steps, cofprice)
    elseif occursin("rust", f)
        return spores_GA(lnths, parnames, n, gs, reps, p_c, p_m, steps, cofprice)
    else
        error("obj func?")
    end
end

function profit_GA(lnths::Vector{Int}, parnames::Vector{Symbol}, n::Int, gs::Int, reps::Int, p_c::Float64, p_m::Float64, steps::Int, cofprice::Float64)
    # isodd(n) && error("n has to be even")
    # steps < 365 && error("can't do less than one year")
    rng = Random.Xoshiro()
    pop = bitrand(sum(lnths), n)
    gnfun = genes(lnths)

    fitn_history = zeros(n, gs)
    best_inds = DataFrame()

    wp = CachingPool(workers())
    g = 1
    while g < gs
        phenos = gen_phenotypes(pop, parnames, steps, cofprice, gnfun)
        fitn_history[:, g] .= fitnesses = map(r -> sptlrust_profit_fitness(r, reps, n), Tables.namedtupleiterator(phenos))
        fitn_history[:, g] .= fitnesses = pmap(r -> sptlrust_profit_fitness(r, reps, n), wp, Tables.namedtupleiterator(phenos), retry_delays = [0.1, 0.1, 0.1])
        push!(best_inds, phenos[argmax(fitnesses), :])
        progeny!(pop, fitnesses, n, p_c, p_m, rng)
        g += 1
    end
    phenos = gen_phenotypes(pop, parnames, steps, cofprice, gnfun)
    # fitn_history[:, g] .= fitnesses = map(r -> sptlrust_profit_fitness(r, reps, n), Tables.namedtupleiterator(phenos))
    fitn_history[:, g] .= fitnesses = pmap(r -> sptlrust_profit_fitness(r, reps, n, wp, Tables.namedtupleiterator(phenos), retry_delays = [0.1, 0.1, 0.1])
    push!(best_inds, phenos[argmax(fitnesses), :])

    return phenos, best_inds, fitn_history
end

function sptlrust_profit_fitness(pars::NamedTuple, reps::Int, n::Int)
    models = [init_spatialrust(
        ; pars...
        ) for _ in 1:reps]
    # models = [pars[[1:3;5;8;9]] for _ in 1:reps]

    return mapreduce(farm_profit, +, models) ./ n
end

function farm_profit(model::SpatialRustABM)
    shadetracker = zeros(365)

    s = 1
    while s < 366
        step!(model, dummystep, step_model!, 1)
        shadetracker[s] = model.current.ind_shade
        s += 1
    end

    avsunlight = 1.0 -  mean(shadetracker) * mean(model.shade_map)
    model.current.costs += model.mngpars.other_costs * avsunlight - 0.07

    while s <= steps && model.current.inbusiness
        step!(model, dummystep, step_model!, 1)
        if s % 364 == 0
            model.current.costs += model.mngpars.other_costs * avsunlight - 0.07
        end
        s += 1
    end

    if model.current.inbusiness
        score = -maxspores
    else
        y_lost = 1.0 - s * inv(steps)
        score = -(1.0 + y_lost) * maxspores
    end

    return (model.current.prod) * price - model.current.costs
end

function spores_GA(lnths::Vector{Int}, parnames::Vector{Symbol}, n::Int, gs::Int, reps::Int, p_c::Float64, p_m::Float64, steps::Int, cofprice::Float64)
    # isodd(n) && error("n has to be even")
    # steps < 365 && error("can't do less than one year")
    rng = Random.Xoshiro()
    pop = bitrand(sum(lnths), n)
    gnfun = genes(lnths)

    fitn_history = zeros(n, gs)
    best_inds = DataFrame()

    # wp = CachingPool(workers())
    g = 1
    while g < gs
        phenos = gen_phenotypes(pop, parnames, steps, cofprice, gnfun)
        fitn_history[:, g] .= fitnesses = map(r -> sptlrust_spores_fitness(r, reps, n), Tables.namedtupleiterator(phenos))
        # fitn_history[:, g] .= fitnesses = pmap(r -> sptlrust_spores_fitness(r, reps, n), wp, Tables.namedtupleiterator(phenos), retry_delays = [0.1, 0.1, 0.1])
        push!(best_inds, phenos[argmax(fitnesses), :])
        progeny!(pop, fitnesses, n, p_c, p_m, rng)
        g += 1
    end
    phenos = gen_phenotypes(pop, parnames, steps, cofprice, gnfun)
    fitn_history[:, g] .= fitnesses = map(r -> sptlrust_spores_fitness(r, reps, n), Tables.namedtupleiterator(phenos))
    # fitn_history[:, g] .= fitnesses = pmap(r -> sptlrust_spores_fitness(r, reps, n, wp, Tables.namedtupleiterator(phenos), retry_delays = [0.1, 0.1, 0.1])
    push!(best_inds, phenos[argmax(fitnesses), :])

    return phenos, best_inds, fitn_history
end

function sptlrust_spores_fitness(pars::NamedTuple, reps::Int, n::Int)
    models = [init_spatialrust(
        ; pars...
        ) for _ in 1:reps]
    # models = [pars[[1:3;5;8;9]] for _ in 1:reps]

    return mapreduce(yearly_spores, +, models) ./ n
end

function yearly_spores(model::SpatialRustABM)
    maxspores = 0.0

    s = 1
    myaupc = 0.0
    while s <= steps && model.current.inbusiness
        step!(model, dummystep, step_model!, 1)
        myaupc += sum(sum.(getproperty.(model.agents, :spores)))
        if s % model.mngpars.harvest_day == 0
            if myaupc > maxspores
                maxspores = myaupc
            end
            myaupc = 0.0
        end
        s += 1
    end

    if model.current.inbusiness
        score = -maxspores
    else
        y_lost = 1.0 - s * inv(steps)
        score = -(1.0 + y_lost) * maxspores
    end

    return score
end

