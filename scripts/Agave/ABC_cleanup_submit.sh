#!/bin/bash 
#SBATCH --ntasks=1                                                      
#SBATCH --ntasks-per-core=1
<<<<<<< HEAD
#SBATCH -p debug
#SBATCH -q wildfire
#SBATCH -J cleanup
#SBATCH -o %x-%j.o
#SBATCH -e %x-%j.e
#SBATCH -t 0-00:15:00
=======
#SBATCH -o %x-%j.o
#SBATCH -e %x-%j.e
#SBATCH -t 0-4:00:00
>>>>>>> b6f31279a19913a97cc261731e1bfd78819494c3
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.5.0

julia ~/SpatialRust/scripts/Agave/ABCcleanup.jl

<<<<<<< HEAD
#mv ~/SpatialRust/results/ABCrawfiles/out_102* /scratch/mvanega1/ABCraw/
=======
>>>>>>> b6f31279a19913a97cc261731e1bfd78819494c3
