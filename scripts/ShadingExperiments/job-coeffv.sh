#!/bin/bash
#SBATCH --ntasks=5
#SBATCH --ntasks-per-core=1
#SBATCH --mem=4G

#SBATCH -p htc
#SBATCH -q public
#SBATCH -J CVs
#SBATCH -t 0-01:00:00
#SBATCH -o logs/shading/o-%A.o
#SBATCH -e logs/shading/o-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.8.2

echo `date +%F-%T`
echo $SLURM_JOB_ID
echo $SLURM_JOB_NODELIST
export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
julia --machine-file $SLURM_NODEFILE \
~/SpatialRust/scripts/ShadingExperiments/calcRepCVs.jl 600 22.0 0.8 0.7 4