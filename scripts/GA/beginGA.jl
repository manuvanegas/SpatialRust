using DelimitedFiles, Random

popsize = parse(Int, ARGS[1])
maxgens = parse(Int, ARGS[2])
reps = parse(Int, ARGS[3])
steps = parse(Int, ARGS[4])
pcross = parse(Float64, ARGS[5])
pmut = parse(Float64, ARGS[6])
coffee_price = parse(Float64, ARGS[7])
obj = ARGS[8]

# experiment id: obj function - pcross - pmut
expfolder = string("/scratch/mvanega1/GA/", obj, "-", pcross, "-", pmut)
# mkpaths: pops, transcs, fitns, histftns, scripts
poppath = mkpath(joinpath(expfolder, "pops"))
mkpath(joinpath(expfolder, "transcs"))
mkpath(joinpath(expfolder, "fitns"))
mkpath(joinpath(expfolder, "histftns"))
mkpath(joinpath(expfolder, "scripts"))

# save init pop
writedlm(joinpath(poppath, "g-001.csv", bitrand(67, popsize), ','))

# create first .sh with new ARGS
arraypath = write_array_script(popsize, 1, reps, steps, coffee_price, expfolder)
newgenpath = write_ngen_script(popsize, 1, maxgens, reps, steps, coffee_price, pcross, pmut, expfolder)
# sbatch array for inds
run(`sbatch $arraypath`, wait = false)
# sbatch afterok for next progeny
run(`sbatch $newgenpath`, wait = false)