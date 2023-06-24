module SpatialRust

#using PrecompileTools
#@recompile_invalidations begin
using Agents, DataFrames, Distributions, Random
using StatsBase: sample, weights
#end

# include("ABC/ABCMainSetup.jl")

# const SpatialRustABM = Agents.SingleContainerABM{
#     Agents.GridSpaceSingle{2, false}, Coffee, Vector{Coffee},
#     typeof(Agents.Schedulers.fastest), SpatialRust.Props, Random.Xoshiro
# }

# include("ABM/CreateABM.jl")
# include("ABM/FarmMap.jl")
# include("ABM/ShadeMap.jl")

# include("ABC/ABCMainStep.jl")
# include("ABM/ShadeSteps.jl")
# include("ABM/CoffeeSteps.jl")
# include("ABC/ABCRustGrowth.jl")
# include("ABM/RustDispersal.jl")
# include("ABM/CGrowerSteps.jl")

# include("QuickRuns.jl")
# include("QuickMetrics.jl")

# include("ABC/Sims.jl")



include("ABM/MainSetup.jl")

const SpatialRustABM = Agents.SingleContainerABM{
    Agents.GridSpaceSingle{2, false}, Coffee, Vector{Coffee},
    typeof(Agents.Schedulers.fastest), SpatialRust.Props, Random.Xoshiro
}

include("ABM/CreateABM.jl")
include("ABM/FarmMap.jl")
include("ABM/ShadeMap.jl")

include("ABM/MainStep.jl")
include("ABM/ShadeSteps.jl")
include("ABM/CoffeeSteps.jl")
include("ABM/RustGrowth.jl")
include("ABM/RustDispersal.jl")
include("ABM/CGrowerSteps.jl")

include("QuickRuns.jl")
include("QuickMetrics.jl")

export SpatialRustABM

#@setup_workload begin
#    pars = (row_d = 1,
#        plant_d = 1,
#        shade_d = 9,
#        barriers = (0,0),
#        barrier_rows = 1,
#        prune_sch = [1, 100, 300],
#        post_prune = [0.1, 0.3, 0.4],
#        inspect_period = 32,
#        inspect_effort = 0.1,
#        fungicide_sch =  [1, 100, 300],
#       incidence_as_thr = false,
#       incidence_thresh = 0.1,
#       steps = 1460,
#        coffee_price = 1.0)
#    @compile_workload begin
#        model = init_spatialrust(; pars...)
#        step_model!(model)
#    end
#end

end
