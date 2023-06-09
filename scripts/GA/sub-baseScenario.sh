#!/bin/bash
#SBATCH --ntasks-per-core=1
#SBATCH --mem=1G
#SBATCH --ntasks=1
#SBATCH -p htc
#SBATCH -q debug
#SBATCH -J debug-basescen
#SBATCH -t 0-00:15:00
#SBATCH -o logs/GA/b-%A.o
#SBATCH -e logs/GA/b-%A.e
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.9.0

echo `date +%F-%T`
julia ~/SpatialRust/scripts/GA/runBaseScenario.jl