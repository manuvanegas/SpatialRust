import Pkg
Pkg.activate(".")
using DelimitedFiles, SpatialRust
# using Statistics: mean

n = 300
y = 2

function baseprod(n, y)
    sumprods = 0.0
    ndays = y * 365
    for r in 1:n
        if r % 10 == 0
            model = init_spatialrust(
                steps = ndays,
                row_d = 2,
                plant_d = 1,
                shade_d = 9,
                common_map = :regshaded,
                prune_sch = [74, 196, 319],
                post_prune = [0.05, 0.05, 0.05],
                inspect_period = 32,
                inspect_effort = 0.25,
                fungicide_sch = [125, 176, 237],
                fung_stratg = :cal,
            )
            @time step_n!(model, ndays)
            sumprods += model.current.prod
            println(r)
            flush(stdout)
            GC.gc()
        else
            model = init_spatialrust(
                steps = ndays,
                row_d = 2,
                plant_d = 1,
                shade_d = 9,
                common_map = :regshaded,
                prune_sch = [74, 196, 319],
                post_prune = [0.05, 0.05, 0.05],
                inspect_period = 32,
                inspect_effort = 0.25,
                fungicide_sch = [125, 176, 237],
                fung_stratg = :cal,
            )
            step_n!(model, ndays)
            sumprods += model.current.prod
        end
    end
    return sumprods
end

meanprod = baseprod(n, y)/(n*y)
writedlm("results/GA4/baseProduction-$(y)y.csv", meanprod, ',')