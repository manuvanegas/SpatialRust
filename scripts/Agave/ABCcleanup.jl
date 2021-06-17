@everywhere begin
    using DrWatson
    @quickactivate "SpatialRust"

    using CSV, DataFrames, Distributed, StatsBase
    include(srcdir("ABCproc.jl"))
    #include(srcdir("ABCrun.jl"))
end


load_to_select("/scratch/mvanega1/ABCraw/", 2, 50)

#filter_params("/scratch/mvanega1/ABCveryraw/")
