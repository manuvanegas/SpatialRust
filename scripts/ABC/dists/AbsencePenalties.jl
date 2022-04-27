@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere using Arrow, DataFrames, Distributed

agesfiles = readdir("/scratch/mvanega1/ABC/sims/ages/", join = true, sort = false)
cyclesfiles = readdir("/scratch/mvanega1/ABC/sims/cycles/", join = true, sort = false)

allfiles = vcat(agesfiles, cyclesfiles)

@everywhere function penalties!(file::String)
    df = copy(DataFrame(Arrow.Table(file)))
    replace!(df[!, :area_m], NaN => -1.0, -Inf => -0.5, Inf => -0.5)
    replace!(df[!, :spores_m], NaN => -1.0, -Inf => -0.5, Inf => -0.5)
    Arrow.write(file, df)
    df = nothing
    # println(num)
    # flush(stdout)
    GC.gc()
    return nothing
end

# penalties!.(agesfiles)
# v = pmap(penalties!, allfiles; retry_delays = fill(0.1, 3))

@everywhere function negatives!(file::String)
    df = copy(DataFrame(Arrow.Table(file)))
    df[toobigsmall.(df.area_m), :area_m] .= -0.5
    df[toobigsmall.(df.spores_m), :spores_m] .= -0.5
    # replace!(df[!, :area_m], NaN => -1.0, -Inf => -0.5, Inf => -0.5)
    # replace!(df[!, :spores_m], NaN => -1.0, -Inf => -0.5, Inf => -0.5)
    Arrow.write(file, df)
    df = nothing
    # println(num)
    # flush(stdout)
    GC.gc()
    return nothing
end

@everywhere function toobigsmall(x::Float64)::Bool
    if x < 0.0 && x != -1.0
        return true
    elseif x > 5.0
        return true
    else
        return false
    end
end

v = pmap(negatives!, allfiles; retry_delays = fill(0.1, 3))
