#!/bin/bash 
#SBATCH --ntasks=25                                                            
#SBATCH --ntasks-per-core=1
#SBATCH --nodes=2-10
#SBATCH --mem-per-cpu=5000
#SBATCH -J scale_ext
#SBATCH -o %x-%j.o
#SBATCH -e %x-%j.e
#SBATCH -t 0-03:59:59
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.5.0

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/Agave/ScaleExtensionAg.jl

