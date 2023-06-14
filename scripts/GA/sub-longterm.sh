#!/bin/bash
#SBATCH --array=1-2
#SBATCH --ntasks-per-core=1
#SBATCH --mem=1G
#SBATCH --ntasks=1
#SBATCH -p htc
#SBATCH -J fittest
#SBATCH -t 0-00:45:00
#SBATCH --chdir=/home/mvanega1/SpatialRust
#SBATCH -o logs/GA/fittest/i-%A.o
#SBATCH -e logs/GA/fittest/i-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.9.0

echo `date +%F-%T`

julia ~/SpatialRust/scripts/GA/runFittest.jl /home/mvanega1/SpatialRust/results/GA4/fittest/parsdf.csv $SLURM_ARRAY_TASK_ID 5

exit 0