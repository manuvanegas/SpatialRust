using BenchmarkTools


function withfilter()
    a = rand(10_000)
    a[rand(1:10_000)] = 2.0
    a = filter(i -> i != 2.0, a)
    return a
end

function withsetdiff()
    a = rand(10_000)
    a[rand(1:10_000)] = 2.0
    a = setdiff(a, 2.0)
    return a
end

function withfindfirst()
    a = rand(10_000)
    a[rand(1:10_000)] = 2.0
    a = deleteat!(a, findfirst(i -> i == 2.0, a))
    return a
end

withfilter() # mid (median 20µs)
withsetdiff() # slowest (median 392µs)
withfindfirst() # fastest (median 13 µs)
