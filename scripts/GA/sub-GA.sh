#!/bin/bash
#SBATCH --ntasks-per-core=1
#SBATCH --mem=1G
#SBATCH --ntasks=1
#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J debug-GA-gen-1
#SBATCH -t 0-00:15:00
# #SBATCH -J GA-gen-1
# #SBATCH -t 0-01:00:00
#SBATCH -o logs/GA/gen/g-%A.o
#SBATCH -e logs/GA/gen/g-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu
    #SBATCH --exclude=c[001-85],c[090-095],c[105-112],cg[001-005],ch001

module purge
module load julia/1.9.0

echo `date +%F-%T`
#julia ~/SpatialRust/scripts/GA/beginGA.jl 4 2 75 730 0.5 0.02 0.65 deb profit true 87
julia ~/SpatialRust/scripts/GA/beginGA.jl 100 48 75 730 0.5 0.02 0.65 2 prems true 87
# popsize, gens, reps, steps, pcross, pmut, cofprice, folder name/suffix, obj function (profit/sev/(no)prems/all), premiums?, chr length
#pet: 40 20 50
