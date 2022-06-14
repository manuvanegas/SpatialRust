#!/bin/bash
#SBATCH --array=1-3
#SBATCH --ntasks-per-core=1

##SBATCH --ntasks=10
##SBATCH -p debug
##SBATCH -q wildfire
##SBATCH -J debug-shadeexp
##SBATCH -t 0-00:15:00
#SBATCH --ntasks=35
#SBATCH -J shadeexp
#SBATCH -t 0-00:55:00

#SBATCH -o logs/shading/o-%x-%A-%a.o
#SBATCH -e logs/shading/o-%x-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
echo `date +%F-%T`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ShadingExperiments/RunExperiment.jl 200 22.5 0.55 $SLURM_ARRAY_TASK_ID
#ARGs: repetitions, mean temp, rain prob, array ID -> fragments
# 1 -> 29, 2 or 3 -> 42
