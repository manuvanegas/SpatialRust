#!/bin/bash
#SBATCH --ntasks=102
#SBATCH --ntasks-per-core=1
#SBATCH -p htc
#SBATCH --nodelist=cg40
#SBATCH -J htc_sampling
#SBATCH -o %x-%j.o
#SBATCH -e %x-%j.e
#SBATCH -t 0-04:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.5.0

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/Agave/ABCcleanup.jl ABCsampled 1 1 0

# export SLURM_NODEFILE=`generate_pbs_nodefile`
# julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/Agave/ABCcleanup.jl ABCsampled 1 $SLURM_ARRAY_TASK_STEP $SLURM_ARRAY_TASK_ID

#julia ~/SpatialRust/scripts/Agave/ABCcleanup.jl
