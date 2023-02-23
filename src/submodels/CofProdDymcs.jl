# Coffee production dynamics
# using Pkg
# Pkg.activate("src/submodels")
using CairoMakie


#= Variables:
- V: vegetative tissue
- B: berries
- S: stored resources
- R: Rust

Parameters (pars):
- a: Hill constant for PhS saturation against V
- b: fraction of daily energy to V (in vegetative stage)
- c: fraction of daily energy to S (in vegetative stage)
- d: budding 
- e: storage use saturation parameter # not used anymore
- f: storage deficit threshold
- µ_V: V decay constant
- µ_B: B decay constant
- µ_S: S decay constant
- γ: R resource demand from S
- veg_gro: R growth during vegetative phase
- rep_gro: fruit load-dependent R growth during repro. phase
- lgh: sunlight %

Other ("outer") Parameters:
- years: tot years simulated
- bd: blossoming day
- wrust: with rust? rust grows in year 24 and goes back to 0 starting y 25
- initial conditions for V, B, S, R
=#

# Plot function. Runs for each shade level and plots the 4 variables
function plot_sun_shade(lastdays::Bool = true, wrust::Bool = true;
    a::Float64 = 0.01,
    b::Float64 = 0.5,
    c::Float64 = 1.0,
    d::Float64 = 1.0,
    e::Float64 = 1.0,
    f::Float64 = 1.0,
    μ_V::Float64 = 1.0,
    μ_B::Float64 = 1.0,
    μ_S::Float64 = 0.1,
    γ::Float64 = 0.05,
    # veg_gro::Float64 = 0.3,
    rep_gro::Float64 = 0.7,
    bd::Int = 182,
    years::Int = 10,
    Vi::Float64 = 0.1,
    Bi::Float64 = 0.0,
    Si::Float64 = 0.0,
    Ri::Float64 = 0.0,
    lasty = 5)

    if lastdays
        plotdays = (years - lasty)*365:(365*years)
    else
        plotdays = 1:(365*years)
    end

    # sn_gr = run_oncee(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, bd, years, Vi, Bi, Si, Ri, 1.0, wrust)
    # sh_gr = run_oncee(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.7, wrust)
    # shh_gr = run_oncee(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.5, wrust)
    # shhh_gr = run_oncee(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.3, wrust)
    sn_gr = run_oncee(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, rep_gro, bd, years, Vi, Bi, Si, Ri, 1.0, wrust)
    sh_gr = run_oncee(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.7, wrust)
    shh_gr = run_oncee(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.5, wrust)
    shhh_gr = run_oncee(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.3, wrust)

    # sn_gr = run_once(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.9, wrust)
    # sh_gr = run_once(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.8, wrust)
    # shh_gr = run_once(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.6, wrust)
    # shhh_gr = run_once(a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, bd, years, Vi, Bi, Si, Ri, 0.2, wrust)

# plot commands
    ticksx = filter(x -> (x % 365 == 0 || x % 365 == bd), plotdays)

    fig = Figure();
    axs = [Axis(fig[i, j], xticks = ticksx, xticklabelrotation = pi/2) for i in 1:4, j in 1:4]
    Vsn, Bsn, Ssn, Rsn, Vsh, Bsh, Ssh, Rsh, Vshh, Bshh, Sshh, Rshh, Vshhh, Bshhh, Sshhh, Rshhh = axs
    linkyaxes!(Vsn, Vsh, Vshh, Vshhh)
    linkyaxes!(Bsn, Bsh, Bshh, Bshhh)
    linkyaxes!(Ssn, Ssh, Sshh, Sshhh)
    linkyaxes!(Rsn, Rsh, Rshh, Rshhh)
    hidexdecorations!.([axs[i] for i in 1:16 if i % 4 != 0], grid = false)
    # hidexdecorations!(Bsn, grid = false)
    # hidexdecorations!(Ssn, grid = false)
    # hidexdecorations!(Vsh, grid = false)
    # hidexdecorations!(Bsh, grid = false)
    # hidexdecorations!(Ssh, grid = false)
    ylabs = ["V", "B", "S", "R"]
    for var in 1:4
        lines!(axs[var,1], plotdays, sn_gr[var, plotdays])
    end
    for var in 1:4
        lines!(axs[var,2], plotdays, sh_gr[var, plotdays])
    end
    for var in 1:4
        lines!(axs[var,3], plotdays, shh_gr[var, plotdays])
    end
    for var in 1:4
        lines!(axs[var,4], plotdays, shhh_gr[var, plotdays])
    end
    Label(fig[1,1, Top()], "Sun (1.0)")
    Label(fig[1,2, Top()], "Shade (0.7)")
    Label(fig[1,3, Top()], "Shade (0.5)")
    Label(fig[1,4, Top()], "Shade (0.3)")
    Label(fig[1,0], "V", rotation = pi/2, tellheight = false)
    Label(fig[2,0], "B", rotation = pi/2, tellheight = false)
    Label(fig[3,0], "S", rotation = pi/2, tellheight = false)
    Label(fig[4,0], "R", rotation = pi/2, tellheight = false)
    Label(fig[5,:], "a=$a, b=$b, d=$d, e=$e, f=$f, μ_B=$μ_B, bd=$bd, Vi=$Vi, Si=$Si", tellwidth = false)
    # ylims!.(axs, low = -0.05)

    return fig
end

# Organizes inputs. Main.
function run_oncee(;
    a::Float64 = 0.1,
    b::Float64 = 0.5,
    c::Float64 = 0.5,
    d::Float64 = 1.0,
    e::Float64 = 0.0,
    f::Float64 = 0.0,
    μ_V::Float64 = 1.0,
    μ_B::Float64 = 1.0,
    μ_S::Float64 = 0.1,
    γ::Float64 = 0.05,
    # veg_gro::Float64 = 0.3,
    rep_gro::Float64 = 0.7,
    bd::Int = 182,
    years::Int = 1,
    Vi::Float64 = 0.1,
    Bi::Float64 = 0.0,
    Si::Float64 = 0.0,
    Ri::Float64 = 0.0,
    lgh::Float64 = 1.0,
    wrust::Bool)

    # params = [a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, lgh]
    params = [a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, rep_gro, lgh]
    init = [Vi, Bi, Si, Ri]
    record = onerun(init, params, bd, years, wrust)
end

function run_oncee(a::Float64 = 0.1,
    b::Float64 = 0.5,
    c::Float64 = 0.5,
    d::Float64 = 1.0,
    e::Float64 = 0.0,
    f::Float64 = 0.0,
    μ_V::Float64 = 1.0,
    μ_B::Float64 = 1.0,
    μ_S::Float64 = 0.1,
    γ::Float64 = 0.05,
    # veg_gro::Float64 = 0.3,
    rep_gro::Float64 = 0.7,
    bd::Int = 182,
    years::Int = 1,
    Vi::Float64 = 0.1,
    Bi::Float64 = 0.0,
    Si::Float64 = 0.0,
    Ri::Float64 = 0.0,
    lgh::Float64 = 1.0,
    wrust::Bool = false)

    # params = [a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, veg_gro, rep_gro, lgh]
    params = [a, b, c, d, e, f, µ_V, μ_B, µ_S, γ, rep_gro, lgh]
    init = [Vi, Bi, Si, Ri]
    record = onerun(init, params, bd, years, wrust)
end

# Core run
function onerun(init::Vector{Float64}, params::Vector{Float64}, bd::Int, years::Int, wrust::Bool)
    veg!, rep!, def!, buds! = gen_3stages(params, bd)
    record = zeros(4, (years * 365))
    
    s = 1
    record[:, 1] .= init
    
    for d in 2:bd
        @views veg!(record[:, d], record[:, d - 1])
        s += 1
    end

    @views buds!(record[:, bd])

    for d in (bd + 1):365
        if record[3, d - 1] > params[6] # is S > f ?
            @views rep!(record[:, d], record[:, d - 1])
        else
            @views def!(record[:, d], record[:, d - 1])
        end
        s += 1
    end

    for y in 1:(years - 1)
        dd = y * 365
        record[2, dd] = 0.0

        if wrust
            if y == 24
            record[4, dd] = 0.00014
            elseif y == 25
                record[4, dd] = 0.0
            end
        end

        for d in (dd + 1):(dd + bd)
            @views veg!(record[:, d], record[:, d - 1])
            s += 1
            if record[1, d] < 1.0
                # println("$(record[1,d]) on $d and light $(params[7])")
            end
        end

        @views buds!(record[:, (dd + bd)])

        for d in (dd + bd + 1):(dd + 365)
            if record[3, d - 1] > params[6] # is S > f ?
                @views rep!(record[:, d], record[:, d - 1])
                s += 1
            else
                @views def!(record[:, d], record[:, d - 1])
                s += 1
            end
        end
    end
    return record
end

# Generate growth functions for the 3 phases
function gen_3stages(params, bd)
    # a, b, c, d, e, f, μ_V, μ_B, μ_S, γ, veg_gro, rep_gro, lgh = params
    a, b, c, d, e, f, μ_V, μ_B, μ_S, γ, rep_gro, lgh = params
    g_r = 0.15
    β = 0.0
    inh = 1.0 #0.15
    resc = 0.2
    avail = 0.5

    function vegetative!(varsout::SubArray, varsin::SubArray)
        V, B, S, R = varsin
        fV = (0.2 * V / (a + 0.2 * V))
        # ΔV = a * lgh * V * b - μ_V * V
        # ΔS = a * lgh * V * c
        PhS = avail * (resc * (lgh / (lgh + 0.05))) * fV #- β * R
        ΔV = PhS * b - μ_V * V
        # ΔV = PhS - μ_V
        # ΔS = PhS * c - γ * S * R#- μ_S * S
        # ΔR = (g_r * R * (1.0 - R)) * (inh / (inh + γ * S * R))
        ΔS = PhS * c  - γ * R#- μ_S * S
        host_gro = 1.0 + rep_gro * (B / (V + B))
        ΔR = (g_r * R * (1.0 - R)) * host_gro # (1.0 - 0.5 * (S / (S + inh)))  #* (inh / (inh + γ * S * R))
    
    
        varsout .= [V + ΔV, B, S + ΔS, R + ΔR] 
    end
    
    function reproductive!(varsout::SubArray, varsin::SubArray)
        V, B, S, R = varsin
        # ΔV = e - μ_V * V = 0 # could be != 0 ?
        # ΔS = - d - (μ_V * V)
        # ΔB = a * lgh * V + d - μ_B * B
        # newb=b-0.2
        # tob=1.0-newb
        fV = (0.2 * V / (a + 0.2 * V))
        sink = μ_V * V + μ_B * B
        sink2 = V + B
        tob = B / sink2
        newb = 1.0 - tob
        # newb = min(1.0 - tob, b)
        PhS = avail * (resc * lgh / (lgh + 0.05)) * fV # - β * R
        Sd = μ_V * V + μ_B * B - PhS # demand for S

        ΔV = PhS * newb * b - µ_V * V
        dB = PhS * tob - µ_B * B
        # if B > 6.0; println(B,dB);end
        if dB > 0.0
            ΔV += dB * b
            ΔB = 0.0
            ΔS = 0.0 - γ * R
        else
            ΔS = 0.95 * dB - γ * R
            ΔB = 0.05 * dB
        end


        # if Sd < 0
        #     # println("more C than sink at PhS $PhS, V $V, B $B")
        #     # Sd = 0
        #     ΔS = 0.0 - γ * S * R
        #     ΔV = 0.0
        #     ΔB = 0.0 #- Sd
        # else
        #     ΔS = - Sd #- μ_S * S
        #     ΔV = 0.0
        #     ΔB = 0.0
        # end
        # Ss = (sink) * Sd / (e + Sd)
        # Ss = Sd * sink2 / (e + sink2) # S supplied
        # Ss = Sd
        # # ΔV = (Ss + PhS) * (V / (V + B)) - μ_V * V
        # ΔV = (Ss + PhS) * μ_V * V / (sink) - μ_V * V
        # # ΔV = (Ss + PhS) * V / (sink2) - μ_V * V
        # ΔS = -Ss # - μ_S * S
        # # ΔB = (Ss + PhS) * (B / (V + B)) - μ_B * B
        # ΔB = (Ss + PhS) * μ_B * B / (sink) - μ_B * B
        # if ΔB > 0.000000000000001
        #     println(V, B, S)
        # end
        # ΔB = (Ss + PhS) * B / (sink2) - μ_B * B

        # ΔR = (g_r * R * (1.0 - R)) * (inh / (inh + γ * S * R))
        host_gro = 1.0 + rep_gro * (B / (V + B))
        ΔR = (g_r * R * (1.0 - R)) * host_gro # (1.0 - 0.5 * (S / (S + inh)))  #* (inh / (inh + γ * S * R))
    
    
        varsout .= [max(V + ΔV, 0.0), max(B + ΔB, 0.0), S + ΔS, R + ΔR] 
    end
    
    function deficit!(varsout::SubArray, varsin::SubArray)
        V, B, S, R = varsin
        PhS = avail * ((resc * lgh / (lgh + 0.05)) * (0.2 * V / (a + 0.2 * V)) ) 
        ΔS = 0.0 - (γ * R)
        ΔB = - (μ_B * B)
        ΔV = - (μ_V * V)

        if PhS > 0.0
            ΔB = PhS - μ_B * B
            # ΔB = PhS - μ_B * B
            # ΔV = μ_V * V
            if ΔB > 0.0
                ΔV = ΔB * b - µ_V * V #- (γ * R)
                ΔB = 0.0
                if ΔV > 0.0
                    ΔS = ΔV - (γ * R)
                    ΔV = 0.0 #PhS - μ_B * B - (μ_V * V)
                end
            end
        end
        # ΔB = min(PhS - μ_B * B, 0.0)
        # ΔV = max(PhS - μ_B * B, 0.0) - (μ_V * V)
        #- μ_S * S
        # ΔR = (g_r * R * (1.0 - R)) * (inh / (inh + γ * S * R))
        host_gro = 1.0 + rep_gro * (B / (V + B))
        ΔR = (g_r * R * (1.0 - R)) * host_gro # (1.0 - 0.5 * (S / (S + inh)))  #* (inh / (inh + γ * S * R))
    
        # ΔB = a * lgh * V - μ_B * B
        # println("deficit: $V, $B, $S, $lgh")
    
        varsout .= [max(V + ΔV, 0.0), max(B + ΔB, 0.0), S + ΔS, R + ΔR] 
    end

    function buds!(vars::SubArray)
        vars[2] = max(lgh * vars[1] * d * vars[3], 0)
        # PhS = avail * ((resc * lgh / (lgh + 0.05)) * V / (a + V)
        # vars[2] = 
        # vars[2] = 0.0
        # vars[2] = (vars[3] / 2.0) / (365.0 - bd)
        # vars[2] = (max(vars[3] - (f * 2.0), 0) / (365 - bd)) # + (a * lgh * vars[1]) / μ_B
    end

    return vegetative!, reproductive!, deficit!, buds!
end


figtest = plot_sun_shade(true, true;
    a=0.2,
    b=0.8,
    c=0.6,
    d=0.25,
    e=0.0,
    f=0.0,
    µ_V=0.01,
    μ_B=0.01,
    μ_S=0.001,
    γ=0.02,
    # veg_gro=0.3,
    rep_gro=0.7,
    Vi=1.0,
    Si=3.0,
    bd=135,
    years=30, lasty=10)

    # a=3.0, b=0.7, d=0.3, e=0.0, f=1.0, μ_B=0.03, Vi=1.0, Si=2.0, bd=120,
    # with avail on 0.3 and c 2.0



function emptyfunction()
end



# rectest = run_once(a = 0.01, b = 0.3, years = 2)

# plot(1:730,rectest[1,:])

# plot59 = plot_sun_shade(false,a=0.01, b=0.2, f=10.0, μ_B=0.5, Vi=1.0, Si=10.0)

# function testveg(vegf, days)
#     records = zeros(4, days)
#     records[1,1] = 0.1
#     records[3,1] = 1.0
#     for d in 2:days
#         @views vegf(records[:, d], records[:, d - 1])
#     end
#     return records
# end

# tfveg! = gen_3stages([0.5, 0.3, 0.7, 0.1, 1.0, 5.0, 1.0, 0.015, 0.1], 182)[1]
# tdays = 300
# tmveg = testveg(tfveg!, tdays)
# plot(1:tdays,tmveg[1,:])


# function monodveg(vout, vin, a, b, l, μ, lgh)
#     V = vin[1]
#     ΔV = (1.1 * lgh / (lgh + l)) * b * (V / (V + a)) - μ * V
#     S = a * lgh * (1 - b) + vin[3]

#     vout .= [V + ΔV, 0.0, S, 0.0]
# end

# function testsingleveg(vegf, days, init)
#     records = zeros(4, days)
#     records[1,1] = init
#     records[3,1] = 1.0
#     for d in 2:days
#         @views vegf(records[:, d], records[:, d - 1], 4.0, 0.3, 0.05, 0.05, 1.0)
#     end
#     return records
# end

# tsdays = 200
# tsmveg = testsingleveg(monodveg, tsdays, 1)
# lines(1:tsdays,tsmveg[1,:])



#= Variables:
- V: vegetative tissue
- B: berries
- S: stored resources
- R: Rust

Fixed Parameters (fpars):
- days: tot days simulated
- bd: blossoming day

Parameters (pars):
- a: photosynthesis "efficiency"
- b: proportion of daily energy to V (in vegetative stage)
- c: proportion of daily energy to S (in vegetative stage)
(b+c=1)
- d: amount of energy from S to B (in investment state)
- e: amount of energy from S to V (in investment state)
- 
- lgh: sunlight %
=#


## Functions

# function generate_f(pars::Vector, fpars::Vector)
#     let bd = fpars[1],

#         a = pars[1]

#         function difeqs(varsout::Vector, varsin::Vector, day::Int)
#             V = varsin[1]
#             B = varsin[2]
#             R = varsin[3]
#             Rust = varsin[4]

#             if isodd(day % bd)
#                 ΔV = 0
#                 ΔB = 0
#                 ΔR = 0
#                 ΔRust = 0
#             elseif iseven(day % bd)
#                 ΔV = 0
#                 ΔB = 0
#                 ΔR = 0
#                 ΔRust = 0
#             end
            
#             varsout .= [V + ΔV, B + ΔB, R + ΔR, Rust + ΔRust]
#         end
#         return difeqs
#     end

# end

# function runone(pars::Vector, fpars::Vector, init::Vector)
#     eqs! = generate_f(pars, fpars)
#     record = zeros(4, fpars[1])
#     record[:, 1] .= init
#     for d in 2:fpars[1]
#         @views eqs!(record[:, d], record[:, d - 1], d)
#     end
#     return record
# end

# function plotonerun(record::Matrix{Float64})
    
# end

# ## Parameters and initial conditions

# pars = [1]
# fpars = [1]
# init = [1, 1, 1, 1]

# ## Run
# record = runone(pars, fpars, init)


# ##

# struct Paramss
#     a::Float64
#     b::Float64
#     d::Float64
#     e::Float64
#     f::Float64
#     μ_B::Float64
#     lgh::Float64
#     bd::Int
#     years::Int
#     Vi::Float64
#     Bi::Float64
#     Si::Float64
#     Ri::Float64
# end

# function genParams(;
#     a::Float64 = 0.1,
#     b::Float64 = 0.5,
#     d::Float64 = 1.0,
#     e::Float64 = 1.0,
#     f::Float64 = 1.0,
#     μ_B::Float64 = 1.0,
#     lgh::Float64 = 1.0,
#     bd::Int = 182,
#     years::Int = 1,
#     Vi::Float64 = 0.1,
#     Bi::Float64 = 0.0,
#     Si::Float64 = 0.0,
#     Ri::Float64 = 0.0)

#     return Paramss(a, b, d, e, f, μ_B, lgh, bd, years, Vi, Bi, Si, Ri)
# end



