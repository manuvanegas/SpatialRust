##Growth
function r_germinate!(rust::Coffee, rng, rustpars::RustPars, local_temp::Float64, fung::Float64)
    # No fungicide - Rain version of germinate!
    # There is substantial code duplication, but it was put in place to minimize innecessary
    # checks of global conditions (eg, rain will be true for all rusts on a given day)
    # See if deposited spores are inhibited/washed off, if not, see if they germinate+penetrate tissue
    if rust.deposited >= 1.0
        let inhib = rust.sunlight * rustpars.light_inh,
            washed = rust.sunlight * rustpars.rain_washoff,
            max_nl = rustpars.max_lesions
            if rust.n_lesions < max_nl
                temp_inf_p = 0.015625 * (local_temp - 22.0)^2.0 + 1.0
                wet_inf_p = 0.05 * (18.0 + 2.0 * rust.sunlight) - 0.2
                infection_p = rustpars.max_inf * temp_inf_p * wet_inf_p * fung

                # for (d, sp) in enumerate(rust.deposited), s in 1:sp
                #     if rand(rng) < inhib || rand(rng) < washed
                #         @inbounds rust.deposited[d] -= 1
                #     elseif rand(rng) < infection_p
                #         nl = rust.n_lesions += 1
                #         @inbounds rust.deposited[d] -= 1
                #         @inbounds rust.ages[nl] = 0
                #         @inbounds rust.areas[nl] = 0.00014
                #         # Make sure n_lesions is never > max
                #         if rust.n_lesions == rustpars.max_lesions
                #             break
                #         end
                #     end
                # end
                for sp in 1.0:rust.deposited
                    if rand(rng) < inhib || rand(rng) < washed
                        rust.deposited -= 1.0
                    elseif rust.n_lesions < max_nl && rand(rng) < infection_p
                        rust.deposited -= 1.0
                        nl = rust.n_lesions += 1
                        @inbounds rust.ages[nl] = 0
                        @inbounds rust.areas[nl] = 0.00014
                    end
                end
            else
                for sp in 1.0:rust.deposited
                    if rand(rng) < inhib || rand(rng) < washed
                        rust.deposited -= 1.0
                    end
                end
            end
        end
    end
end

function nr_germinate!(rust::Coffee, rng, rustpars::RustPars, local_temp::Float64, fung::Float64)
    # No fungicide - No rain version of germinate!()
    # See nf_r_germinate!() for more details/explanations
    if rust.deposited >= 1.0
        let inhib = rust.sunlight * rustpars.light_inh,
            max_nl = rustpars.max_lesions
            if rust.n_lesions < rustpars.max_lesions 
                temp_inf_p = 0.015625 * (local_temp - 22.0)^2.0 + 1.0
                wet_inf_p = 0.05 * (12.0 + 2.0 * rust.sunlight) - 0.2
                infection_p = rustpars.max_inf * temp_inf_p * wet_inf_p * fung

                # for (d, sp) in enumerate(rust.deposited), s in 1:sp
                #     if rand(rng) < inhib
                #         @inbounds rust.deposited[d] -= 1
                #     elseif rand(rng) < infection_p
                #         nl = rust.n_lesions += 1
                #         @inbounds rust.ages[nl] = 0
                #         @inbounds rust.areas[nl] = 0.00014
                #         if rust.n_lesions == rustpars.max_lesions
                #             break
                #         end
                #     end
                # end
                for sp in 1.0:rust.deposited
                    if rand(rng) < inhib
                        rust.deposited -= 1.0
                    elseif rust.n_lesions < max_nl && rand(rng) < infection_p
                        rust.deposited -= 1.0
                        nl = rust.n_lesions += 1
                        @inbounds rust.ages[nl] = 0
                        @inbounds rust.areas[nl] = 0.00014
                    end
                end
            else
                for sp in 1.0:rust.deposited
                    if rand(rng) < inhib
                        rust.deposited -= 1.0
                    end
                end
            end
        end
    end
end

function grow_rust!(rust::Coffee, rng, rustpars::RustPars, local_temp::Float64, fday::Int)
    # No fungicide version of rust growth
    # All rusts age 1 day
    rust.ages .+= 1
    # Temperature-dependent growth modifier. If <= 0, there is no growth or sporulation
    # For non sporulated lesions, see if spor happens, then update total and sporulated areas
    temp_mod = -(1.0/(rustpars.max_g_temp - rustpars.opt_g_temp)) * (local_temp - rustpars.opt_g_temp)^2.0 + 1.0
    if temp_mod > 0
        let spor_mod = temp_mod * rustpars.host_spo_inh / (rustpars.host_spo_inh + rust.storage),
            host_gro = rustpars.veg_gro + rustpars.rep_gro * rust.production / (rust.production + rust.veg),
            growth_mod = rustpars.rust_gr * temp_mod * host_gro,
            nls = rust.n_lesions #BENCH (wont need nls if only used once)
            
            for (nl, spo) in enumerate(@views(@inbounds(rust.spores[1:nls])))
            # for nl in 1:nls
                if !spo && rand(rng) < @inbounds rust.areas[nl] * spor_mod
                    @inbounds rust.spores[nl] = true
                end
            end
            # update total lesion areas
            # @simd @fastmath
            rust.areas .+= rust.areas .* (1 .- rust.areas) .* growth_mod
            # @views(@inbounds(rust.areas[1:nls] .+= rust.areas[1:nls] .* (1 .- rust.areas[1:nls]) .* growth_mod)) #BENCH 
            # update sporulated area
            # rust.spores .= rust.spores .* rust.areas .* rustpars.spore_pct
        end
    end
end

function grow_f_rust!(rust::Coffee, rng, rustpars::RustPars, local_temp::Float64, fday::Int)
    # Fungicide version of rust growth. See grow_rust for more details
    # This version has vectors for growth and sporulation modifiers because preventative vs curative 
    # fungicide effects are different (some lesions can be older, some younger, than last fung spraying)
    rust.ages .+= 1
    temp_mod = -(1.0/(rustpars.max_g_temp - rustpars.opt_g_temp)) * (local_temp - rustpars.opt_g_temp)^2.0 + 1.0
    if temp_mod > 0
        let nls = rust.n_lesions,
            spor_mod = temp_mod * rustpars.host_spo_inh / (rustpars.host_spo_inh + rust.storage),
            host_gro = rustpars.veg_gro + rustpars.rep_gro * rust.production / (rust.production + rust.veg),
            growth_mod = rustpars.rust_gr * temp_mod * host_gro,
            prev_cur = rust.ages .< fday,
            spor_probs = rust.areas .* spor_mod .* ifelse.(prev_cur, rustpars.fung_spor_prev, rustpars.fung_spor_cur),
            gro_mods = growth_mod .* ifelse.(prev_cur, rustpars.fung_gro_prev, rustpars.fung_gro_cur)
            # @views(prev_cur = @inbounds rust.ages[1:nls] .< fday),
            # @views(spor_probs = @inbounds rust.area[1:nls] .* spor_mod .* ifelse.(prev_cur, rustpars.fung_spor_prev, rustpars.fung_spor_cur)),
            # @views(gro_mods = @inbounds growth_mod[1:nls] .* ifelse.(prev_cur, rustpars.fung_gro_prev, rustpars.fung_gro_cur))

            for (nl, spo) in enumerate(@views(@inbounds(rust.spores[1:nls])))
                if !spo && rand(rng) < @inbounds spor_probs[nl]
                    @inbounds rust.spores[nl] = true
                end
            end
            rust.areas .=+ rust.areas .* (1 .- rust.areas) .* gro_mods
            # @views(@inbounds(rust.areas[1:nl] .+= rust.areas[1:nl] .* (1 .- rust.areas[1:nl]) .* gro_mods)) # BENCH 
            # update sporulated area
            # rust.spores .= rust.spores .* rust.areas .* rustpars.spore_pct
        end
    end
end

## Parasitism

function parasitize!(rust::Coffee, rustpars::RustPars, rusts::Set{Coffee})
    rust.storage -= rustpars.rust_paras * sum(rust.areas)

    if rust.storage < 0 && rust.veg < rustpars.exh_threshold
        rust.veg = 0
        rust.production = 0
        rust.exh_countdown = rustpars.exh_countdown
        # fill!(rust.deposited, 0)
        rust.deposited = 0.0
        rust.n_lesions = 0
        fill!(rust.ages, rustpars.steps + 1)
        fill!(rust.areas, 0.0)
        fill!(rust.spores, false)
        @inbounds farm_map[rust.pos...] = 0
    end

    if rust.deposited < 0.1 
        rust.deposited == 0.0
        if rust.n_lesions == 0
            delete!(rusts, rust)
        end
    end
end


# function area_growth!(state::SubArray{Float64}, local_temp::Float64, growth_modif::Float64, spor_conds::Bool)
# # 1. germinated - "Bool"
# # 2. area - Float64 (only real one)
# # 3. spores - "Bool"
# # 4. age - "Int"
#     if @inbounds state[4] < 500.0
#         @inbounds state[4] += 1.0
#     end
#     if 14.0 < local_temp < 30.0 # grow and sporulate

#         #  logistic growth (K=1) * rate due to fruit load * rate due to temperature
#         @inbounds state[2] += state[2] * (1 - state[2]) * growth_modif
#         if @inbounds state[2] > 1.0
#             @inbounds state[2] = 1.0
#         end

#         if spor_conds
#             state[3] = 1.0
#         end
#     end
# end

# function sporul_conds(r::Float64, area::Float64, temp::Float64, fung::Float64)::Bool
#     r < ((area * (temp + 5.0) * inv(30.0)) * fung) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
# end

# function colonize!(state::SubArray{Float64})
#     # println(typeof(state))
#     # println(state)
#     @inbounds state[1] = 1.0
#     @inbounds state[2] = 0.00014
#     @inbounds state[4] = 0.0
# end

## Helpers

# function calc_wetness_p(local_temp)
#     w = (-0.5/16.0) * local_temp + (0.5*30.0/16.0)
# end

# function infection_p(local_temp::Float64, fung::Float64)::Float64
#     w = calc_wetness_p(local_temp) * fung
# end

## Parasitism

# function parasitize!(rust::Rust, rustpars::RustPars)
    # # if any(rust.germinated)
    #     # bal = rust.area + (rust.n_lesions / 25.0) # between 0.0 and 2.0
    # # # cof.progression = 1 / (1 + (0.75 / bal)^4)
    # #     prog = 1 / (1 + (0.25 / bal)^4) # Hill function with steep increase
    # #     cof.area = 1.0 - prog
    # # r_area = (sum(@view rust.state[2,:])) * inv(model.pars.max_lesions)
    # r_area = rel_rusted_area(rust, pars.max_lesions)
    # cof.area = 1.0 - r_area
    #     # cof.area = 1.0 - (sum(rust.state[2, :]) / model.pars.max_lesions)

    #     # # if rust.area * rust.n_lesions >= model.pars.exhaustion #|| bal >= 2.0

    #     if r_area >= pars.exhaustion
    #     # if (sum(rust.state[2, :]) / model.pars.max_lesions) >= model.pars.exhaustion
    #         cof.area = 0.0
    #         cof.production = 0.0
    #         # assumes coffee is immediately replaced, but it takes years to start to produce again
    #         cof.exh_countdown = pars.exh_countdown
    #         kill_rust!(model, rust)
    #     end
    # # end
# end

## Helpers

# function rel_rusted_area(rust::Rust, lesions::Int)::Float64
#     return sum(@view rust.state[2,:]) * inv(lesions)
# end

# function kill_rust!(model::ABM, rust::Rust, cof::Coffee)
#     cof.hg_id = 0
#     rm_id = rust.id
#     delete!(model.agents, rust.id)
#     @inbounds deleteat!(model.space.s[rust.pos...], 2)
#     @inbounds deleteat!(model.current.rusts, findfirst(i -> i.id == rm_id, model.current.rusts))
# end

# kill_rust!(model, rust::Rust) = kill_rust!(model, rust, model[rust.hg_id])

# function growth_conds(fruit_load::Float64, production::Float64, harvest_day::Int,
#     opt_g_temp::Float64, rust_gr::Float64, local_temp::Float64, fung::Float64)::Float64
#     # fung = fungicide > 0 ? 0.98 : 1.0
#     return fung * (1 + fruit_load * production * inv(harvest_day)) *
#         (-0.0178 * ((local_temp - opt_g_temp) ^ 2.0) + 1.0) * rust_gr
# end # not in use
