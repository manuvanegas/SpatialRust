#!/bin/bash 
#SBATCH --ntasks=1                                                      
#SBATCH --ntasks-per-core=1
#SBATCH -p debug
#SBATCH -q wildfire
#SBATCH -J cleanup
#SBATCH -o %x-%j.o
#SBATCH -e %x-%j.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.5.0

julia ~/SpatialRust/scripts/Agave/ABCcleanup.jl

#mv ~/SpatialRust/results/ABCrawfiles/out_102* /scratch/mvanega1/ABCraw/
