using BenchmarkTools, SpatialRust

suite =

if isfile("bench/params.json")
    oadparams!(suite, BenchmarkTools.load("bench/params.json")[1], :evals, :samples);
else
    tune!(suite)
    BenchmarkTools.save("bench/params.json", params(suite))
end

results = run(suite, verbose = true)

BenchmarkTools.save("bench/output.json", median(results))
