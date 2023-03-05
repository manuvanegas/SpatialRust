#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --ntasks-per-core=1
#SBATCH --mem=25G
#SBATCH -p htc
#SBATCH -q public
#SBATCH -J PkgCompiler
#SBATCH -o logs/ABC/pkgcomp/o.%x-%A.o
#SBATCH -e logs/ABC/pkgcomp/o.%x-%A.e
#SBATCH -t 0-00:35:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=mvanega1@asu.edu

module purge
module load julia/1.8.2

ulimit -s 262144

julia << EOF
using Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.precompile()
using Arrow, DataFrames, SpatialRust
using PackageCompiler
PackageCompiler.create_sysimage(["DataFrames", "Arrow", "SpatialRust"];
	sysimage_path="src/PkgCompile/ABCSysimage2.so")
EOF

julia --sysimage "src/PkgCompile/ABCSysimage2.so" --project=. -e 'using SpatialRust; dummyrun_spatialrust(); println("Ok")'

julia << EOF
using Pkg
Pkg.activate(".")
using PackageCompiler
PackageCompiler.create_sysimage(["DataFrames", "Arrow", "SpatialRust"];
	sysimage_path="src/PkgCompile/ABCPrecompiledSysimage2.so",
	precompile_execution_file="src/PkgCompile/ABCprecompile.jl",
	base_sysimage="src/PkgCompile/ABCSysimage2.so")
EOF

julia --sysimage "src/PkgCompile/ABCPrecompiledSysimage2.so" --project=. -e 'using SpatialRust; dummyrun_spatialrust(); println("Ok2")'