#!/bin/bash
#SBATCH --array=1-50 #80
#SBATCH --mem=3G
#SBATCH --ntasks=5
#SBATCH --ntasks-per-core=1
#SBATCH -p htc
#SBATCH -q public
#SBATCH -J ABC
#SBATCH -o logs/ABC/sims/o-%A-%a.o
#SBATCH -e logs/ABC/sims/o-%A.e
#SBATCH -t 0-04:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.8.2
ulimit -s 262144

# checklist
# [] Pkg.precompiled 
# [] Sysimage is current
# [] output dirnames updated at runABC.jl
# [] correct # arrays/runs per job
# [] every file has been saved!

echo `date +%F-%T`
echo $SLURM_JOB_ID
echo $SLURM_JOB_NODELIST
export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
cp $SLURM_NODEFILE logs/ABC/nodefiles/nodes_${SLURM_ARRAY_TASK_ID}
# ARGS: params file #, slurm job array id, # cores, # sims per core
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABC/sims/runABC.jl \
16 $SLURM_ARRAY_TASK_ID $SLURM_NTASKS 4000 #2500 # 250 #500
