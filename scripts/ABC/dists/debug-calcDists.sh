#!/bin/bash
#SBATCH --ntasks=2
#SBATCH --ntasks-per-core=1
#SBATCH --mem=1G
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

echo `date +%F-%T`
echo $SLURM_JOB_ID
echo $SLURM_JOB_NODELIST
export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ABC/dists/calcDistsnoVar.jl 16
