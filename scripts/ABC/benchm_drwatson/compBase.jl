the_time = @elapsed begin
    @everywhere begin
        using Pkg
        Pkg.activate("/home/mvanega1/SpatialRust/.")
    end
    @everywhere begin
        using DataFrames
        using Distributed: pmap
        using CSV: read as crd, write as cwr
        using Arrow: write as awr
        include("/home/mvanega1/SpatialRust/SpatialRust.jl")
    end
    @everywhere begin
        using .SpatialRust
    end
end

println(string("Base: ",the_time))
