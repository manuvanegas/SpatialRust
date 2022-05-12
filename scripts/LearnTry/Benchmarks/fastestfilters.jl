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

withfilter() # 2nd place (median 20µs)
withsetdiff() # 3rd (median 392µs)
withfindfirst() # 1st (median 13 µs)

## Sets

l = 10000

function vfindfirst(l)
    a = rand(l)
    a[rand(1:l)] = 2.0
    sa = Set(a)
    @assert length(sa) == l
    a = deleteat!(a, findfirst(i -> i == 2.0, a))
    return a
end

function setdelete(l)
    a = rand(l)
    a[rand(1:l)] = 2.0
    sa = Set(a)
    @assert length(sa) == l
    a = delete!(sa, 2.0)
    return a
end

vfindfirst(l)
setdelete(l)
# they're almost the same. Plus, fcts like shuffle, sample, sort, don't work on sets
