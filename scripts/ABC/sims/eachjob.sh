#!/bin/bash
#SBATCH --array=1-2 # 125
#SBATCH --ntasks=21
#SBATCH --ntasks-per-core=1
#SBATCH -J init-ABC
#SBATCH -o logs/outs.%x-%A.o
#SBATCH -e logs/outs.%x-%A.e
#SBATCH -t 0-00:12:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABCsims/runABC.jl parameters.csv $SLURM_ARRAY_TASK_ID $SLURM_NTASKS 100 #400
# ARGS: params file, slurm job array id, # cores, # sims per core
