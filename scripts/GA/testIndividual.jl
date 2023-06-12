import Pkg
Pkg.activate(".")
using DelimitedFiles, SpatialRust
using Statistics: mean

indiv = parse(Int, ARGS[1])
gen = parse(Int, ARGS[2])
reps = parse(Int, ARGS[3])
steps = parse(Int, ARGS[4])
coffee_price = parse(Float64, ARGS[5])
scriptsfolder = ARGS[6]
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
    
    nobj = ifelse(exp < 3, :profit, :sev)
    nprem = iseven(exp)
    
elseif obj == :noprems
    expfs = split(read("/scratch/mvanega1/GA4/expfolders.txt", String))
    exp = div(indiv - 1, popsize) + 1
    expfolder = expfs[exp]
    println(indiv)
    indiv = mod1(indiv, popsize)
    
    nobj = ifelse(exp == 1, :profit, :sev)
    nprem = false
    
elseif obj == :prems
    expfs = split(read("/scratch/mvanega1/GA4/expfolders.txt", String))
    exp = div(indiv - 1, popsize) + 1
    expfolder = expfs[exp]
    println(indiv)
    indiv = mod1(indiv, popsize)
    
    nobj = ifelse(exp == 1, :profit, :sev)
    nprem = true
    
else
    expfolder = scriptsfolder
    nobj = obj
    nprem = prem
end

# loci = readdlm(joinpath("/scratch/mvanega1/GA/",obj,"loci.csv"), ',', Int)
filename = string("g-", lpad(gen, 3, "0"), "/i-", lpad(indiv, 3, "0"), ".csv")
transcripts = readdlm(joinpath(expfolder, "transcs/", filename), ',', Int)

# "phenotype"
pheno = ints_to_pars(transcripts, steps, coffee_price)
# produce individual fitness
fitness = sptlrust_fitness(pheno, reps, steps, coffee_price, nobj, nprem)

# write fitness
writedlm(joinpath(expfolder, "fitns/", filename), fitness, ',')

# see if all files of the gen are ready to sbatch next gen
gen0s = lpad(gen, 3, "0")
if obj == :all || obj == :noprems || obj == :prems
    nfiles = (200 * ifelse(obj == :all, 2, 1))
    nfs = 0
    for expf in expfs
        global nfs += length(readdir(joinpath(expf,"fitns", string("g-", gen0s,"/")), join = true))
    end
else
    nfiles = 100
    nfs = length(readdir(joinpath(scriptsfolder,"fitns", string("g-", gen0s,"/")), join = true))
end

println("$nfs files out of $nfiles")
if nfs == nfiles
    println("has newgen script been submitted yet?")
    gjname = "debug-GA-gen-$(gen + 1)"
    ijname = "GA-ind-g$(gen + 1)"
    genjob = readchomp(ignorestatus(pipeline(`myjobs`, `grep $gjname`)))
    indsjob = readchomp(ignorestatus(pipeline(`myjobs`, `grep $ijname`)))
    #running = readchomp(pipeline(`myjobs`, `grep -i running`, `wc -l`))
    if isempty(genjob) && isempty(indsjob) #&& running < 6
        scriptfile = joinpath(scriptsfolder, "scripts/newgen-$(gen + 1).sh")
        run(`sbatch --dependency=singleton $scriptfile`, wait = false)
        println("submitted")
    end
end

exit(0)
