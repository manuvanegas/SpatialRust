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
obj = Symbol(ARGS[10])
prem = parse(Bool, ARGS[11])

include("../../src/GA/Generation.jl")
include("../../src/GA/SlurmScripts.jl")


pastgen0s = lpad(pastgen, 3, "0")
if pastgen < maxgens
    rng = Xoshiro()
    gen = pastgen + 1
    gen0s = lpad(gen, 3, "0")
    

    if obj == :all
        expfs = string.(split(read("/scratch/mvanega1/GA4/expfolders.txt", String)))
        for expfolder in expfs
            newgen(expfolder, pastgen0s, gen0s, popsize, rng)
        end
        arrayn = popsize * 4
    elseif obj == :noprems || obj == :prems
        expfs = string.(split(read("/scratch/mvanega1/GA4/expfolders.txt", String)))
        for expfolder in expfs
            newgen(expfolder, pastgen0s, gen0s, popsize, rng)
        end
        arrayn = popsize * 2
    else
        newgen(expfolder, pastgen0s, gen0s, popsize, rng)
        arrayn = popsize
    end
    
    # write .sh with new ARGS
    arraypath, runmins = write_array_script(popsize, gen, reps, steps, coffee_price, expfolder, obj, prem, arrayn)
    newgenpath = write_ngen_script(popsize, gen, maxgens, reps, steps, coffee_price, pcross, pmut, expfolder, obj, prem)
    # sbatch array for inds
    println("sbatch $arraypath")
    #println("First try.")
    
    run(`sbatch $arraypath`, wait = false)
    
    pastgenname = "GA-ind-g$pastgen-$(obj)$(Int(prem))"
    genname = "GA-ind-g$gen"
    samename = "debug-GA-gen-$gen"
    
    # really make sure all past gen's jobs are done
    run(`scancel -n $pastgenname`, wait = false)
    sleep(2)
    run(`scancel -n $pastgenname`, wait = false)
    sleep(5)
    run(`scancel -n $pastgenname`, wait = false)
    
    # now cancel any other repeated jobs
    needcancel = true
    while needcancel
        lines = readchomp(pipeline(`myjobs`, `grep $samename`, `wc -l`))
        if parse(Int, lines) > 1
            jinfo = readchomp(pipeline(`myjobs`, `grep -i pending`, `grep -v $genname`))
            jid = first(split(jinfo))
            run(`scancel $jid`, wait = false)
            sleep(5)
            println("canceled $jid")
        else
            global needcancel = false
        end
    end
    println("ok, wrap up?")
    exit(0)
    # try
    #     depend = readchomp(`sbatch --parsable $arraypath`)
    #     println(depend)
    #     flush(stdout)
    #     # sbatch after for next progeny
    #     jt = string(depend, "+", runmins, "?afterok:$depend")
    #     run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)
    #     println("sbatch --dependency=after:$jt $newgenpath")
    # catch
    #     jname = "GA-ind-g$gen"
    #     sleep(5)
    #     println("Second try. Reading job id from myjobs")
    #     try
    #         arrayid = first(split(readchomp(pipeline(`myjobs`, `grep $jname`))))
    #         depend = first(split(arrayid, "_"))
    #         # sbatch after for next progeny
    #         jt = string(depend, "+", runmins, "?afterok:$depend")
    #         run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)
    #         println("sbatch --dependency=after:$jt $newgenpath")
    #     catch
    #         sleep(15)
    #         arrayid = first(split(readchomp(pipeline(`myjobs`, `grep $jname`))))
    #         depend = first(split(arrayid, "_"))
    #         # sbatch after for next progeny
    #         jt = string(depend, "+", runmins, "?afterok:$depend")
    #         run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)
    #         println("sbatch --dependency=after:$jt $newgenpath")
    #     end
    #     #run(`scancel -n $jname`)
    #     #sleep(2)
    #     #run(`scancel -n $jname`)
    #     #sleep(10)
    #     #run(`scancel -n $jname`)
    #     #println("Second try. Cancelling jobs with name $jname")
    #     #sleep(20)
    #     #rm("/home/mvanega1/SpatialRust/slurmjobid-$gen.txt", force = true)
    #     #println("Second try. Submitting again.")
    #     #depend = readchomp(ignorestatus(`sbatch --parsable $arraypath`))
    #     #println(depend)
    #     #if length(depend) == 0
    #         #println("Third try. Sleeping 45 s so job id is written to file.")
    #         #sleep(45)
    #         #println("Third try. Submitting again.")
    #         #depend = readchomp("/home/mvanega1/SpatialRust/slurmjobid-$gen.txt")
    #         #println(depend)
    #     #end
    #     #flush(stdout)
    #     # sbatch after for next progeny
    #     #jt = string(depend, "+", runmins, "?afterok:$depend")
    #     #run(`sbatch --dependency=after:$jt?afterok:$depend $newgenpath`, wait = false)
    #     #println("sbatch --dependency=after:$jt?afterok:$depend $newgenpath")
    # end
else
    if obj == :all
        expfs = string.(split(read("/scratch/mvanega1/GA4/expfolders.txt", String)))
        for expfolder in expfs
            finalize(expfolder, pastgen0s, popsize)
        end
    elseif obj == :noprems || obj == :prems
        expfs = string.(split(read("/scratch/mvanega1/GA4/expfolders.txt", String)))
        for expfolder in expfs
            finalize(expfolder, pastgen0s, popsize)
        end
    else
        finalize(expfolder, pastgen0s, popsize)
    end
    exit()
end
