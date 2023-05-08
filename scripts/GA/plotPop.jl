using CairoMakie, CSV, DataFrames, Statistics

include("../../src/GA/Plots.jl")

obj = "shorttprofit3032"
obj = "longtermprofit"
pcross = 0.5
pmut = 0.02

function readaddinfo(f)
    df = CSV.read(f, DataFrame, header = false)
    i = parse(Int, f[end-6:end-4])
    transform!(df, eachindex => :pos)
    df.gen .= i
    return df
end

function minfreq(v)
    ts = mean(v)
    return min(ts, 1.0 - ts)
end


###########################################


popfiles = readdir("results/GA/$obj-$pcross-$pmut/pops/", join = true)

popsraw = [readaddinfo(f) for f in popfiles]
pops = reduce(vcat, popsraw)

freqs = select(pops, :gen, :pos,
    AsTable(r"Column") => ByRow(minfreq) => :minfreq
)

historyhm(freqs)