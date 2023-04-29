module SpatialRust

using Agents, DataFrames, Distributions, Random
using DrWatson: srcdir, datadir
using StatsBase: sample, weights

# include(srcdir("ABC/ABCMainSetup.jl"))

# const SpatialRustABM = Agents.SingleContainerABM{
#     Agents.GridSpaceSingle{2, false}, Coffee, Vector{Coffee},
#     typeof(Agents.Schedulers.fastest), SpatialRust.Props, Random.Xoshiro
# }

# include(srcdir("ABM/CreateABM.jl"))
# include(srcdir("ABM/FarmMap.jl"))
# include(srcdir("ABM/ShadeMap.jl"))

# include(srcdir("ABC/ABCMainStep.jl"))
# include(srcdir("ABM/ShadeSteps.jl"))
# include(srcdir("ABM/CoffeeSteps.jl"))
# include(srcdir("ABC/ABCRustGrowth.jl"))
# include(srcdir("ABM/RustDispersal.jl"))
# include(srcdir("ABM/CGrowerSteps.jl"))

# include(srcdir("QuickRuns.jl"))
# include(srcdir("QuickMetrics.jl"))

# include(srcdir("ABC", "Sims.jl"))



include(srcdir("ABM/MainSetup.jl"))

const SpatialRustABM = Agents.SingleContainerABM{
    Agents.GridSpaceSingle{2, false}, Coffee, Vector{Coffee},
    typeof(Agents.Schedulers.fastest), SpatialRust.Props, Random.Xoshiro
}

include(srcdir("ABM/CreateABM.jl"))
include(srcdir("ABM/FarmMap.jl"))
include(srcdir("ABM/ShadeMap.jl"))

include(srcdir("ABM/MainStep.jl"))
include(srcdir("ABM/ShadeSteps.jl"))
include(srcdir("ABM/CoffeeSteps.jl"))
include(srcdir("ABM/RustGrowth.jl"))
include(srcdir("ABM/RustDispersal.jl"))
include(srcdir("ABM/CGrowerSteps.jl"))

include(srcdir("QuickRuns.jl"))
include(srcdir("QuickMetrics.jl"))

export SpatialRustABM

end
