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

module purge
module load julia/1.8.2

echo `date +%F-%T`
julia ~/SpatialRust/scripts/GA/beginGA.jl 6 4 200 365 0.3 0.1 1.0 shorttprofit
# popsize, gens, reps, steps, pcross, pmut, cofprice, obj function name
