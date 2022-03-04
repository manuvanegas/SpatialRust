using DataFrames, OnlineStats

df = DataFrame(g1 = rand(Bool, 50), g2 = repeat(1:5, 10), x1 = 1:50, x2 = 2:2:100, x3 = 3:3:150)
df2 = DataFrame(g1 = rand(Bool, 50), g2 = repeat(2:6, 10), x1 = 1:50, x2 = 2:2:100, x3 = 3:3:150)
df3 = DataFrame(g1 = rand(Bool, 100), g2 = repeat(2:6, 20), x1 = repeat(0:24, 4), x4 = 201:300, x5 = fill(-1, 100))

dfitr = ((r.g2, r.g1) => (r.x1, r.x2, r.x3) for r in eachrow(df))
dfitr2 = ((r.g2, r.g1) => (r.x1, r.x2, r.x3) for r in eachrow(df2))

dfout = fit!(GroupBy(Tuple, Series(3Variance(), 3Counter())), dfitr)
dfout2 = fit!(GroupBy(Tuple, Series(3Variance(), 3Counter())), dfitr2)

# testing transforming functions. and it works!
dfitr3 = ((r.g2, r.g1) => r for r in eachrow(df2))
ttransform(dfr::DataFrameRow) = (dfr.x1 + dfr.x2, dfr.x3 - dfr.x1)
dfoutft = fit!(GroupBy(Tuple, FTSeries(DataFrameRow, 2Sum(); transform = ttransform)), dfitr3)
transfdf2 = transform(df2, [:x1, :x2] => (+) => :r1, [:x3, :x1] => (-) => :r2)
confdfout = combine(groupby(transfdf2, [:g2, :g1]), :r1 => sum, :r2 => sum)

dfdfout = combine(groupby(df, [:g2, :g1]), :x1 => var)

dfoutout = merge(dfout,dfout2)
dfoutout2 = merge(dfout2,dfout)
dfoutout3 = fit!(dfout)
# using merge! was problematic (had 20 instead of 10 total (x,6)'s)
# merge worked fine. dfoutout == dfoutout2 except for (false,4)
# values are not seen as ==,but the string version of them is ==


df3 = vcat(df,df2)
dfitr3 = ((r.g1, r.g2) => (r.x1, r.x2) for r in eachrow(df3))
dfout3 = fit!(GroupBy(Tuple, 2Mean()), dfitr3)

dfoutout == dfout3

collect(value(dfoutout)) .== collect(value(dfout3))

for k in keys(value(dfoutout))
    if (dfoutout[k] != dfoutout2[k])
        println(k)
        println(dfoutout[k])
        println("not =")
        println(dfoutout2[k])
    end
end


## turn into df (benchmark options)
using BenchmarkTools

function t_dfize(dfout::GroupBy)
    df = DataFrame(g2 = Int[], g1 = Bool[],
                    v_1 = Float64[], v_2 = Float64[], v_3 = Float64[],
                    n_1 = Int[], n_2 = Int[], n_3 = Int[])
    for k in keys(value(dfout))
        row::Vector{Any} = collect(k)
        append!(row, collect(value.(value(dfout[k].stats[1]))))
        append!(row, collect(value.(value(dfout[k].stats[2]))))
        push!(df, row)
    end
    return df
end

function t_dfize2(dfout::GroupBy)
    df = DataFrame(g2 = Int[], g1 = Bool[],
                    v_1 = Float64[], v_2 = Float64[], v_3 = Float64[],
                    n_1 = Int[], n_2 = Int[], n_3 = Int[])
    for k in keys(value(dfout))
        df_row = DataFrame()
        df_row[!, :g2] = [k[1]]
        df_row[!, :g1] = [k[2]]
        df_row[!, :v_1] .= [value(value(dfout[k].stats[1])[1])]
        df_row[!, :v_2] .= [value(value(dfout[k].stats[1])[2])]
        df_row[!, :v_3] .= [value(value(dfout[k].stats[1])[3])]
        df_row[!, :n_1] .= [value(value(dfout[k].stats[2])[1])]
        df_row[!, :n_2] .= [value(value(dfout[k].stats[2])[2])]
        df_row[!, :n_3] .= [value(value(dfout[k].stats[2])[3])]
        append!(df, df_row)
    end
    return df
end

@benchmark t_dfize($dfout)
@benchmark t_dfize2($dfout)


## Does DF repeat rows when joining?

rdata_var = DataFrame(a = 1:6, b = repeat(1:2,3), c = 5:5:30)

rsims = DataFrame(rown = repeat(1:2, inner = 6), a = repeat(1:6,2), b = repeat(repeat(1:2, 3), 2), x = 3:3:36)

# yes. join rsims into rdata_var (leftjoin(rdata_var,rsims))

## dealing with separate sims_out and empirical+variances dfs
tdouble_itr = (r.g1 => ((r.g2, dfr.g2, r.x1, dfr.x1),
                            (r.x4, dfr.x1),
                            (r.x5, dfr.x2)) for (r, dfr) in zip(eachrow(df3), Iterators.cycle(eachrow(df))) )

ttransform2(row) = sum.(row[2:3])

tfilter(row) = row[1][1] == row[1][2]

tdiffs = fit!(GroupBy(Bool, FTSeries(Tuple, 2Sum(); filter = tfilter, transform = ttransform2)), tdouble_itr)

# works, but there is no way to make sure that the right (tick, age/cycle) are being compared
