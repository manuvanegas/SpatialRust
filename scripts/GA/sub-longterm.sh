#!/bin/bash
#SBATCH --array=1-8
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks=1
#SBATCH -p htc
# #SBATCH -q debug
#SBATCH -J fittest
#SBATCH -t 0-01:00:00
#SBATCH --chdir=/home/mvanega1/SpatialRust
# #SBATCH -o logs/GA/fittest/i-%A.o
# #SBATCH -e logs/GA/fittest/i-%A.e
#SBATCH -o logs/GA/fittest/i-%A-%a.o
#SBATCH -e logs/GA/fittest/i-%A-%a.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.9.0

echo `date +%F-%T`

ulimit -s 262144

julia ~/SpatialRust/scripts/GA/runFittest.jl /home/mvanega1/SpatialRust/results/GA4/fittest/parsdfNF.csv $SLURM_ARRAY_TASK_ID 100

echo `date +%F-%T`

exit 0