#!/bin/bash
#SBATCH --array=2
#SBATCH --ntasks=2
#SBATCH --ntasks-per-core=1
# #SBATCH --nodelist=c016
#SBATCH --mem=2G
#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J debug-ABC
#SBATCH -o logs/ABC/sims/do-%A-%a.o
#SBATCH -e logs/ABC/sims/do-%A.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.8.2

# echo $SLURM_JOB_NODELIST > /tmp/nodelist

export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`
# julia --machine-file $SLURM_NODEFILE -e "using Distributed; println(nprocs()); println(workers())"
# julia --project=. -e "using SpatialRust"
# echo "pkg should be loaded"
# julia --project=. --machine-file $SLURM_NODEFILE -e "using Pkg;println(Pkg.status())"

echo `date +%F-%T`
echo $SLURM_JOB_ID
echo $SLURM_JOB_NODELIST
ulimit -s 262144
# ARGS: params file, slurm job array id, # cores, # sims per core
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ABC/sims/runABC.jl 16 $SLURM_ARRAY_TASK_ID $SLURM_NTASKS 100 #500
# julia ~/SpatialRust/scripts/ABC/sims/runABC.jl 9 $SLURM_ARRAY_TASK_ID $SLURM_NTASKS 400

# julia --machine-file $SLURM_NODEFILE --sysimage src/PkgCompile/ABCSysimage.so -e 'u_t = @elapsed begin; @everywhere begin; using Pkg; Pkg.activate("."); end; @everywhere using SpatialRust; end; println(u_t)'

# nodes = ENV["SLURM_JOB_NODELIST"]
# nnums=length(filter(isdigit,nodes))
# ngroups = div(nnums, 6)
# if ngroups == 1
# println(parse(Int,nodes[3:5]))
# end


# ntasks = parse(Int, ENV["SLURM_NTASKS"])
# thefile = open("/tmp/tasks";create=true,write=true)
# for i in 1:ntasks
# write(thefile, string(i,"\n"))
# end
# close(thefile)
