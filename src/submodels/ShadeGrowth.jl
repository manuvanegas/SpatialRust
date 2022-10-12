using CairoMakie

days = 100

function growsh(days::Int, init::Float64, rate::Float64)
    shades = vcat(init, Vector{Float64}(undef, (days - 1)))
    for d in 2:days
        shades[d] = rate * (1.0 - shades[(d - 1)] / 0.95) * shades[(d - 1)] + shades[(d - 1)]
    end
    return shades
end

tss = growsh(days, 0.1, 0.06)
tss[60] / 0.95
lines(tss)
