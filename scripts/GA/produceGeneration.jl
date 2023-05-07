import Pkg
Pkg.activate(".")
using DelimitedFiles, Random
using StatsBase: sample

popsize = parse(Int, ARGS[1])
pastgen = parse(Int, ARGS[2])
maxgens = parse(Int, ARGS[3])
reps = parse(Int, ARGS[4])
steps = parse(Int, ARGS[5])
coffee_price = parse(Float64, ARGS[6])
pcross = parse(Float64, ARGS[7])
pmut = parse(Float64, ARGS[8])
expfolder = ARGS[9]

include("../../src/GA/Generation.jl")
include("../../src/GA/SlurmScripts.jl")

pastgen0s = lpad(pastgen, 3, "0")
if pastgen < maxgens # || end condition?
    rng = Xoshiro()
    gen = pastgen + 1
    gen0s = lpad(gen, 3, "0")

    # read past gen's pop and fitnesses
    pastpop = BitMatrix(readdlm(joinpath(expfolder,"pops", string("g-", pastgen0s,".csv")), ',', Bool))
    fitnfiles = readdir(joinpath(expfolder,"fitns", string("g-", pastgen0s,"/")), join = true)
    fitns = zeros(popsize)
    for f in fitnfiles
        ind = parse(Int, f[end-6:end-4])
        fitns[ind] = only(readdlm(f, ','))
    end

    # copy fitnesses to single file and create dir for next generation
    writedlm(joinpath(expfolder,"histftns", string("g-", pastgen0s,".csv")), fitns, ',')
    mkpath(joinpath(expfolder, "fitns", string("g-", gen0s)))

    # progeny
    newpop = tourn_select(pastpop, fitns, popsize, rng)
    xover!(newpop, pcross, popsize, 79, rng)
    mutate!(newpop, pmut, rng)

    # write new gen's pop
    writedlm(joinpath(expfolder,"pops", string("g-", gen0s,".csv")), newpop, ',')

    # transcribe from pop (produce Ints) and write files
    trfolder = mkpath(joinpath(expfolder, "transcs", string("g-", gen0s)))
    transcribe(newpop, trfolder)
    # write .sh with new ARGS
    arraypath = write_array_script(popsize, gen, reps, steps, coffee_price, expfolder)
    newgenpath = write_ngen_script(popsize, gen, maxgens, reps, steps, coffee_price, pcross, pmut, expfolder)
    # sbatch array for inds
    depend = readchomp(`sbatch --parsable $arraypath`)
    # sbatch afterok for next progeny
    run(`sbatch --dependency=afterok:$depend $newgenpath`, wait = false)
else
    # read past gen's fitnesses to copy them in a single file
    fitnfiles = readdir(joinpath(expfolder,"fitns", string("g-", pastgen0s,"/")), join = true)
    fitns = zeros(popsize)
    for f in fitnfiles
        ind = parse(Int, f[end-6:end-4])
        fitns[ind] = only(readdlm(f, ','))
    end
    writedlm(joinpath(expfolder,"histftns", string("g-", pastgen0s,".csv")), fitns, ',')
    
    p = mkpath(joinpath("results/GA", rsplit(expfolder, "/", limit = 2)[2]))
    hfitnsfiles = readdir(joinpath(expfolder, "histftns"), join = true)
    hfitns = fill(Float64[], maxgens)
    for f in hfitnsfiles
        g = parse(Int, f[end-6:end-4])
        hfitns[g] = vec(readdlm(f, ',', Float64))
    end
    histfitness = reduce(hcat, hfitns)
    writedlm(joinpath(p,"fitnesshistory.csv"), hfitns, ',')
end