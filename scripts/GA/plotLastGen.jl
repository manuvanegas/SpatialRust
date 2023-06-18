using CairoMakie, CSV, DataFrames, DelimitedFiles, Statistics
using SpatialRust
include("../../src/GA/Plots.jl")


function express(col)
    # pos = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:19, 20:25, 26:31, 32:37, 38:43, 44:48, 49:54, 55:60, 61:66, 67:72, 73:73, 74:79]
    # pos = [1:2, 3:3, 4:5, 6:6, 7:7, 8:13, 14:14, 15:20, 21:21, 22:27, 28:28, 29:34, 35:40, 41:46, 47:51, 52:57, 58:63, 64:64, 65:70, 71:71, 72:77, 78:78, 79:80, 81:86]
    pos = [1:7, 8:14, 15:21, 22:27, 28:33, 34:39, 40:41, 42:45, 46:46, 47:53, 54:54, 55:56, 57:57, 58:64, 65:71, 72:78, 79:80, 81:87]
    transcripts = [bits_to_int(col[p]) for p in pos]
    # transcripts[[1:3; 5]] .+= 1
    return ints_to_pars(transcripts, 2555, 0.65)
end

function getbestind(folder, exp, v)
    maxf, pos = findmax(readdlm(joinpath(folder, exp, "fitnesshistory-$v.csv"), ','))
    println(exp, ", ", maxf, ", ", pos)

    gen = string("g-", lpad(pos[1], 3, "0"), ".csv")
    chrom = readdlm(joinpath(folder, exp, "pops", gen), ',')[:, pos[2]]
    
    return (express(chrom)..., exp = exp)
end

exps = ["profit-np-s",  "sev-np-s", "profit-p-s1b",  "sev-p-s1b", "profit-np",  "sev-np", "profit-p-2b",  "sev-p-2b",]
pars = collect(getbestind("results/GA/4/2/", e, 125) for e in exps);

bestexppars = DataFrame(pars)

CSV.write("results/GA/4/2/fittest/parsdf.csv", bestexppars)

bestexpparsNF = deepcopy(bestexppars)
bestexpparsNF.fungicide_sch .= [Int[]]
bestexpparsNF.fung_stratg .= :cal

CSV.write("results/GA/4/2/fittest/parsdfNF.csv", bestexpparsNF)

###########################################################
##


function global100(folder, exp, v)
    fh = readdlm(joinpath(folder, exp, "fitnesshistory-$v.csv"), ',')
    best100 = first(sortperm(vec(fh), rev = true), 100)
    println(fh[best100[100]])
    indpos = collect((mod1(i, v), div(i, v) + 1) for i in best100)
    inds = [readdlm(joinpath(folder, exp, "pops", string("g-", lpad(p[1], 3, "0"), ".csv")), ',')[:, p[2]] for p in indpos]

    return DataFrame(collect(express(i) for i in inds))
end

function first100(folder, exp)
    pop = readdlm(joinpath(folder, exp, "pops", "g-001.csv"), ',')
    return DataFrame(collect(express(i) for i in eachcol(pop)))
end

function last100(folder, exp, v)
    pop = readdlm(joinpath(folder, exp, "pops", string("g-", lpad(v, 3, "0"), ".csv")), ',')
    return DataFrame(collect(express(i) for i in eachcol(pop)))
end

function init_vs_best(folder, exp, v, par)
    best = global100(folder, exp, v)
    init = first100(folder, exp)
    last = last100(folder, exp, v)
    bv = reduce(vcat, best[:, par])
    iv = reduce(vcat, init[:, par])
    lv = reduce(vcat, last[:, par])
    return iv, bv, lv
end

iv, bv, lv = init_vs_best("results/GA/4/2/", "profit-np", 125, :prune_sch)

hist(iv, bins = 20);
hist!(bv, bins = 20)
# hist!(lv)
current_figure()

# lastfitns = DataFrame(indiv = 1:30, fitns = vec(readdlm("results/GA/shorttprofit3032-0.5-0.02/g-032.csv",',')))


###########################################################
##

include("../../src/GA/GARuns.jl")

function phenofit(obj, lp, fh = 0)
    if fh == 0
        fh = lp
    end
    lastpopf = readdir("results/GA/4/2/$obj/pops/", join = true, sort = true)[lp]
    lastpop = readdlm(lastpopf, ',', Bool)
    parsdf = DataFrame(map(express, eachcol(lastpop)))
    transform!(parsdf, eachindex => :indiv)

    fitness = CSV.read("results/GA/4/2/$obj/fitnesshistory-$fh.csv", DataFrame, header = false)
    println(findmax(maximum(r) for r in eachrow(fitness)))
    lastfitns = DataFrame(indiv = 1:ncol(fitness), fitns = stack(fitness[lp,:]))
    println(maximum(lastfitns.fitns))
    leftjoin!(parsdf, lastfitns, on = :indiv)

    return parsdf
end

parsdf = phenofit("sev-p-2b", 125, 125);
bestpars = subset(parsdf, :fitns => ByRow(==(maximum(parsdf.fitns))))
bestpars = sort(parsdf, :fitns, rev = true)[1:5,:]

@time bdf = garuns(1, 365, 1.0, false; 
    mean_temp = 22.0,
    rain_prob = 0.8,
    bestpars[1,Not([:indiv,:fitns])]...)

# bp2 = deepcopy(bestpars)
# bp2[!,:row_d] .= 2
# bdf = garuns(1, 2190, 0.85, false; mean_temp = 22.0, bp2[1,Not([:indiv,:fitns])]...)

# mean(bdf.mapshade)
# "profit-np-s" -> 0.3960382138592426
# "sev-np-s" -> 0.34956781443576285
# "profit-p-s1b" -> 0.34530010803395605
# "sev-p-s1b" -> 0.29290319850432917
# "profit-np" -> 0.1615357697815683
# "sev-np" -> 0.1542541267449669
# "profit-p-2b" -> 0.5376182424600082
# "sev-p-2b" -> 0.5399456336288129

lines(bdf.dayn, bdf.production)
# lines(bdf.dayn, bdf.farmprod)
lines(bdf.dayn, bdf.sumarea)
lines(bdf.dayn, bdf.severity)
lines(bdf.dayn[1:365], bdf.sumarea[1:365])
lines(bdf.dayn, bdf.fung)
lines(bdf.dayn, bdf.active)
lines(bdf.dayn, bdf.remprofit)
lines(bdf.dayn, bdf.costs)
lines(bdf.dayn, bdf.remprofit .- bdf.costs)
lines(bdf.dayn, bdf.incidence);
lines!(bdf.dayn, bdf.obs_incidence)
current_figure()

##
@time basesc = garuns(1, 2190, 0.65, false,
    row_d = 1,
    plant_d = 1,
    shade_d = 6,
    common_map = :regshaded,
    prune_sch = [200],#[250,145],
    # prune_sch = [205, 46], # [74, 196, 319],
    post_prune = [0.445312, 0.292969],
    # post_prune = [0.05, 0.05, 0.05],
    inspect_period = 2,
    inspect_effort = 0.45,
    # fungicide_sch = [125, 166, 237],
    fungicide_sch = Int[],
    fung_stratg = :incd,
    # incidence_thresh = 0.05,
    # fung_gro_prev = 0.3,
    # fung_gro_cur = 0.6,
    # fung_spor_cur = 0.5,
    # fung_inf = 0.9,
    # fung_effect = 30,
    # mean_temp = 22.0,
    coffee_price = 1.0,
    # max_fung_sprayings = 3,
)

# @benchmark basesc = garuns(1, 730, 0.65, false; prf...)
bbexp = deepcopy(bestexppars[8,:])
bbexp.inspect_effort = 0.5

@time basesc = garuns(1, 2555, 0.65, false; bbexp...)

lines(basesc.dayn, basesc.production)
lines(basesc.dayn, basesc.gsumarea)
lines(basesc.dayn, basesc.sumarea)
lines(basesc.dayn, basesc.severity)
lines(basesc.dayn, basesc.nl)
lines(basesc.dayn, basesc.inoculum)
lines(basesc.dayn, basesc.fung)
lines(basesc.dayn, basesc.active)
lines(basesc.dayn, basesc.mapshade)
lines(basesc.dayn, basesc.costs)
lines(basesc.dayn, basesc.remprofit .- basesc.costs)
lines(basesc.dayn, basesc.incidence);
lines!(basesc.dayn, basesc.obs_incidence)
current_figure()


# basesc = garuns(1, 730, 0.65, false;
#     row_d = 2,
#     plant_d = 1,
#     shade_d = 9,
#     common_map = :regshaded,
#     prune_sch = [75, 197, 319],
#     post_prune = [0.05, 0.05, 0.05],
#     inspect_period = 16,
#     inspect_effort = 0.25,
#     rm_lesions = 1,
#     fungicide_sch = [125, 177, 238],
#     fung_stratg = :cal,
# )

obj = "shorttermprofit"
obj = "longtermprofit-0.0"
pcross = 0.5
pmut = 0.02
lp = 80
