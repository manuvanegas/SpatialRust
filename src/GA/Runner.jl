include("Progenies.jl")
include("Chromosomes.jl")


function GA(lnths::Vector{Int}, parnames::Vector{Symbol}, n::Int, gs::Int, reps::Int, p_c::Float64, p_m::Float64, f::Function)
    # wp = CachingPool(workers())
    isodd(n) && error("n has to be even")
    rng = Random.Xoshiro()
    pop = bitrand(sum(lnths), n)
    gnfun = genes(lnths)

    fitn_history = zeros(n, gs)
    best_inds = DataFrame()

    g = 1
    while g < gs
        phenos = gen_phenotypes(pop, parnames, gnfun)
        fitn_history[:, g] .= fitnesses = map(r -> sptlrust_fitness(r, f, reps, n), Tables.namedtupleiterator(phenos))
        # fitn_history[:, g] .= fitnesses = pmap(r -> sptlrust_fitness(r, f, reps, n), wp, Tables.namedtupleiterator(phenos), retry_delays = [0.1, 0.1, 0.1])
        push!(best_inds, phenos[argmax(fitnesses), :])
        progeny!(pop, fitnesses, n, p_c, p_m, rng)
        g += 1
    end
    phenos = gen_phenotypes(pop, parnames, gnfun)
    fitn_history[:, g] .= fitnesses = map(r -> sptlrust_fitness(r, f, reps, n), Tables.namedtupleiterator(phenos))
    # fitn_history[:, g] .= fitnesses = pmap(r -> sptlrust_fitness(r, f, reps, n, wp, Tables.namedtupleiterator(phenos), retry_delays = [0.1, 0.1, 0.1])
    push!(best_inds, phenos[argmax(fitnesses), :])

    return phenos, best_inds, fitn_history
end

function sptlrust_fitness(pars::NamedTuple, f::Function, reps::Int, n::Int)
    models = [init_spatialrust(; pars) for _ in 1:reps]
    # models = [pars[[1:3;5;8;9]] for _ in 1:reps]

    return mapreduce(f, +, models) ./ n
end

function farm_profit(steps::Int, price::Float64)
    function sim(model::SpatialRustABM)
        s = 0
        while Agents.until(s, steps, model)
            step!(model, dummystep, step_model!, 1)
            # sumareas = filter(>(0.0), sum.(getproperty.(model.agents, :areas)))
            if !isempty(sumareas)
                if (currentarea = mean(sumareas)) > max_area
                    max_area = currentarea
                end
            end
            s += 1
        end

        return (model.current.prod) * price - model.current.costs
    end
    return sim
end

function yearly_spores(steps::Int)
    function sim(model::SpatialRustABM)
        maxspores = 0.0

        s = 0
        myaupc = 0.0
        while Agents.until(s, steps, model)
            step!(model, dummystep, step_model!, 1)
            myaupc += sum(sum.(getproperty.(model.agents, :areas)))
            if s % model.mngpars.harvest_day == 0
                if myaupc > maxspores
                    maxspores = myaupc
                end
                myaupc = 0.0
            end
            s += 1
        end

        return maxspores
    end
    return sim
end

