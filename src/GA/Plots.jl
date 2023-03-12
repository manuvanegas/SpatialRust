function plot_fitn_history(fhist::Matrix{Float64})
    max = maximum(fhist, dims = 1)
    µ = mean(fhist, dims = 1)
    σ = std(fhist, dims = 1)
    max_mean_fitness(max, µ, σ)
end

function plot_fitn_history(fhist::DataFrame)
    summhist = combine(
        fhist, All() .=> [maximum, mean, std] => [:max, :µ, :std]
    )
    max = summhist[:, :max]
    µ = summhist[:, :µ]
    σ = summhist[:, :std]
    max_mean_fitness(max, µ, σ)
end

function max_mean_fitness(max::Vector{Float64}, µ::Vector{Float64}, σ::Vector{Float64})
    
end