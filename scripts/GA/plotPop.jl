using CairoMakie, CSV, DataFrames, Statistics

include("../../src/GA/Plots.jl")

obj = "shorttermprofit-0.0"
pcross = 0.5
pmut = 0.02



###########################################


obj = "sev-p"
popfiles = readdir("results/GA/4/2/$obj/pops/", join = true);

popsraw = [readaddinfo(f) for f in popfiles];
pops = reduce(vcat, popsraw);

freqs = select(pops, :gen, :pos,
    AsTable(r"Column") => ByRow(minfreq) => :minfreq
)

fhm = historyhm(freqs, true)
##
# savedissGA("test.png", fhm)


poss = [(1,1),(1,2),(2,1),(2,2)]
exps = ["profit-np", "profit-p", "sev-np", "sev-p"]

exps2 = ["profit-np-s",  "sev-np-s", "profit-p-s1b",  "sev-p-s1b", "profit-np",  "sev-np", "profit-p",  "sev-p",]
poss2 = [(1,1),(1,2),(2,1),(2,2),(3,1),(3,2),(4,1),(4,2)]

hmfig = hmfigure("results/GA/4/2/", exps2, poss2)

savedissGA("hm8.png", hmfig)