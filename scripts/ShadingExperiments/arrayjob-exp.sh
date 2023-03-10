#!/bin/bash
#SBATCH --array=1-4
#SBATCH --ntasks-per-core=1

#SBATCH --ntasks=5
#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J debug-shadeexp
#SBATCH -t 0-00:15:00
# #SBATCH --ntasks=5
# #SBATCH -J shadeexp
# #SBATCH -t 0-00:55:00

#SBATCH -o logs/shading/o-%A-%a.o
#SBATCH -e logs/shading/o-%A-%a.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.8.2

export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
echo `date +%F-%T`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ShadingExperiments/runExperiment.jl 10 23.0 0.8 $SLURM_ARRAY_TASK_ID
# ~/SpatialRust/scripts/ShadingExperiments/runExperiment.jl 200 22.5 0.55 $SLURM_ARRAY_TASK_ID
#ARGs: repetitions, mean temp, rain prob, array ID -> shade_placements
# 1 -> 29, 2 or 3 -> 42 # need to update #s
