#!/bin/bash
#SBATCH --array=1-250
#SBATCH --ntasks=16
#SBATCH --ntasks-per-core=1
#SBATCH -J ABC
#SBATCH -o logs/ABC/o-%A-%a.o
#SBATCH -e logs/ABC/o-%A.e
#SBATCH -t 0-04:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABC/sims/runABCclean.jl parameters_1000000 $SLURM_ARRAY_TASK_ID $SLURM_NTASKS 250 #500
# ARGS: params file, slurm job array id, # cores, # sims per core
