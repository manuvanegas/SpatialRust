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
if pastgen < maxgens
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
    xover!(newpop, pcross, popsize, 86, rng)
    mutate!(newpop, pmut, rng)

    # write new gen's pop
    writedlm(joinpath(expfolder,"pops", string("g-", gen0s,".csv")), newpop, ',')

    # transcribe from pop (produce Ints) and write files
    trfolder = mkpath(joinpath(expfolder, "transcs", string("g-", gen0s)))
    transcribe(newpop, trfolder)
    # write .sh with new ARGS
    arraypath, runmins = write_array_script(popsize, gen, reps, steps, coffee_price, expfolder)
    newgenpath = write_ngen_script(popsize, gen, maxgens, reps, steps, coffee_price, pcross, pmut, expfolder)
    # sbatch array for inds
    println("sbatch --parsable $arraypath")
    println("First try.")
    try
        depend = readchomp(`sbatch --parsable $arraypath`)
        println(depend)
        flush(stdout)
        # sbatch after for next progeny
        jt = string(depend, "+", runmins, "?afterok:$depend")
        run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)
        println("sbatch --dependency=after:$jt $newgenpath")
    catch
        jname = "GA-ind-g$gen"
        sleep(5)
        println("Second try. Reading job id from myjobs")
        try
            arrayid = first(split(readchomp(pipeline(`myjobs`, `grep $jname`))))
            depend = first(split(arrayid, "_"))
            # sbatch after for next progeny
            jt = string(depend, "+", runmins, "?afterok:$depend")
            run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)
            println("sbatch --dependency=after:$jt $newgenpath")
        catch
            sleep(15)
            arrayid = first(split(readchomp(pipeline(`myjobs`, `grep $jname`))))
            depend = first(split(arrayid, "_"))
            # sbatch after for next progeny
            jt = string(depend, "+", runmins, "?afterok:$depend")
            run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)
            println("sbatch --dependency=after:$jt $newgenpath")
        end
        #run(`scancel -n $jname`)
        #sleep(2)
        #run(`scancel -n $jname`)
        #sleep(10)
        #run(`scancel -n $jname`)
        #println("Second try. Cancelling jobs with name $jname")
        #sleep(20)
        #rm("/home/mvanega1/SpatialRust/slurmjobid-$gen.txt", force = true)
        #println("Second try. Submitting again.")
        #depend = readchomp(ignorestatus(`sbatch --parsable $arraypath`))
        #println(depend)
        #if length(depend) == 0
            #println("Third try. Sleeping 45 s so job id is written to file.")
            #sleep(45)
            #println("Third try. Submitting again.")
            #depend = readchomp("/home/mvanega1/SpatialRust/slurmjobid-$gen.txt")
            #println(depend)
        #end
        #flush(stdout)
        # sbatch after for next progeny
        #jt = string(depend, "+", runmins, "?afterok:$depend")
        #run(`sbatch --dependency=after:$jt?afterok:$depend $newgenpath`, wait = false)
        #println("sbatch --dependency=after:$jt?afterok:$depend $newgenpath")
    end
else
    # read past gen's fitnesses to copy them in a single file
    fitnfiles = readdir(joinpath(expfolder,"fitns", string("g-", pastgen0s,"/")), join = true)
    fitns = zeros(popsize)
    for f in fitnfiles
        ind = parse(Int, f[end-6:end-4])
        fitns[ind] = only(readdlm(f, ','))
    end
    writedlm(joinpath(expfolder,"histftns", string("g-", pastgen0s,".csv")), fitns, ',')
    
    p = mkpath(joinpath("results/GA4", rsplit(expfolder, "/", limit = 2)[2]))
    hfitnsfiles = readdir(joinpath(expfolder, "histftns"), join = true)
    hfitns = fill(Float64[], maxgens)
    for f in hfitnsfiles
        g = parse(Int, f[end-6:end-4])
        if g <= maxgens
            hfitns[g] = vec(readdlm(f, ',', Float64))
        end
    end
    histfitness = reduce(hcat, hfitns)
    writedlm(joinpath(p,"fitnesshistory-$(pastgen).csv"), hfitns, ',')
end