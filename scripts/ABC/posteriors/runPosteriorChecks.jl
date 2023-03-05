@everywhere begin
    using Pkg
    Pkg.activate(".")
end
@everywhere begin
    using Arrow, CSV, DataFrames, Statistics, SpatialRust
    include("../../../src/ABC/PosteriorChecks.jl")
end

metrics = "sentinels"
max_missings = 5
pardir = "results/ABC/params/"
pdir = mkpath("results/ABC/posteriors/b")
csvtail = string("_", metrics, "_", max_missings, ".csv")
arrtail = string("_", metrics, "_", max_missings, ".arrow")


when_rust = Vector(Arrow.Table("data/exp_pro/input/whentocollect.arrow")[1])
when_2017 = filter(d -> d < 200, when_rust)
when_2018 = filter(d -> d > 200, when_rust)
w_table = Arrow.Table("data/exp_pro/input/weather.arrow")
temp_data = Tuple(w_table[2])
rain_data = Tuple(w_table[3])
wind_data = Tuple(w_table[4])

accepted, rejected, pointestimate = read(
    string.(pardir, ("accepted", "rejected", "pointestimate"), csvtail)...
)
repeat!(pointestimate, 100)
pointestimate.RowN = collect(10^6 + 1:10^6 + 100)
select!(pointestimate, 15, 1:14)

acc_outs = pmap(
    p -> sim_abc(p, temp_data, rain_data, wind_data, when_2017, when_2018),
    eachrow(accepted); retry_delays = fill(0.1, 3)
)
rej_outs = pmap(
    p -> sim_abc(p, temp_data, rain_data, wind_data, when_2017, when_2018),
    eachrow(rejected); retry_delays = fill(0.1, 3)
)
point_outs = pmap(
    p -> sim_abc(p, temp_data, rain_data, wind_data, when_2017, when_2018),
    eachrow(pointestimate); retry_delays = fill(0.1, 3)
)

acc_quant, acc_qual = reduce(cat_dfs, acc_outs)
rej_quant, rej_qual = reduce(cat_dfs, rej_outs)
point_quant, point_qual = reduce(cat_dfs, point_outs)

quants = vcat(acc_quant, rej_quant, point_quant, source = :source => [:acc, :rej, :point])
quals = vcat(acc_qual, rej_qual, point_qual, source = :source => [:acc, :rej, :point])

cwrite(pdir, csvtail, [quants, quals], ["quant","qual"])

    


