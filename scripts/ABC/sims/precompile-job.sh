#!/bin/bash
#SBATCH --ntasks=5
#SBATCH --ntasks-per-core=1
# #SBATCH --mem=25G
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

# ulimit -s 262144

# julia << EOF
# using Pkg
# Pkg.activate(".")
# Pkg.instantiate()
# Pkg.precompile()
# using Arrow, DataFrames, SpatialRust
# using PackageCompiler
# PackageCompiler.create_sysimage(["DataFrames", "Arrow", "SpatialRust"];
# 	sysimage_path="src/PkgCompile/ABCSysimage2.so")
# EOF

# julia --sysimage "src/PkgCompile/ABCSysimage2.so" --project=. -e 'using SpatialRust; dummyrun_spatialrust(); println("Ok")'

# julia << EOF
# using Pkg
# Pkg.activate(".")
# using PackageCompiler
# PackageCompiler.create_sysimage(["DataFrames", "Arrow", "SpatialRust"];
# 	sysimage_path="src/PkgCompile/ABCPrecompiledSysimage2.so",
# 	precompile_execution_file="src/PkgCompile/ABCprecompile.jl",
# 	base_sysimage="src/PkgCompile/ABCSysimage2.so")
# EOF

# julia --sysimage "src/PkgCompile/ABCPrecompiledSysimage2.so" --project=. -e 'using SpatialRust; dummyrun_spatialrust(); println("Ok2")'

export SLURM_NODEFILE=`scripts/generate_pbs_nodefile.pl`

# julia --machine-file $SLURM_NODEFILE -e '@everywhere begin;
julia -e '
	using Pkg;
	Pkg.activate(".");
# end;
comptime = @elapsed using SpatialRust;
println("Time to compile: $comptime")'


julia --machine-file $SLURM_NODEFILE -e '@everywhere begin;
	using Pkg;
	Pkg.activate(".");
end;
usingtime = @elapsed @everywhere using SpatialRust;
println("Time to load again: $usingtime");
flush(stdout);
using Arrow, DataFrames;
using Tables: namedtupleiterator;
run_time = @elapsed begin;
    parameters = DataFrame(Arrow.Table(string("data/ABC/parameters_8.arrow")))[1:20,:];
    wp = CachingPool(workers());
    outputs = abc_pmap(Tables.namedtupleiterator(parameters), wp);
end;
println("Time to run: $run_time")
'

# using Arrow, DataFrames;
# using Tables: namedtupleiterator;
# run_time = @elapsed begin;
#     parameters = DataFrame(Arrow.Table(string("data/ABC/parameters_8.arrow")))[1:10,:];
#     wp = CachingPool(workers());
#     outputs = abc_pmap(Tables.namedtupleiterator(parameters), wp);
# end;


# atup = (p_row = 1, res_commit = 0.2, µ_prod = 0.05, rust_gr = 0.2);
# run_time = @elapsed outputs = sim_abc(atup);

# julia -e '
# using Pkg;
# Pkg.activate(".");
# usingtime = @elapsed using SpatialRust;
# println("Time to load again: $usingtime");
# flush(stdout);
# atup = (p_row = 1, res_commit = 0.2, µ_prod = 0.05, rust_gr = 0.2);
# run_time = @elapsed outputs = sim_abc(atup);
# println("Time to run: $run_time")
# '