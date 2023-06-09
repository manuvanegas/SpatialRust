using DelimitedFiles, Random

popsize = parse(Int, ARGS[1])
maxgens = parse(Int, ARGS[2])
reps = parse(Int, ARGS[3])
steps = parse(Int, ARGS[4])
pcross = parse(Float64, ARGS[5])
pmut = parse(Float64, ARGS[6])
coffee_price = parse(Float64, ARGS[7])
suffix = ARGS[8]
obj = Symbol(ARGS[9])
prem = parse(Bool, ARGS[10])

include("../../src/GA/Generation.jl")
include("../../src/GA/SlurmScripts.jl")

if obj == :all
    # experiment id: obj function - pcross - pmut
    objnames = ["profit-np", "profit-p", "sev-np", "sev-p"]
    expfolders = string.("/scratch/mvanega1/GA4/", objnames, "-", suffix, "-", pcross, "-", pmut)
    write("/scratch/mvanega1/GA4/expfolders.txt", join(expfolders, " "))
    # mkpaths: pops, transcs, fitns, histftns, scripts
    poppaths = mkpath.(joinpath.(expfolders, "pops"))
    mkpath.(joinpath.(expfolders, "transcs"))
    mkpath.(joinpath.(expfolders, "fitns"))
    mkpath.(joinpath.(expfolders, "histftns"))
    mkpath.(joinpath.(expfolders, "scripts"))
    
    # init and save pop
    for (poppath, expfolder) in zip(poppaths, expfolders)
        local pop = bitrand(86, popsize)
        writedlm(joinpath(poppath, "g-001.csv"), pop, ',')
        # create fitness folder
        mkpath(joinpath(expfolder, "fitns", "g-001"))
        # transcribe from pop (produce Ints) and write files
        local trfolder = mkpath(joinpath(expfolder, "transcs", "g-001"))
        transcribe(pop, trfolder)
    end
    
    
    # create first .sh with new ARGS
    arraypath, runmins = write_array_script(popsize, 1, reps, steps, coffee_price, expfolders[1], obj, prem, popsize * 4)
    newgenpath = write_ngen_script(popsize, 1, maxgens, reps, steps, coffee_price, pcross, pmut, expfolders[1], obj, prem)
    # sbatch array for inds
    depend = readchomp(`sbatch --parsable $arraypath`)
    # sbatch after for next progeny
    jt = string(depend, "+", runmins, "?afterok:$depend")
    run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)
    
    
    #for (expfolder, obj, prem) in zip(expfolders, [:profit, :profit, :sev, :sev], [false, true, false, true])


else
    # experiment id: obj function - pcross - pmut
    expfolder = string("/scratch/mvanega1/GA4/", obj, "-", pcross, "-", pmut)
    # mkpaths: pops, transcs, fitns, histftns, scripts
    poppath = mkpath(joinpath(expfolder, "pops"))
    mkpath(joinpath(expfolder, "transcs"))
    mkpath(joinpath(expfolder, "fitns"))
    mkpath(joinpath(expfolder, "histftns"))
    mkpath(joinpath(expfolder, "scripts"))
    
    # init and save pop
    pop = bitrand(86, popsize)
    writedlm(joinpath(poppath, "g-001.csv"), pop, ',')
    
    # create fitness folder
    mkpath(joinpath(expfolder, "fitns", "g-001"))
    
    # transcribe from pop (produce Ints) and write files
    trfolder = mkpath(joinpath(expfolder, "transcs", "g-001"))
    transcribe(pop, trfolder)
    
    # create first .sh with new ARGS
    arraypath, runmins = write_array_script(popsize, 1, reps, steps, coffee_price, expfolder, popsize)
    newgenpath = write_ngen_script(popsize, 1, maxgens, reps, steps, coffee_price, pcross, pmut, expfolder)
    # sbatch array for inds
    depend = readchomp(`sbatch --parsable $arraypath`)
    # sbatch after for next progeny
    jt = string(depend, "+", runmins, "?afterok:$depend")
    run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)
end
