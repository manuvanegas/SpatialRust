# @everywhere using DrWatson
# @everywhere @quickactivate "SpatialRust"
#
# @everywhere using CSV, DataFrames, Distributed, StatsBase
# @everywhere include(srcdir("ABCproc.jl"))
#     #include(srcdir("ABCrun.jl"))
#
#
# load_to_select("/scratch/mvanega1/ABCveryraw/", ARGS[1], parse(Int, ARGS[2]), parse(Int, ARGS[3]))
#
# #filter_params("/scratch/mvanega1/ABCveryraw/")

using DrWatson
@quickactivate "SpatialRust"

using CSV, DataFrames

startedat = time()
outfolder = mkpath(projectdir("results","faulty"))
files = readdir("/scratch/mvanega1/ABCveryraw/", join = true, sort = false)
for f in files
    missing_vals = ismissing.(CSV.read(f, DataFrame))
    println(basename(f))
    now = time() - startedat
    println(now)
    sums = sum(eachcol(missing_vals))
    if any(sums .> 0)
        CSV.write(string(outfolder, basename(f)), DataFrame(v = sums))
    end
end
