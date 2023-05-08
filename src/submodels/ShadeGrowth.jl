using CairoMakie

days = 120

function growsh(days::Int, init::Float64, rate::Float64)
    shades = vcat(init, Vector{Float64}(undef, (days - 1)))
    for d in 2:days
        shades[d] = rate * (1.0 - shades[(d - 1)] / 0.8) * shades[(d - 1)] + shades[(d - 1)]
    end
    return shades
end

tss = growsh(days, 0.1, 0.01)
tss[60] / 0.95
lines(1 .- tss)

function growprune(days, init, rate, sch, level)
    shades = vcat(init, Vector{Float64}(undef, (days - 1)))
    if length(sch) == 2
        for d in 2:days
            if d == sch[1]
                shades[d] = level[1]
            elseif d == sch[2]
                shades[d] = level[2]
            else
                shades[d] = rate * (1.0 - shades[(d - 1)] / 0.8) * shades[(d - 1)] + shades[(d - 1)]
            end
        end
    elseif length(sch) == 3
        for d in 2:days
            if d == sch[1]
                shades[d] = level[1]
            elseif d == sch[2]
                shades[d] = level[2]
            elseif d == sch[3]
                shades[d] = level[3]
            else
                shades[d] = rate * (1.0 - shades[(d - 1)] / 0.8) * shades[(d - 1)] + shades[(d - 1)]
            end
        end
    end
    return shades
end

tshp = growprune(365, 0.1, 0.02, [1,123,246], [0.1, 0.1, 0.1]) # [1,123,246] is [74,196,319] shifted to 74 is 1
tshp = growprune(365, 0.5, 0.02, [1,123,246], [0.5, 0.5, 0.5])
tshp = growprune(365, 0.15, 0.008, [1,182], [0.15, 0.2, 0.5])
lines(tshp)
