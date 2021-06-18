@everywhere using DrWatson
@everywhere @quickactivate "SpatialRust"

@everywhere using CSV, DataFrames, Distributed, StatsBase
@everywhere include(srcdir("ABCproc.jl"))
    #include(srcdir("ABCrun.jl"))


load_to_select("/scratch/mvanega1/ABCveryraw/", ARGS[1], parse(Int, ARGS[2]), parse(Int, ARGS[3]))

#filter_params("/scratch/mvanega1/ABCveryraw/")

#find_fauly_files()

