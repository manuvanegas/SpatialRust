#!/bin/bash
#SBATCH --array=1-100
#SBATCH --ntasks=5
#SBATCH --ntasks-per-core=1
#SBATCH -p htc
#SBATCH -q public
#SBATCH -J reABC
#SBATCH -o logs/ABC/ro-%A-%a.o
#SBATCH -e logs/ABC/ro-%A.e
#SBATCH -t 0-02:30:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


module purge
module load julia/1.8.2

export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
cp $SLURM_NODEFILE logs/ABC/nodefiles/nodes_${SLURM_ARRAY_TASK_ID}
julia --machine-file $SLURM_NODEFILE --sysimage src/PkgCompile/ABCPrecompiledSysimage.so ~/SpatialRust/scripts/ABC/sims/re-runABC.jl parameters_1000000 $SLURM_ARRAY_TASK_ID $SLURM_NTASKS 2000 # 250 #500
# ARGS: params file, slurm job array id, # cores, # sims per core
