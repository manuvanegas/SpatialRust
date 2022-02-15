#!/bin/bash
#SBATCH --array=1-2
#SBATCH --ntasks=5
#SBATCH --ntasks-per-core=1
#SBATCH -p debug
#SBATCH -q wildfire
#SBATCH -J debug-ABC
#SBATCH -o outs.%x-%A.o
#SBATCH -e outs.%x-%A.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABCsims/compBase.jl parameters.csv $SLURM_ARRAY_TASK_ID $SLURM_NTASKS
