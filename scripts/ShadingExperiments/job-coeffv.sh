#!/bin/bash
#SBATCH --ntasks=5
#SBATCH --ntasks-per-core=1

#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J debug-CVs
#SBATCH -t 0-00:15:00
#SBATCH -o logs/shading/o-%A.o
#SBATCH -e logs/shading/o-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.8.2

export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ShadingExperiments/CoeffVariance.jl 100 23.0 0.8
# 1003