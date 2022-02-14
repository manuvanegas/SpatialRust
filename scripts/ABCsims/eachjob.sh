#!/bin/bash
#SBATCH --ntasks=201
#SBATCH --ntasks-per-core=1
#SBATCH -J ABC-%A-%a
#SBATCH -o %x.o
#SBATCH -e %x.e
#SBATCH -t 0-04:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABCsims/runABC.jl parameters.csv $SLURM_ARRAY_TASK_ID $SLURM_NTASKS
