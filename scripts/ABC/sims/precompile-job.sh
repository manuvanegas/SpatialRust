#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --ntasks-per-core=1
#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J debug-ABC
#SBATCH -o logs/ABC/prec-%A.o
#SBATCH -e logs/ABC/prec-%A.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.8.2

julia << EOF
using Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.precompile()
using SpatialRust
dummyrun_spatialrust()
EOF
