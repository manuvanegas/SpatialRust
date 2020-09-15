using DrWatson
@quickactivate "SpatialRust"
using Interact, Plots

@manipulate for local_temp = 14:0.5:30
    days = collect(1:50)
    size = zeros(length(days))
    size[1] = 0.01

    for day in 2:length(days)
        size[day] = size[day - 1] + 0.5 * (-0.0178 * ((local_temp - 22.5) ^ 2) + 1) * size[day - 1] * (1 - size[day - 1])
    end

    plot(days, size)
end


function plot_indicators(steps, reps)
    # chromosome = bitrand(31)
    chromosome=BitArray([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1])
    # innn[1:10].=0
    chromosome[10]=0 # 50%
    shade_percent, microlots, fungicide, inspection_f, pruning, shade_mgmnt = decode_chromosome(chromosome)
    dims = 100
    bitmap = create_bitmap(dims, shade_percent, microlots, false)
    mean_temp = 22.0

    input = [dims, bitmap, mean_temp, shade_mgmnt, fungicide, inspection_f, pruning, steps, reps]
    data = setup_and_step_reps(input)
    return data

    # ...
end


function plot_hist_fitness(temp)
    # using Statistics

    f_df = CSV.read("../FromS/800_$temp/results/out_fitness.csv")
    p_df = CSV.read("../FromS/800_$temp/results/out_pop.csv")

    historic_f = convert(Array, f_df)
    population = convert(Array, p_df)

    # fitness = zeros(2, 80, 80)
    # fitness[1, :, 80] = mapslices(maximum, historic_f, dims=1) # find max fitness for each gen
    # fitness[2, :, 80] = mapslices(mean, historic_f, dims=1)

    best_inds = Array{Any}(undef, (3, 6))

    ind_i = partialsortperm(historic_f[:, 80], 1:3) # find indices of 3 ind with max fitness at end of run
    println(ind_i)
    for b in 1:length(ind_i)
        indx=ind_i[b]
        println(indx)
        best_inds[b, :] .= decode_chromosome(BitArray(population[ind_i[b], :]))
    end

    # run model with best par set

    μ = mean(historic_f, dims = 1)
    σ = std(historic_f, dims = 1)
    max = maximum(historic_f, dims = 1)

    plot(µ, ribbon = σ, fillalpha=0.3,
        xlabel="Generations",
        ylabel="Fitness",
        label="Mean Fitness",
        # ylims=(-0.5,0.0),
        legend=:bottomright)
    plot!(max,
        label="Maximum Fitness")

    return best_inds
end
