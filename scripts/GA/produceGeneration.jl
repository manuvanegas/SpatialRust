using DelimitedFiles, Random

popsize = parse(Int, ARGS[1])
pastgen = parse(Int, ARGS[2])
maxgens = parse(Int, ARGS[3])
reps = parse(Int, ARGS[4])
steps = parse(Int, ARGS[5])
coffee_price = parse(Float64, ARGS[6])
pcross = parse(Float64, ARGS[7])
pmut = parse(Float64, ARGS[8])
coffee_price = parse(Float64, ARGS[9])
expfolder = ARGS[10]

include("../../src/GA/Generation.jl")

gen = pastgen + 1
if gen < maxgens # || end condition?
    rng = Xoshiro()
    pastgen0s = lpad(pastgen, 3, "0")
    gen0s = lpad(gen, 3, "0")

    # read past gen's pop and fitnesses
    pastpop = readdlm(joinpath(expfolder,"pops", string("g-", pastgen0s,".csv")), ',', Int)
    fitnfiles = readdir(joinpath(expfolder,"fitns", string("g-", pastgen0s,"/")), join = true)
    fitns = zeros(popsize)
    for f in fitnfiles
        ind = parse(Int, f[end-6:end-4])
        fitns[ind] = only(readdlm(f, ','))
    end

    # copy fitnesses to single file and create dir for next generation
    writedlm(joinpath(expfolder,"histfitns", string("g-", pastgen0s,".csv")), fitns, ',')
    mkpath(joinpath(expfolder, "fitns", string("g-", gen0s)))

    # progeny
    newpop = tourn_select(pastpop, fitns, popsize, rng)
    xover!(newpop, pcross, popsize, 67, rng)
    mutate!(newpop, pmut, rng)

    # transcribe from pop (produce Ints) and write files
    trfolder = mkpath(joinpath(expfolder, "transcs", string("g-", gen0s)))
    transcribe(newpop, trfolder)

    # write new gen's pop + transcripts (Int)
    writedlm(joinpath(expfolder,"pops", string("g-", gen0s,".csv")), newpop,',')
    # write .sh with new ARGS
    arraypath = write_array_script(popsize, gen, reps, steps, coffee_price, expfolder)
    newgenpath = write_ngen_script(popsize, gen, reps, steps, coffee_price, pcross, pmut, expfolder)
    # sbatch array for inds
    run(`sbatch $arraypath`, wait = false)
    # sbatch afterok for next progeny
    run(`sbatch $newgenpath`, wait = false)

    println("Running gen $gen")
else
    mkpath(joinpath("~/SpatialRust/results/GA", rsplit(expfolder, "/", limit = 2)[2]))
    fitnsfiles = readdir(joinpath(expfolder, "histfitns"), join = true)
    histfitness = reduce(hcat, [read(f, ',', Float64) for f in fitnfiles])
end