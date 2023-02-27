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
using PackageCompiler
PackageCompiler.create_sysimage(["DataFrames", "Arrow", "SpatialRust"];
	sysimage_path="src/PkgCompile/ABCSysimagePosteriors.so")
EOF

julia << EOF
using Pkg
Pkg.activate(".")
using PackageCompiler
PackageCompiler.create_sysimage(["DataFrames", "Arrow", "SpatialRust"];
	sysimage_path="src/PkgCompile/ABCPrecompiledSysimagePosteriors.so",
	precompile_execution_file="src/PkgCompile/ABCprecompile.jl",
	base_sysimage="src/PkgCompile/ABCSysimagePosteriors.so")
EOF