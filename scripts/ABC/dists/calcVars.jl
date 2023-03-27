time_load = @elapsed begin
    @everywhere begin
        using Pkg
        Pkg.activate(".")
    end
    @everywhere begin
        using Arrow, CSV, DataFrames, OnlineStats, OnlineStatsBase
        include("../../../src/ABC/Variances.jl")
    end
end
println("Load: $time_load")

mkpath("results/ABC/variances/sents/q8")

# read relevant files
time_read = @elapsed begin
    # if isfile("data/exp_pro/compare/perdate_age_long.csv")
    #     quantdata = CSV.read("data/exp_pro/compare/perdate_age_long.csv", DataFrame, types = Dict(:plot => Symbol))
    # else
    #     quantdata = rearrange_datafile()
    # end
    quantdata = DataFrame(Arrow.Table("data/exp_pro/compare/perdate_age_long_10.arrow"))
    firstn = parse(Int, ARGS[3])
    if firstn == 0
        quantfiles = readdir(string("/scratch/mvanega1/ABC/sims/", ARGS[1]), join = true, sort = false)
        qualfiles = readdir(string("/scratch/mvanega1/ABC/sims/", ARGS[2]), join = true, sort = false)
    else
        quantfiles = readdir(string("/scratch/mvanega1/ABC/sims/", ARGS[1]), join = true, sort = false)[1:firstn]
        qualfiles = readdir(string("/scratch/mvanega1/ABC/sims/", ARGS[2]), join = true, sort = false)[1:firstn]
    end
end
println("Read: $time_read")
flush(stdout)

# calculate variance from sim outputs
time_vars = @elapsed begin
    g_σ2_quants, g_n_quants = σ2_nts(quantfiles)
    # σ2_quants, n_quants, g_σ2_quants, g_n_quants = σ2_nts(quantfiles)
    # σ2_quants, n_quants = σ2_nts(quantfiles)
    σ2_quals, n_quals = σ2_ls(qualfiles)
end
println("Variance: $time_vars")
flush(stdout)

# time_join = @elapsed begin
#     # σ2_quants = leftjoin(quantdata, σ2_quants, on = [:plot, :dayn, :age, :cycle], order = :left)
#     # n_quants = leftjoin(quantdata[:, [:plot, :dayn, :age, :cycle]], n_quants, on = [:plot, :dayn, :age, :cycle], order = :left)
# end
# println("Join: $time_join")
flush(stdout)

time_write = @elapsed begin
    # write csvs
    # CSV.write("results/ABC/variances/sents/q7/v_quants.csv", σ2_quants)
    CSV.write("results/ABC/variances/sents/q8/v_gquants.csv", g_σ2_quants)
    CSV.write("results/ABC/variances/sents/q8/v_quals.csv", σ2_quals)
    # CSV.write("results/ABC/variances/sents/q7/n_quants.csv", n_quants)
    CSV.write("results/ABC/variances/sents/q8/n_gquants.csv", g_n_quants)
    CSV.write("results/ABC/variances/sents/q8/n_quals.csv", n_quals)
end
println("Write: $time_write")
