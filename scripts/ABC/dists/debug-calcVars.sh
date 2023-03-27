#!/bin/bash
#SBATCH --ntasks=4
#SBATCH --ntasks-per-core=1
#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J ABCvar
#SBATCH -o logs/ABC/vars/do-%A.o
#SBATCH -e logs/ABC/vars/do-%A.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.8.2

export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
cp $SLURM_NODEFILE logs/ABC/nodefiles/varnodes_${SLURM_JOB_ID}
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABC/dists/calcVars.jl quants_8 quals_8 0
