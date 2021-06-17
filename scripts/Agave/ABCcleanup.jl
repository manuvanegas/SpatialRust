using DrWatson
@quickactivate "SpatialRust"

using DataFrames, CSV, StatsBase

include(srcdir("ABCproc.jl"))
#include(srcdir("ABCrun.jl"))

load_to_select("/scratch/mvanega1/ABCraw/", 2, 50)

#filter_params("/scratch/mvanega1/ABCveryraw/")
