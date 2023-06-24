import Pkg
Pkg.activate(".")
using CSV, DataFrames, SpatialRust, StatsBase

filepath = ARGS[1]
arrayid = parse(Int, ARGS[2])
# years = parse(Int, ARGS[3])
reps = parse(Int, ARGS[3])

p = mkpath("results/GA4/fittest/$reps")

rawpars = CSV.read(filepath, DataFrame)[arrayid, :]

pars = DataFrame(
    prune_sch = [map(x -> parse(Int, x), split(rawpars.prune_sch[2:end-1], ','))],
    post_prune = [map(x -> parse(Float64, x), split(rawpars.post_prune[2:end-1], ','))],
    rm_lesions = rawpars.rm_lesions,
    inspect_period = rawpars.inspect_period,
    row_d = rawpars.row_d,
    inspect_effort = rawpars.inspect_effort,
    plant_d = rawpars.plant_d,
    shade_d = rawpars.shade_d,
    barriers = Tuple(map(x -> parse(Int, x), split(rawpars.barriers[2:end-1], ','))),
    fungicide_sch = [map(x -> parse(Int, x), split(rawpars.fungicide_sch[2:end-1], ','))],
    fung_stratg = Symbol(rawpars.fung_stratg),
    incidence_thresh = rawpars.incidence_thresh,
    steps = rawpars.steps,
    coffee_price = rawpars.coffee_price,
)[1,:]

scen = (:p_np_s, :s_np_s, :p_p_s, :s_p_s, :p_np_m, :s_np_m, :p_p_m, :s_p_m)[arrayid]

visible(a::Float64) = a > 0.05 ? a : 0.0

function runfittest(pars, reps)
    outs = DataFrame(
        p4 = Float64[], p5 = Float64[], p6 = Float64[], p7 = Float64[],
        s4 = Float64[], s5 = Float64[], s6 = Float64[], s7 = Float64[],
        f4 = Int[], f5 = Int[], f6 = Int[], f7 = Int[],
    )
    
    for c in eachcol(outs)
        sizehint!(c, reps)
    end

    everyn = 7

    for i in 1:reps
        model = init_light_spatialrust(; pars...)
        allcofs = model.agents
        ninsp = round(Int, length(allcofs) * 0.1)
        steps = copy(pars.steps)
        cprice = copy(pars.coffee_price)
        
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
        ls4 = sev / insps
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
        ls5 = sev / insps
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
        ls6 = sev / insps
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
        ls7 = sev / insps
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

println(scen)

@time outs = runfittest(pars, reps)

println("writing outs")

df = hcat(DataFrame(scenario = scen, rep = 1:reps), outs)
CSV.write(joinpath(p, "$(scen).csv"), df)
