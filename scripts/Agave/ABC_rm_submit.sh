#!/bin/bash 
#SBATCH --ntasks=1                                                      
#SBATCH --ntasks-per-core=1
#SBATCH -p debug
#SBATCH -q wildfire
#SBATCH -J rmfiles9
#SBATCH -o %x-%j.o
#SBATCH -e %x-%j.e
#SBATCH -t 0-00:15:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu


rm /scratch/mvanega1/ABCveryraw/out_9*