import Pkg
Pkg.activate(".")
using CSV, DataFrames, SpatialRust

filepath = ARGS[1]
arrayid = parse(Int, ARGS[2])
# years = parse(Int, ARGS[3])
reps = parse(Int, ARGS[3])

p = mkpath("results/GA4/fittest/$reps")

pars = CSV.read(filepath, DataFrame)[arrayid, :]
# pars.steps = 2555

scen = (:p_np_s, :s_np_s, :p_p_s, :s_p_s, :p_np_m, :s_np_m, :p_p_m, :s_p_m)[arrayid]

function runfittest(pars, reps)
    outs = DataFrame(
        p4 = Float64[], p5 = Float64[], p6 = Float64[], p7 = Float64[],
        s4 = Float64[], s5 = Float64[], s6 = Float64[], s7 = Float64[],
        f4 = Int[], f5 = Int[], f6 = Int[], f7 = Int[],
    )

    everyn = 7

    for i in 1:reps
        model = init_light_spatialrust(pars...)
        steps = copy(pars.steps)
        lp4 = 0.0; lp5 = 0.0; lp6 = 0.0; lp7 = 0.0
        ls4 = 0.0; ls5 = 0.0; ls6 = 0.0; ls7 = 0.0
        lf4 = 0.0; lf5 = 0.0; lf6 = 0.0; lf7 = 0.0
        sev = 0.0
        insps = 0
        fungs = 0

        s = 0

        while s < 1460
            s += step_n!(model, everyn)
            inspected = sample(allcofs, ninsp, replace = false)
            sev += mean(map(c -> sum(visible, c.areas, init = 0.0), inspected))
            insps += 1
            
            if s % 365 == 364
                fungs += model.current.fung_count
                step_model!(model)
                s += 1
            end
        end

        lp4 = model.current.prod * cprice - model.current.costs
        ls4 = sev / inspected
        lf4 = fungs

        while s < 1825
            s += step_n!(model, everyn)
            inspected = sample(allcofs, ninsp, replace = false)
            sev += mean(map(c -> sum(visible, c.areas, init = 0.0), inspected))
            insps += 1
            
            if s % 365 == 364
                fungs += model.current.fung_count
                step_model!(model)
                s += 1
            end
        end

        lp5 = model.current.prod * cprice - model.current.costs
        ls5 = sev / inspected
        lf5 = fungs

        while s < 2190
            s += step_n!(model, everyn)
            inspected = sample(allcofs, ninsp, replace = false)
            sev += mean(map(c -> sum(visible, c.areas, init = 0.0), inspected))
            insps += 1
            
            if s % 365 == 364
                fungs += model.current.fung_count
                step_model!(model)
                s += 1
            end
        end

        lp6 = model.current.prod * cprice - model.current.costs
        ls6 = sev / inspected
        lf6 = fungs

        while s < 2555
            s += step_n!(model, everyn)
            inspected = sample(allcofs, ninsp, replace = false)
            sev += mean(map(c -> sum(visible, c.areas, init = 0.0), inspected))
            insps += 1
            
            if s % 365 == 364
                fungs += model.current.fung_count
                step_model!(model)
                s += 1
            end
        end

        lp7 = model.current.prod * cprice - model.current.costs
        ls7 = sev / inspected
        lf7 = fungs

        push!(outs,
            [lp4, lp5, lp6, lp7, ls4, ls5, ls6, ls7, lf4, lf5, lf6, lf7]
        )
        if i % 25 == 0
            GC.gc()
        end
    end
    return outs
end

outs = runfittest(pars, reps)

df = hcat(DataFrame(scenario = scen, rep = 1:reps), outs)
CSV.write(joinpath(p, "$(scen).csv"), df)
