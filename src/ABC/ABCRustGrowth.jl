## Growth

# No fungicide version of rust growth
function grow_rust!(rust::Coffee, rng::Xoshiro, rustpars::RustPars, local_temp::Float64, rain_spo::Float64, fday::Int)
    # Senescence after ~5 months (McCain & Hennen, 1984)
    rmrusts = findall(>(150), rust.ages)
    if !isnothing(rmrusts)
        nl = rust.n_lesions -= length(rmrusts)
        deleteat!(rust.ages, rmrusts)
        deleteat!(rust.areas, rmrusts)
        deleteat!(rust.spores, rmrusts)
    end
    # All rusts age 1 day
    @fastmath rust.ages .+= 1
    # Temperature-dependent growth modifier. If <= 0, there is no growth or sporulation
    # temp_mod = -(1.0/(rustpars.max_g_temp - rustpars.opt_g_temp)^2) * (local_temp - rustpars.opt_g_temp)^2.0 + 1.0
    temp_mod = (rustpars.temp_ampl_c * (local_temp - rustpars.opt_temp)^2.0 + 1.0) - 0.1 * rust.sunlight
    if temp_mod > 0.0
        # spor_mod = temp_mod * rain_spo * (1.0 + rustpars.host_spo_inh * (rust.production / (rust.production + rust.veg)))
        spor_mod = temp_mod * rain_spo * (1.0 + rustpars.rep_spo * (rust.production / (rust.production + rust.veg)))
        host_gro = 1.0 + rustpars.rep_gro * (rust.production / max(rust.storage, 1.0))
        growth_mod = rust.rust_gr * temp_mod * host_gro
        
        # For non sporulated lesions, see if spor happens, then update total areas
        areas = rust.areas
        spores = rust.spores
        # @fastmath @inbounds @simd for nl in eachindex(spores)
            # spores[nl] = spores[nl] || (rand(rng) < areas[nl] * spor_mod)
        for nl in findeach(!, spores)
            if (rand(rng) < areas[nl] * spor_mod)
                spores[nl] = true 
                push!(rust.lp, rust.ages[nl])
            end
            # @views spores[nl] = rand(rng) < areas[nl] * spor_mod
        end
        # update total lesion areas
        # @fastmath rust.areas .+= rust.areas .* (1.0 .- rust.areas) .* growth_mod
        area_gro = max(0.0, 1.0 - sum(areas) / 25.0)
        @fastmath areas .+= areas .* (growth_mod * area_gro)

        clamp!(areas, 0.0, 7.0) # (McCain & Hennen, 1984)

        # If active, update ABC sentinel leaves
        # if rust.sentinel.active
        #     sent = rust.sentinel
        #     # sent.ages .+= 1
        #     sent_areas = sent.areas
        #     for nl in findeach(!, sent.spores)
        #         @views sent.spores[nl] = rand(rng) < sent_areas[nl] * spor_mod
        #     end
        #     sent_area_gro = max(0.0, 1.0 - sum(sent_areas) / 25.0)
        #     @fastmath sent_areas .+= sent_areas .* (growth_mod * sent_area_gro)
        # end
    end
end

# https://github.com/JuliaLang/julia/issues/43737
findeach(f::Function, A) = (first(p) for p in pairs(A) if f(last(p)))

# Fungicide version of rust growth. See grow_rust for more details
# function grow_f_rust!(rust::Coffee, rng, rustpars::RustPars, local_temp::Float64, rain_spo::Float64, fday::Int)
#     # This version has vectors for growth and sporulation modifiers because preventative vs curative 
#     # fungicide effects are different (some lesions can be older, some younger, than last fung spraying)
#     @fastmath rust.ages .+= 1
#     temp_mod = -(1.0/(rustpars.max_g_temp - rustpars.opt_g_temp)^2) * (local_temp - rustpars.opt_g_temp)^2.0 + 1.0
#     # temp_mod = rustpars.temp_ampl_c * (local_temp - rustpars.opt_temp)^2.0 + 1.0
#     if temp_mod > 0.0
#         areas = rust.areas
#         spores = rust.spores
#         spor_mod = temp_mod * rain_spo * (1.0 - rustpars.host_spo_inh + rustpars.host_spo_inh * (rust.production / (rust.production + rust.veg)))
#         # spor_mod = temp_mod * rain_spo * (1.0 + - rustpars.rep_spo rustpars.rep_spo * (rust.production / max(rust.storage, 1.0))
#         host_gro = 1.0 + rustpars.rep_gro * (rust.production / max(rust.storage, 1.0))
#         growth_mod = rust.rust_gr * temp_mod * host_gro
#         # prev_cur = rust.ages .< fday
#         # spor_probs = areas .* spor_mod .* ifelse.(prev_cur, rustpars.fung_spor_prev, rustpars.fung_spor_cur)
#         spor_probs = (spor_mod * ifelse(last(p) < fday, rustpars.fung_spor_prev, rustpars.fung_spor_cur) for p in pairs(rust.ages) if !spores[first(p)])
#         # gro_mods = growth_mod .* ifelse.(prev_cur, rustpars.fung_gro_prev, rustpars.fung_gro_cur)
#         gro_mods = (growth_mod * ifelse(p < fday, rustpars.fung_gro_prev, rustpars.fung_gro_cur) for p in rust.ages)
#         # for (nl, spo) in enumerate(spores)
#         #     if !spo && rand(rng) < @inbounds spor_probs[nl]
#         #         @inbounds spores[nl] = true
#         #     end
#         # end
#         for (nl, sp_prob) in zip(findeach(!, spores), spor_probs)
#             @views spores[nl] = rand(rng) < areas[nl] * sp_prob
#         end
#         # @fastmath rust.areas .+= rust.areas .* (1.0 .- rust.areas) .* gro_mods
#         # @views(@inbounds(rust.areas[1:nls] .+= rust.areas[1:nls] .* (1 .- rust.areas[1:nls]) .* gro_mods)) 
#         area_gro = max(0.0, 1.0 - sum(areas) / 25.0)
#         areas .+= areas .* (gro_mods .* area_gro)
#     end
# end

## Germination+Infection

function r_germinate!(rust::Coffee, rng, rustpars::RustPars, local_temp::Float64, fung::Float64)
    # Rain version of germinate!
    # There is substantial code duplication, but it was put in place to minimize innecessary
    # checks of global conditions (eg, rain will be true for all rusts on a given day)
    # See if deposited spores are inhibited/washed off, if not, see if they germinate+penetrate tissue
    if (deps = rust.deposited) >= 1.0
        inhib = rust.sunlight * rustpars.light_inh
        washed = rust.sunlight * rustpars.rain_washoff
        max_nl = rustpars.max_lesions
        if rust.n_lesions < max_nl
            temp_inf_p = 1.0 - (0.0137457 * (local_temp - 21.5) ^ 2.0)
            wet_inf_p = 0.05 * (18.0 + 2.0 * rust.sunlight) - 0.2
            # host = 1.0 + (rust.production / (rust.production + rust.veg)) * rustpars.host_spo_inh
            host = 1.0 - rustpars.rep_inf + (rust.production / (rust.production + rust.veg)) * rustpars.rep_inf 
            infection_p = rustpars.max_inf * temp_inf_p * wet_inf_p * host * fung

            sp = 0.0
            while sp <= deps
                if rand(rng) < inhib || rand(rng) < washed
                    rust.deposited -= 1.0
                elseif rust.n_lesions < max_nl && rand(rng) < infection_p
                    rust.deposited -= 1.0
                    rust.n_lesions += 1
                    push!(rust.ages, 0)
                    push!(rust.areas, 0.00005)
                    push!(rust.spores, false)
                    # rust.sentinel.active && track_lesion!(rust.sentinel)
                end
                sp += 1.0
            end
        else
            sp = 0.0
            while sp <= deps
                if rand(rng) < inhib || rand(rng) < washed
                    rust.deposited -= 1.0
                end
                sp += 1.0
            end
        end
    end
end

function nr_germinate!(rust::Coffee, rng, rustpars::RustPars, local_temp::Float64, fung::Float64)
    # No-rain version of germinate!()
    # See r_germinate!() for more details/explanations
    if (deps = rust.deposited) >= 1.0
        inhib = rust.sunlight * rustpars.light_inh
        max_nl = rustpars.max_lesions
        if rust.n_lesions < max_nl
            temp_inf_p = 1.0 - (0.0137457 * (local_temp - 21.5) ^ 2.0)
            wet_inf_p = 0.05 * (12.0 + 2.0 * rust.sunlight) - 0.2
            # host = 1.0  + (rust.production / (rust.production + rust.veg)) * rustpars.host_spo_inh
            host = 1.0 - rustpars.rep_inf + (rust.production / (rust.production + rust.veg)) * rustpars.rep_inf 
            infection_p = rustpars.max_inf * temp_inf_p * wet_inf_p * host * fung

            sp = 0.0
            while sp <= deps
                if rand(rng) < inhib
                    rust.deposited -= 1.0
                elseif rust.n_lesions < max_nl && rand(rng) < infection_p
                    rust.deposited -= 1.0
                    rust.n_lesions += 1
                    push!(rust.ages, 0)
                    push!(rust.areas, 0.00005)
                    push!(rust.spores, false)
                    # rust.sentinel.active && track_lesion!(rust.sentinel)
                end
                sp += 1.0
            end
        else
            sp = 0.0
            while sp <= deps
                if rand(rng) < inhib
                    rust.deposited -= 1.0
                end
                sp += 1.0
            end
        end
    end
end

## Parasitism

# function parasitize!(rust::Coffee, rustpars::RustPars, rusts::Set{Coffee})
function parasitize!(rust::Coffee, rustpars::RustPars, farm_map::Array{Int, 2})
    stor = rust.storage -= (rustpars.rust_paras * sum(rust.areas))

    if stor < -10.0
        rust.production = 0.0
        rust.exh_countdown = rustpars.exh_countdown
        rust.newdeps = 0.0
        rust.deposited = 0.0
        rust.n_lesions = 0
        empty!(rust.ages) 
        empty!(rust.areas)
        empty!(rust.spores)
        @inbounds farm_map[rust.pos...] = 0
        # rust.sentinel.active = false
        # rust.sentinel.n_lesions = 0
        # # empty!(rust.sentinel.ages)
        # empty!(rust.sentinel.areas)
        # empty!(rust.sentinel.spores)
    end
end

# End-of-day update

# function update_rusts!(rust::Coffee, farm_map::Array{Int, 2}, rustpars::RustPars)
#     stor = rust.storage -= (rustpars.rust_paras * sum(rust.areas))
#
#     if stor < -10.0 || (stor < 0.0 && rust.veg <= rustpars.exh_thresh)
#         rust.production = 0.0
#         rust.exh_countdown = rustpars.exh_countdown
#         rust.newdeps = 0.0
#         rust.deposited = 0.0
#         rust.n_lesions = 0
#         # fill!(rust.ages, rustpars.reset_age)
#         # fill!(rust.areas, 0.0)
#         # fill!(rust.spores, false)
#         empty!(rust.ages)
#         empty!(rust.areas)
#         empty!(rust.spores)
#         @inbounds farm_map[rust.pos...] = 0
#         # delete!(rusts, rust)
#         rust.rusted = false
#         rust.sentinel.active = false
#         rust.sentinel.n_lesions = 0
#         empty!(rust.sentinel.ages)
#         empty!(rust.sentinel.areas)
#         empty!(rust.sentinel.spores)
#     else
#         rust.deposited = rust.deposited * 0.65 + rust.newdeps # Nutman et al, 1963
#         rust.newdeps = 0.0
#         if rust.deposited < 0.05
#             rust.deposited = 0.0
#             if rust.n_lesions == 0
#                 # delete!(rusts, rust)
#                 rust.rusted = false
#             end
#         end
#     end
# end

# function update_rust!(rust::Coffee)
function update_rust!(rust::Coffee, viab::Float64)
    if rust.exh_countdown > 0
        rust.rusted = false
    else
        # rust.deposited = rust.deposited * 0.75 + rust.newdeps # Nutman et al, 1963
        rust.deposited = rust.deposited * viab + rust.newdeps # Nutman et al, 1963

        rust.newdeps = 0.0
        if rust.deposited < 0.05
            rust.deposited = 0.0
            if rust.n_lesions == 0
                rust.rusted = false
            end
        end
    end
end

