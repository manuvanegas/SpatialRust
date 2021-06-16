#!/bin/bash 
#SBATCH --ntasks=40                                                            
#SBATCH --ntasks-per-core=1
#SBATCH -J test_spatialR
#SBATCH -o %j.o
#SBATCH -e %j.e
#SBATCH -t 0-00:10:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.5.0

export SLURM_NODEFILE=`generate_pbs_nodefile`
julia --machine-file $SLURM_NODEFILE ~/SpatialRust/scripts/ParamScan.jl

cp /scratch/mvanega1/track/* ~/SpatialRust/results/track/
rm /scratch/mvanega1/track/*
