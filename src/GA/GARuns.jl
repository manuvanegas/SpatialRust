
function transcripts(col)
    pos = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:14, 15:20, 21:21, 22:27, 28:28, 29:34, 35:40, 41:46, 47:51, 52:57, 58:63, 64:64, 65:70, 71:71, 72:77, 78:78, 79:80, 81:86]
    transcripts = [bits_to_int(col[p]) for p in pos]
    # transcripts[[1:3; 5]] .+= 1
    return ints_to_pars(transcripts, 1460, 0.65)
end

function garuns(n::Int, steps::Int, rem::Float64; kwargs...)
    dfs = [run(steps, rem; kwargs...) for _ in 1:n]

    return reduce(vcat, dfs)
end

function run(steps::Int, rem::Float64; kwargs...)
    model = init_spatialrust(steps = steps; kwargs...)
    
    meanshade = mean(model.shade_map)
    allcofs = model.agents
    ncofs = length(allcofs)
    sporepct = model.rustpars.spore_pct
    cprice = model.mngpars.coffee_price

    df = DataFrame(dayn = Int[],
        indshade = Float64[], mapshade = Float64[],
        production = Float64[], active = Float64[],
        incidence = Float64[], obs_incidence = Float64[],
        sumarea = Float64[], inoculum = Float64[],
        remprofit = Float64[], costs = Float64[],
        fung = Int[],
    )
    for c in eachcol(df)
        sizehint!(c, steps)
    end

    s = 0
    while s < steps
        s += 1
        indshade = model.current.ind_shade
        sumareas = Iterators.filter(>(0.0), map(r -> sum(r.areas), allcofs))
        msuma = isempty(sumareas) ? 0.0 : mean(sumareas)

        push!(df, [
            model.current.days,
            indshade,
            indshade * meanshade,
            mean(map(currentprod, allcofs)),
            sum(map(active, allcofs)) / ncofs,
            sum(map(activeRust, allcofs)) / ncofs,
            model.current.obs_incidence,
            msuma,
            mean(map(inoculum, allcofs)) * sporepct,
            model.current.prod * rem * cprice,
            model.current.costs,
            model.current.fungicide,
        ])
        step_model!(model)
    end

    return df
end

currentprod(c::Coffee)::Float64 = c.production

inoculum(r::Coffee)::Float64 =
    isempty(r.areas) ? 0.0 : sum(a * s for (a,s) in zip(r.areas, r.spores)) * (1.0 + r.sunlight)

