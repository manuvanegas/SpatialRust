#!/bin/bash
#SBATCH --ntasks=30
#SBATCH --ntasks-per-core=1

# #SBATCH -p debug
# #SBATCH -q wildfire
# #SBATCH -J debug-shadeexp
# #SBATCH -t 0-00:15:00
#SBATCH -J shadeexp
#SBATCH -t 0-02:00:00

#SBATCH -o logs/shading/o-%A.o
#SBATCH -e logs/shading/o-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.7.2

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ShadingExperiments/RunExperiment.jl 300 23.5 0.65 true
#ARGs: repetitions, mean temp, rain prob
# false -> 35, true -> 51
