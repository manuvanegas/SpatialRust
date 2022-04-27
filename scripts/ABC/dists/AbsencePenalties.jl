@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"
@everywhere using Arrow, DataFrames, Distributed

agesfiles = readdir("/scratch/mvanega1/ABC/sims/ages/", join = true, sort = false)
cyclesfiles = readdir("/scratch/mvanega1/ABC/sims/cycles/", join = true, sort = false)

allfiles = vcat(agesfiles, cyclesfiles)

@everywhere function penalties!(file::String, num::Int)
    df = DataFrame(Arrow.Table(file))
    replace!(df[!, :area_m], NaN => -1.0)
    replace!(df[!, :spores_m], NaN => -1.0)
    Arrow.write(file, df)
    df = nothing
    println(num)
    flush(stdout)
    GC.gc()
    return nothing
end

# penalties!.(agesfiles)
v = pmap((i,f) -> penalties!(f,i), enumerate(allfiles); retry_delays = fill(0.1, 3))
