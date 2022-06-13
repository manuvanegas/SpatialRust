using BenchmarkTools, SpatialRust
using Random: seed!

steps_nlesions(steps, nlesions) = dummyrun_fullsun_spatialrust(steps, 100, nlesions)
steps_nlesions(500, 25)

suite = BenchmarkGroup()
suite["ABM"] = BenchmarkGroup(["core"])
suite["ABM"]["steps: 1000, nlesions: 1"] = @benchmarkable steps_nlesions(1000, 1) seconds = 90
suite["ABM"]["steps: 1000, nlesions: 5"] = @benchmarkable steps_nlesions(1000, 5) seconds = 90
suite["ABM"]["steps: 1000, nlesions: 25"] = @benchmarkable steps_nlesions(1000, 25) seconds = 90

loadparams!(suite, BenchmarkTools.load("bench/params.json")[1], :evals, :samples);
# For future ref, params.json was generated by:
# seed!(1234)
# tune!(suite)
# BenchmarkTools.save("bench/params.json", params(suite))

seed!(1234)
results = run(suite, verbose = true)

## Get time in seconds, not ns
function in_seconds(group::BenchmarkGroup)
    for k in keys(group)
        for subk in keys(group[k])
            group[k][subk].time /= 10^9
            group[k][subk].gctime /= 10^9
        end
    end
    return group
end
##

estimates = in_seconds(median(results))
BenchmarkTools.save("bench/output.json", estimates)
