import Pkg
Pkg.activate(".")
using DelimitedFiles, SpatialRust
using Statistics: mean

indiv = parse(Int, ARGS[1])
gen = parse(Int, ARGS[2])
reps = parse(Int, ARGS[3])
steps = parse(Int, ARGS[4])
coffee_price = parse(Float64, ARGS[5])
expfolder = ARGS[6]
obj = Symbol(ARGS[7])
prem = parse(Bool, ARGS[8])
popsize = parse(Int, ARGS[9])

include("../../src/GA/Individual.jl")
# parnames = [:row_d, :plant_d, :shade_d, :barriers, :barrier_rows, :prune_sch, :target_shade,
# :inspect_period, :inspect_effort, :fungicide_sch, :incidence_as_thr, :incidence_thr]
# starts = [2; 1; 2; 1; 1; fill(5, 3); fill(5,3); 4; 5; fill(5, 3); 1; 5]
# stops = [1; 1 .+ cumsum(starts[1:end-1])] 

# using CSV
# phenfile = string("ph-", gen, ".csv")
# # popfile = string(ARGS[2], ".csv")
# phenod, phenon = CSV.read(joinpath("/scratch/mvanega1/GA",obj,"phens/", phenfile), ',', header = true)
# pheno = NamedTuple(zip(vec(phenon), phenod[indiv,:]))

if obj == :all
    expfs = split(read("/scratch/mvanega1/GA4/expfolders.txt", String))
    exp = div(indiv - 1, popsize) + 1
    expfolder = expfs[exp]
    println(indiv)
    indiv = mod1(indiv, popsize)
    obj = ifelse(exp < 3, :profit, :sev)
    prem = iseven(exp)
end

# loci = readdlm(joinpath("/scratch/mvanega1/GA/",obj,"loci.csv"), ',', Int)
filename = string("g-", lpad(gen, 3, "0"), "/i-", lpad(indiv, 3, "0"), ".csv")
transcripts = readdlm(joinpath(expfolder, "transcs/", filename), ',', Int)

# "phenotype"
pheno = ints_to_pars(transcripts, steps, coffee_price)
# produce individual fitness
fitness = sptlrust_fitness(pheno, reps, steps, coffee_price, obj, prem)

# write fitness
writedlm(joinpath(expfolder, "fitns/", filename), fitness, ',')
