#!/bin/bash
#SBATCH --ntasks=5
#SBATCH --ntasks-per-core=1
# #SBATCH --mem=5G

#SBATCH -p htc
#SBATCH -q debug
#SBATCH -t 15:00
#SBATCH -J debugGA
# #SBATCH -q public
# #SBATCH -J GA
# #SBATCH -t 0-04:00:00
#SBATCH -o logs/ga/%x-%A.o
#SBATCH -e logs/ga/%x-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.8.2

echo `date +%F-%T`
export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/GA/runGA.jl 5 10 3 0.7 0.1 365 1.0 shortprofit
# popsize, gens, reps, p cross, p mut, steps, coffeeprice, obj