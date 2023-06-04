export dummyrun_spatialrust, simplerun, justtwosteps

function dummyrun_spatialrust(steps::Int = 200, side::Int = 60, maxlesions::Int = 25; kwargs...)
    model = init_spatialrust(steps = steps, map_side = side, max_lesions = maxlesions; kwargs...)

    a_df, m_df = run!(model, dummystep, step_model!, steps;
        # adata = [(:n_lesions, median, justrusts), (:state, medsum_s, justrusts), (:production, mean, justcofs)],
        adata = [(:n_lesions, emedian, rusted), (tot_area, emedian, rusted), (:production, mean)],
        mdata = [incidence, n_rusts])
    rename!(a_df, [:step, :n_lesion_med, :tot_area_med, :production_mean])

    return a_df, m_df, model
end

# function dummyrun_fullsun_spatialrust(steps::Int = 200, side::Int = 60, maxlesions::Int = 25; kwargs...)
#     model = init_spatialrust(steps = steps, map_side = side, max_lesions = maxlesions, common_map = :fullsun; kwargs...)

#     a_df, m_df = run!(model, dummystep, step_model!, steps;
#         # adata = [(:n_lesions, median, justrusts), (:state, medsum_s, justrusts), (:production, mean, justcofs)],
#         adata = [(:n_lesions, emedian, rusted), (tot_area, emedian, rusted), (:production, mean)],
#         mdata = [incidence, n_rusts])
#     rename!(a_df, [:step, :n_lesion_med, :tot_area_med, :production_mean])

#     return a_df, m_df, model
# end

function justtwosteps(side::Int = 60)
    model = init_spatialrust(steps = steps, map_side = side, max_lesions = maxlesions, common_map = :fullsun)
    step!(model, dummystep, step_model!, 2)
    return model
end

function step_n!(model::SpatialRustABM, n::Int)
    s = 0
    while s < n
        step_model!(model)
        s += 1
    end
    return s
end

function step_while!(model::SpatialRustABM, s::Int, n::Int)
    while s < n && model.current.withinbounds
        step_model!(model)
        s += 1
    end
    return s
end

function simplerun(steps::Int = 365; kwargs...)
    model = init_spatialrust(steps = steps; kwargs...)

    df = runsimple!(model, steps)

    return df#, model
end

function runsimple!(model::SpatialRustABM, steps::Int)
    meanshade = mean(model.shade_map)
    allcofs = model.agents
    ncofs = length(allcofs)
    sporepct = model.rustpars.spore_pct

    df = DataFrame(dayn = Int[],
        veg = Float64[], storage = Float64[], production = Float64[],
        indshade = Float64[], mapshade = Float64[],
        nl = Float64[], sumarea = Float64[], sumspore = Float64[],
        sporearea = Float64[],
        active = Float64[], farmprod = Float64[],
        nrusts = Int[], mages = Float64[],
    )
    for c in eachcol(df)
        sizehint!(c, steps)
    end

    s = 0
    while s < steps
        indshade = model.current.ind_shade

        sumareas = Iterators.filter(>(0.0), map(r -> sum(r.areas), allcofs))
        # sumareas = Iterators.filter(>(0.0), map(emptymean, allcofs))
        if isempty(sumareas)
            msuma = 0.0
            msumsp = 0.0
            mages = 0.0
        else
            msuma = mean(sumareas)
            sumspores = map(r -> sum(r.spores), allcofs)
            msumsp = mean(sumspores)
            mages = mean(map(a -> meanage(a.ages), allcofs))
        end

        push!(df, [
            model.current.days,
            mean(map(a -> a.veg, allcofs)),
            mean(map(a -> a.storage, allcofs)),
            mean(map(a -> a.production, allcofs)),
            indshade,
            indshade * meanshade,
            mean(map(a -> a.n_lesions, allcofs)),
            msuma,
            msumsp,
            mean(map(sporear, allcofs)) * sporepct,
            sum(map(active, allcofs)) / ncofs,
            copy(model.current.prod),
            sum(map(a -> a.rusted, allcofs)),
            mages
        ])
        step!(model, dummystep, step_model!, 1)
        s += 1
    end

    indshade = model.current.ind_shade
    
    sumareas = Iterators.filter(>(0.0), map(r -> sum(r.areas), allcofs))
    # sumareas = Iterators.filter(>(0.0), map(emptymean, allcofs))
    if isempty(sumareas)
        msuma = 0.0
        msumsp = 0.0
        mages = 0.0
    else
        msuma = mean(sumareas)
        sumspores = map(r -> sum(r.spores), allcofs)
        msumsp = mean(sumspores)
        mages = mean(map(a -> meanage(a.ages), allcofs))
    end

    push!(df, [
        model.current.days,
        mean(map(a -> a.veg, allcofs)),
        mean(map(a -> a.storage, allcofs)),
        mean(map(a -> a.production, allcofs)),
        indshade,
        indshade * meanshade,
        mean(map(a -> a.n_lesions, allcofs)),
        msuma,
        msumsp,
        mean(map(sporear, allcofs)) * sporepct,
        sum(map(active, allcofs)) / ncofs,
        copy(model.current.prod),
        sum(map(a -> a.rusted, allcofs)),
        mages
    ])

    return df
end

function sporear(a::Coffee)
    return sum((ar * sp for (ar,sp) in zip(a.areas, a.spores)), init = 0.0)
end

function meanage(ages)
    if isempty(ages)
        return 0.0
    else
        return mean(ages)
    end
end

emptymean(c) = isempty(c.areas) ? 0.0 : mean(filter(>(0.0), c.areas))

function followone(steps::Int = 365; kwargs...)
    model = init_spatialrust(steps = steps,
        farm_map = [0 0 0 0 0; 0 0 0 0 0; 0 1 0 1 0; 0 0 0 0 0; 0 0 0 0 0],
        p_rusts = 0.0,
        ; kwargs...)
    ci = model.agents[1]
    ci.n_lesions = 3
    ci.ages = [10, 8, 3]
    ci.areas = [0.1, 0.05, 0.0003]
    ci.spores = [false, false, false]
    ci.rusted = true

    df = DataFrame(dayn = Int[],
    veg = Float64[], storage = Float64[], production = Float64[],
    indshade = Float64[], mapshade = Float64[], sl = Float64[],
    nl = Int[],
    sumarea = Float64[], maxarea = Float64[], minarea = Float64[], allareas = Vector{Float64}[],
    spores = Vector{Bool}[], deps = Float64[], ndeps = Float64[],
    maxage = Int[], minage = Int[], allages = Vector{Int}[],
    active = Bool[], rusted = Bool[], nrusts = Int[],
    farmprod = Float64[], fung = Int[]
    )
    for c in eachcol(df)
        sizehint!(c, steps)
    end

    meanshade = mean(model.shade_map)
    c2 = model.agents[2]

    println(ci)
    println(c2)

    s = 0
    while s < steps
        indshade = model.current.ind_shade
        areas = copy(c2.areas)
        ages = copy(c2.ages)
        spores = copy(c2.spores)
        push!(df, [
            model.current.days,
            c2.veg,
            c2.storage,
            c2.production,
            indshade,
            indshade * meanshade,
            c2.sunlight,
            c2.n_lesions,
            sum(areas),
            maximum(areas, init = 0.0),
            minimum(areas, init = 0.0),
            areas,
            spores,
            c2.deposited,
            c2.newdeps,
            maximum(ages, init = 0.0),
            minimum(ages, init = 0.0),
            ages,
            c2.exh_countdown == 0,
            c2.rusted,
            sum(map(a -> a.rusted, model.agents)),
            copy(model.current.prod),
            model.current.fung_count,
        ])
        step_model!(model)
        s += 1
    end

    
    indshade = model.current.ind_shade
    areas = c2.areas
    ages = c2.ages
    spores = copy(c2.spores)
    push!(df, [
        model.current.days,
        c2.veg,
        c2.storage,
        c2.production,
        indshade,
        indshade * meanshade,
        c2.sunlight,
        c2.n_lesions,
        sum(areas),
        maximum(areas, init = 0.0),
        minimum(areas, init = 0.0),
        areas,
        spores,
        c2.deposited,
        c2.newdeps,
        maximum(ages, init = 0.0),
        minimum(ages, init = 0.0),
        ages,
        c2.exh_countdown == 0,
        c2.rusted,
        sum(map(a -> a.rusted, model.agents)),
        copy(model.current.prod),
        model.current.fung_count,
    ])

    return df#, model
end

function secondloss(steps::Int = 730; kwargs...)
    model = init_spatialrust(steps = steps; kwargs...)

    df = DataFrame(
        dayn = Int[],
        veg = Float64[], storage = Float64[], production = Float64[],
        nl = Float64[], sumarea = Float64[], #sumspores = Float64[],
        deps = Float64[], meanage = Float64[],
        active = Float64[], rusted = Float64[], farmprod = Float64[],
    )
    
    s = 0
    allcofs = model.agents
    ncofs = length(allcofs)

    while s < 365
        step_model!(model)
        sumareas = Iterators.filter(>(0.0), map(r -> sum(r.areas), allcofs))
        # sumareas = Iterators.filter(>(0.0), map(emptymean, allcofs))
        actages = Iterators.filter(>(0.0), map(r -> meanage(r.ages), allcofs))
        if isempty(sumareas)
            msuma = 0.0
            msumsp = 0.0
            mages = 0.0
        else
            msuma = mean(sumareas)
            sumspores = map(r -> sum(r.spores), allcofs)
            msumsp = mean(sumspores)
            mages = mean(actages)
        end
        push!(df, [
            model.current.days,
            mean(map(a -> a.veg, allcofs)),
            mean(map(a -> a.storage, allcofs)),
            mean(map(a -> a.production, allcofs)),
            mean(map(a -> a.n_lesions, allcofs)),
            msuma,
            # msumsp,
            mean(map(a -> a.deposited, allcofs)),
            mages,
            sum(map(active, allcofs)) / ncofs,
            sum(map(a -> a.rusted, allcofs)) / ncofs,
            copy(model.current.prod),
        ])
        s += 1
    end

    map(cure, allcofs)
    model.outpour .= 0.0

    while s < steps
        step_model!(model)
        sumareas = Iterators.filter(>(0.0), map(r -> sum(r.areas), allcofs))
        # sumareas = Iterators.filter(>(0.0), map(emptymean, allcofs))
        actages = Iterators.filter(>(0.0), map(r -> meanage(r.ages), allcofs))
        if isempty(sumareas)
            msuma = 0.0
            msumsp = 0.0
            mages = 0.0
        else
            msuma = mean(sumareas)
            sumspores = map(r -> sum(r.spores), allcofs)
            msumsp = mean(sumspores)
            mages = mean(actages)
        end
        push!(df, [
            model.current.days,
            mean(map(a -> a.veg, allcofs)),
            mean(map(a -> a.storage, allcofs)),
            mean(map(a -> a.production, allcofs)),
            mean(map(a -> a.n_lesions, allcofs)),
            msuma,
            # msumsp,
            mean(map(a -> a.deposited, allcofs)),
            mages,
            sum(map(active, allcofs)) / ncofs,
            sum(map(a -> a.rusted, allcofs)) / ncofs,
            copy(model.current.prod),
        ])
        s += 1
    end

    return df
end

function cure(c::Coffee)
    c.rusted = false
    c.newdeps = 0.0
    c.deposited = 0.0
    c.n_lesions = 0
    empty!(c.areas)
    empty!(c.spores)
    empty!(c.ages)
end