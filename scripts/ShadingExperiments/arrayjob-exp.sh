#!/bin/bash
#SBATCH --array=1-3
#SBATCH --ntasks=30
#SBATCH --ntasks-per-core=1

# #SBATCH -p debug
# #SBATCH -q wildfire
# #SBATCH -J debug-shadeexp
# #SBATCH -t 0-00:15:00
#SBATCH -J shadeexp
#SBATCH -t 0-02:00:00

#SBATCH -o logs/shading/o-%A-%a.o
#SBATCH -e logs/shading/o-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ShadingExperiments/RunExperiment.jl 300 23.5 0.65 $SLURM_ARRAY_TASK_ID
#ARGs: repetitions, mean temp, rain prob, array ID -> fragments
# 1 -> 29, 2 or 3 -> 42