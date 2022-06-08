using BenchmarkTools, SpatialRust

steps_nlesions(steps, nlesions) = dummyrun_spatialrust(steps, 100, nlesions)
steps_nlesions(500, 25)
suite = BenchmarkGroup()

suite["ABM"] = BenchmarkGroup(["core"])

suite["ABM"]["steps: 1600, nlesions: 1"] = @benchmarkable steps_nlesions(1600, 1)
suite["ABM"]["steps: 1600, nlesions: 5"] = @benchmarkable steps_nlesions(1600, 5)
suite["ABM"]["steps: 1600, nlesions: 25"] = @benchmarkable steps_nlesions(1600, 25)


loadparams!(suite, BenchmarkTools.load("bench/params.json")[1], :evals, :samples);
# For future ref, params.json was generated by:
# tune!(suite)
# BenchmarkTools.save("bench/params.json", params(suite))

results = run(suite, verbose = true)

BenchmarkTools.save("bench/output.json", median(results))