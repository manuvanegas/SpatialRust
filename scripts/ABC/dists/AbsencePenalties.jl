using Arrow, DataFrames, Distributed

agesfiles = readdir("/scratch/mvanega1/ABC/sims/ages/", join = true, sort = false)
cyclesfiles = readdir("/scratch/mvanega1/ABC/sims/cycles/", join = true, sort = false)

allfiles = vcat(agesfiles, cyclesfiles)

function penalties!(file::String)
    df = DataFrame(Arrow.Table(file))
    replace!(df[!, :area_m], NaN => -1.0)
    replace!(df[!, :spores_m], NaN => -1.0)
    Arrow.write(file, df)
    df = nothing
    GC.gc()
    return nothing
end

# penalties!.(agesfiles)
pmap(penalties!, allfiles; retry_delays = fill(0.1, 3))
