import Pkg
Pkg.activate(".")
using DelimitedFiles, SpatialRust
using Statistics: mean

n = 200
y = 4

function baseprod(n, y)
    sumprods = 0.0
    ndays = y * 365
    for _ in 1:n
        model = init_spatialrust(
            steps = ndays,
            row_d = 2,
            plant_d = 1,
            shade_d = 9,
            common_map = :regshaded,
            prune_sch = [74, 196, 319],
            post_prune = [0.15, 0.15, 0.15],
            inspect_period = 32,
            inspect_effort = 0.25,
            fungicide_sch = [125, 166, 237]
        )
        step_n!(model, ndays)
        sumprods += model.current.prod
    end
    return sumprods
end

meanprod = baseprod(n, y)/(n*y)
writedlm("results/GA/baseProduction.csv", meanprod, ',')