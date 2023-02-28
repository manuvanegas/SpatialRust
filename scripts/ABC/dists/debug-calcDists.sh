#!/bin/bash
#SBATCH --ntasks=4
#SBATCH --ntasks-per-core=1
#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J ABCdist
#SBATCH -o logs/ABC/dists/o.%x-%A.o
#SBATCH -e logs/ABC/dists/o.%x-%A.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.8.2

export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
julia --machine-file $SLURM_NODEFILE --sysimage src/PkgCompile/ABCSysimage.so ~/SpatialRust/scripts/ABC/dists/calcDists.jl 0.6 0.0 quants4 quals4
