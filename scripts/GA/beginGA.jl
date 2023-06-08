using DelimitedFiles, Random

popsize = parse(Int, ARGS[1])
maxgens = parse(Int, ARGS[2])
reps = parse(Int, ARGS[3])
steps = parse(Int, ARGS[4])
pcross = parse(Float64, ARGS[5])
pmut = parse(Float64, ARGS[6])
coffee_price = parse(Float64, ARGS[7])
obj = ARGS[8]

include("../../src/GA/Generation.jl")
include("../../src/GA/SlurmScripts.jl")

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
arraypath, runmins = write_array_script(popsize, 1, reps, steps, coffee_price, expfolder)
newgenpath = write_ngen_script(popsize, 1, maxgens, reps, steps, coffee_price, pcross, pmut, expfolder)
# sbatch array for inds
depend = readchomp(`sbatch --parsable $arraypath`)
# sbatch after for next progeny
jt = string(depend, "+", runmins, "?afterok:$depend")
run(`sbatch --dependency=after:$jt $newgenpath`, wait = false)