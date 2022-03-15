#!/bin/bash
#SBATCH --ntasks=10
#SBATCH -p debug
#SBATCH -q wildfire
#SBATCH -J debug-ABCv
#SBATCH -o logs/outs.%x-%A.o
#SBATCH -e logs/outs.%x-%A.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABC/dists/calcVars.jl
