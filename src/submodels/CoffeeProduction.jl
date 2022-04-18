using Plots

## vegetative vs reproductive growth
function growth1(veg::Float64, rep::Float64)
    sun = 1
    Krep = 0.5
    new_g = sun * veg * (1/(1 + (rep / Krep)^2)) # veg growth is inhibited following Hill fnc

    return new_g + veg, (sun * veg + rep)
end

function run_g1(init_v::Float64, init_r::Float64, days::Int)
    vegs = vcat(init_v, zeros(days - 1))
    reps = vcat(init_r, zeros(days - 1))
    for day in 1:(days - 1)
        vegs[day + 1], reps[day + 1] = growth1(vegs[day], reps[day])
    end
    return vegs, reps
end

days = 50
vegs, reps = run_g1(0.1, 0.0, days)

plot(collect(1:days), vegs)
plot(collect(1:days), reps)

## introducing a resources variable

function growth2(res::Float64, veg::Float64, rep::Float64)
    sun = 1
    thres = 0.8
    rep_p = res > thres ? 0.3 : 0.0
    veg_p = 0.5 - rep_p

    d_veg = veg_p * res
    d_rep = rep_p * res
    d_res = sun * veg - d_veg - d_rep

    return res + d_res, min(veg + d_veg, 1.0), rep + d_rep
end

function run_g2()
    days = 100
    ress = vcat(0.0, zeros(days-1))
    vegs = vcat(0.1, zeros(days-1))
    reps = vcat(0.0, zeros(days-1))

    for day in 1:(days - 1)
        ress[day + 1], vegs[day + 1], reps[day + 1] = growth2(ress[day], vegs[day], reps[day])
    end
    return ress, vegs, reps
end

ress, vegs, reps = run_g2()

plot(collect(1:100), ress)
plot(collect(1:100), vegs)
plot(collect(1:100), reps)

## fixing a "resources expenditure" per unit of rep
# plant invests in a set amount of reproductive growth
# resources or reserves?

function growth3(res::Float64, veg::Float64, rep::Float64, floral_induction::Int, buds::Float64)
    sun = 1.0
    # thres = 0.8
    # floral_induction = 190
    acq_res = sun * veg # 0 to 1.0
    # estimate future accumulation of resources by taking into acc current res and today's change
    # buds = res * acq_res
    # then determine daily "transfer"
    # est_daily = buds / (365 - floral_induction)

    d_rep = buds / (365 - floral_induction)
    d_veg = 0.4 * veg # maintenance is proportional to amount of veg tissue
    # d_veg = acq_res - d_rep < 0 ? acq_res - d_rep : min(acq_res - d_res, acq_rep * 0.3)
    # d_res = acq_res - d_rep - (d_veg < 0.0 ? 0.0 : d_veg) # only substract from res accumulation if d_veg is (+)
    # if d_veg < 0.0
    #     # println("less")
    #     d_veg_res = 0.0
    # else
    #     d_veg_res = d_veg
    # end
    d_res = acq_res - d_rep - d_veg

    return res + d_res, max(0.0, min(veg + d_veg, 1.0)), rep + d_rep
end

function run_g3()
    days = 2190
    floral_induction = 190
    buds = 0.0
    # est_daily = 0
    ress = vcat(0.0, zeros(days-1))
    vegs = vcat(1.0, zeros(days-1))
    reps = vcat(0.0, zeros(days-1))

    for day in 1:(days - 1)
        if mod(day, 365) == 190
            buds = ress[day] * 1.0 * vegs[day] * 2 #1.2 # berrys use 60% of yearly carbon
            println(buds)
        end
        if mod(day, 365) == 0
            buds = 0.0
            reps[day] = 0.0
        end
        ress[day + 1], vegs[day + 1], reps[day + 1] = growth3(ress[day], vegs[day], reps[day], floral_induction, buds)
    end
    return ress, vegs, reps
end

ress, vegs, reps = run_g3()

plot(collect(1:2190), ress)
plot(collect(1:2190), vegs)
plot(collect(1:2190), reps)

## we have oscillations, but veg is not set to change yet. Try to change that

function growth4(res::Float64, veg::Float64, rep::Float64, floral_induction::Int, buds::Float64)
    sun = 1.0
    # thres = 0.8
    # floral_induction = 190
    acq_res = sun * veg # 0 to 1.0
    # estimate future accumulation of resources by taking into acc current res and today's change
    # buds = res * acq_res
    # then determine daily "transfer"
    # est_daily = buds / (365 - floral_induction)

    d_rep = buds / (365 - floral_induction)
    d_veg = 0.4 * veg # maintenance is proportional to amount of veg tissue
    # d_veg = acq_res - d_rep < 0 ? acq_res - d_rep : min(acq_res - d_res, acq_rep * 0.3)
    # d_res = acq_res - d_rep - (d_veg < 0.0 ? 0.0 : d_veg) # only substract from res accumulation if d_veg is (+)
    # if d_veg < 0.0
    #     # println("less")
    #     d_veg_res = 0.0
    # else
    #     d_veg_res = d_veg
    # end
    d_res = acq_res - d_rep - d_veg

    return res + d_res, max(0.0, min(veg + d_veg, 1.0)), rep + d_rep
end

function run_g4()
    days = 2190
    floral_induction = 190
    buds = 0.0
    # est_daily = 0
    ress = vcat(0.0, zeros(days-1))
    vegs = vcat(1.0, zeros(days-1))
    reps = vcat(0.0, zeros(days-1))

    for day in 1:(days - 1)
        if mod(day, 365) == 190
            buds = ress[day] * 1.0 * vegs[day] * 2 #1.2 # berries use 60% of yearly carbon
            println(buds)
        end
        if mod(day, 365) == 0
            buds = 0.0
            reps[day] = 0.0
        end
        ress[day + 1], vegs[day + 1], reps[day + 1] = growth3(ress[day], vegs[day], reps[day], floral_induction, buds)
    end
    return ress, vegs, reps
end

ress, vegs, reps = run_g3()

plot(collect(1:2190), ress)
plot(collect(1:2190), vegs)
plot(collect(1:2190), reps)


function f1(a,b,c)
    c +=1
    return a + b
end
function f2(a,b)
    c=2
    println(c)
    f1(a,b,c)
    println(c)
end

##  A fresh approach
using Plots, Interact

function par_dveg(K::Float64, µ::Float64, hill::Float64)
    return dveg(R::Float64, veg::Float64) = ( 1.0 / (1.0 + (K / R)^hill) - 1) * µ * veg
end

function par_dR(K::Float64, k::Float64, hill::Float64)
    return dR(R::Float64, veg::Float64) = k * V - ( 1.0 / (1.0 + (K / R)^hill) )
end

function run_g5(K::Float64, µ::Float64, k::Float64, hill::Float64, Ri::Float64, vegi::Float64, days::Int = 1900)
    Rs = vcat(Ri, zeros(days - 1))
    vegs = vcat(vegi, zeros(days - 1))

    dR = par_dveg(K, k)
    dveg = par_dveg(K, µ)

    for d in 2:days
        Rs[d] = Rs[d-1] + dR(Rs[d-1], vegs[d-1])
        vegs[d] = vegs[d-1] + dveg(Rs[d-1], vegs[d-1])
    end

    return Rs, vegs
end
