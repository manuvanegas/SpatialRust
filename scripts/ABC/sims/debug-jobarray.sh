#!/bin/bash
#SBATCH --array=1-2
#SBATCH --ntasks=20
#SBATCH --ntasks-per-core=1
#SBATCH -p debug
#SBATCH -q wildfire
#SBATCH -J debug-ABC
#SBATCH -o logs/debugABC/o-%A-%a.o
#SBATCH -e logs/debugABC/o-%A.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABC/sims/runABC.jl parameters_1000000 $SLURM_ARRAY_TASK_ID $SLURM_NTASKS 10 #500
