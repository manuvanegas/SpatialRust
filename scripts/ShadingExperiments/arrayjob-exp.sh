#!/bin/bash
#SBATCH --array=1-4
#SBATCH --ntasks-per-core=1
#SBATCH --mem=4G
#SBATCH --ntasks=5
#SBATCH -p htc
# #SBATCH -q debug
# #SBATCH -J debug-shadeexp
# #SBATCH -t 0-00:15:00
#SBATCH -J shadeexp
#SBATCH -t 0-04:00:00

#SBATCH -o logs/shading/exp-%A-%a.o
#SBATCH -e logs/shading/exp-%A-%a.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.8.2

export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
echo `date +%F-%T`
echo $SLURM_JOB_ID
echo $SLURM_JOB_NODELIST
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ShadingExperiments/runExperiment.jl 50 22.0 0.8 0.7 $SLURM_ARRAY_TASK_ID 5
#ARGs: repetitions, mean temp, rain prob, wind prob, array ID -> shade_placements, sim years
