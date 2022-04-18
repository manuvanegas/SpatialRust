using DataFrames, Plots

## wind-mediated
function winddist(n, basedist, diff)
 dists = DataFrame(d = [], s = [])
 # histogram(abs.(2 .* randn(n) .* 2.0 ./ (1.0 + 0.2)))
 for sl in 0.3:0.1:1.0
     append!(dists, DataFrame(d = abs.(2 .* randn(n)) .* basedist .* diff .* sl, s = sl))
     # histogram!(dists)
 end
 return dists
end
wddiff = 1.2
wtddf = winddist(1000, 5.0, ddiff)
boxplot(string.(wtddf.s), wtddf.d, title = wddiff)

## rain-mediated

tparab(x,v) = (x - 0.55)^2 * (1 - v) / 0.2025 + v
txs = []
for xs in 0.0:0.1:1.0
    push!(txs, tparab(xs,2.0))
end
plot(0.0:0.1:1.0, txs)

function raindist(n, basedist, diff)
 dists = DataFrame(d = [], s = [])
 for sl in 0.3:0.1:1.0
     append!(dists, DataFrame(d = abs.(2 .* randn(n) .* basedist) .* tparab(sl, 2.0), s = sl))
 end
 return dists
end
ddiff = 1.2
tddf = raindist(1000, 1.0, ddiff)
boxplot(string.(tddf.s), tddf.d, title = ddiff)
