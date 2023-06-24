#!/bin/bash
#SBATCH --ntasks=5
#SBATCH --ntasks-per-core=1
#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J ABCposts
#SBATCH -o logs/ABC/posts/o.%x-%A.o
#SBATCH -e logs/ABC/posts/o.%x-%A.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.8.2

echo `date +%F-%T`
export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ABC/posteriors/runPosteriorChecks.jl
