##Growth

function grow_rust!(model::ABM, rust::Rust, sunlight::Float64, production::Float64, fung::NamedTuple)
    # let (local_temp, growth_modif) = growth_conditions(model, sunlight, production)
    let local_temp = model.current.temperature - (model.pars.temp_cooling * (1.0 - sunlight)),
        # growth_modif = growth_conds(model.pars.fruit_load, production, model.pars.harvest_cycle,
        #     model.pars.opt_g_temp, model.pars.rust_gr, local_temp, fung.growth)
        growth_modif = (1 + model.pars.fruit_load * production * inv(model.pars.harvest_cycle)) *
            (-0.0178 * ((local_temp - model.pars.opt_g_temp) ^ 2.0) + 1.0) * model.pars.rust_gr *
            fung.growth

        # growth_conds(model.pars.fruit_load, production, model.pars.harvest_cycle,
        #     model.pars.opt_g_temp, model.pars.rust_gr, local_temp, model.current.fung_effect)

        @views for lesion in 1:rust.n_lesions
            # rust.n_lesions += grow_each_rust!(rust.state[:, lesion], local_temp, sunlight, production)

            if @inbounds rust.state[1, lesion] == 1.0
                if @inbounds rust.state[3, lesion] == 0.0
                    @inbounds area_growth!(rust.state[:, lesion],local_temp, growth_modif,
                        sporul_conds(rand(model.rng), rust.state[2, lesion], local_temp, fung.spor)
                    )
                else
                    @inbounds area_growth!(rust.state[:, lesion], local_temp, growth_modif, false)
                end
            elseif rand(model.rng) < (sunlight * max(model.pars.uv_inact,
                        (model.current.rain ? model.pars.rain_washoff : 0.0)) )
                        # higher % sunlight means more chances of inactivation by UV or rain
                        if rust.n_lesions > 1
                            rust.n_lesions -= 1
                        else
                            kill_rust!(model, rust)
                        end
            elseif rand(model.rng) < infection_p(local_temp - (model.current.rain ? 6.0 : 0.0), fung.germ)
                @inbounds germinate!(rust.state[:, lesion])
            end
        end
    end
end

function area_growth!(state::SubArray{Float64}, local_temp::Float64, growth_modif::Float64, spor_conds::Bool)
# 1. germinated
# 2. area
# 3. spores
# 4. age
    if @inbounds state[4] < 500
        @inbounds state[4] += 1.0
    end
    if 14.0 < local_temp < 30.0 # grow and sporulate

        #  logistic growth (K=1) * rate due to fruit load * rate due to temperature
        @inbounds state[2] += state[2] * (1 - state[2]) * growth_modif
        if @inbounds state[2] > 1.0
            @inbounds state[2] = 1.0
        end

        if spor_conds
            state[3] = 1.0
        end
    end
end

function sporul_conds(r::Float64, area::Float64, temp::Float64, fung::Float64)::Bool
    r < ((area * (temp + 5.0) * inv(30.0)) * fung) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
end

function germinate!(state::SubArray{Float64})
    # println(typeof(state))
    # println(state)
    @inbounds state[1] = 1.0
    @inbounds state[2] = 0.0002
    @inbounds state[4] = 0.0
end

# Secondary and other helper functions

## Rust growth

# function parasitism!(cof::Coffee, rust::Rust, pars::Parameters)
#     # rust = model[cof.hg_id]
#     cof.area = 1.0 - (sum(rust.area) / pars.max_lesions)
#     if (sum(rust.area) / pars.max_lesions) >= pars.exhaustion
#         cof.area = 0.0
#         cof.exh_countdown = (pars.harvest_cycle * 2) + 1
#         # kill_rust!(model, rust, cof)
#         return rust
#     end
#     return nothing
# end

function calc_wetness_p(local_temp)
    w = (-0.5/16.0) * local_temp + (0.5*30.0/16.0)
end

function infection_p(local_temp::Float64, fung::Float64)::Float64
    w = calc_wetness_p(local_temp) * fung
end

## Parasitism

function parasitize!(model::ABM, rust::Rust, cof::Coffee)

    # if any(rust.germinated)
        # bal = rust.area + (rust.n_lesions / 25.0) # between 0.0 and 2.0
    # # cof.progression = 1 / (1 + (0.75 / bal)^4)
    #     prog = 1 / (1 + (0.25 / bal)^4) # Hill function with steep increase
    #     cof.area = 1.0 - prog
    # r_area = (sum(@view rust.state[2,:])) * inv(model.pars.max_lesions)
    r_area = rel_rusted_area(rust, model.pars.max_lesions)
    cof.area = 1.0 - r_area
        # cof.area = 1.0 - (sum(rust.state[2, :]) / model.pars.max_lesions)

        # # if rust.area * rust.n_lesions >= model.pars.exhaustion #|| bal >= 2.0

        if r_area >= model.pars.exhaustion
        # if (sum(rust.state[2, :]) / model.pars.max_lesions) >= model.pars.exhaustion
            cof.area = 0.0
            # assumes coffee is immediately replaced, but it takes 2 1/2 years to start to produce again
            cof.exh_countdown = 731
            kill_rust!(model, rust)
        end
    # end
end

## Helpers

function rel_rusted_area(rust::Rust, lesions::Int)::Float64
    return sum(@view rust.state[2,:]) * inv(lesions)
end

function kill_rust!(model::ABM, rust::Rust, cof::Coffee)
    cof.hg_id = 0
    rm_id = rust.id
    delete!(model.agents, rust.id)
    @inbounds deleteat!(model.space.s[rust.pos...], 2)
    @inbounds deleteat!(model.current.rusts, findfirst(i -> i.id == rm_id, model.current.rusts))
end

kill_rust!(model, rust::Rust) = kill_rust!(model, rust, model[rust.hg_id])

function growth_conds(fruit_load::Float64, production::Float64, harvest_cycle::Int,
    opt_g_temp::Float64, rust_gr::Float64, local_temp::Float64, fung::Float64)::Float64
    # fung = fungicide > 0 ? 0.98 : 1.0
    return fung * (1 + fruit_load * production * inv(harvest_cycle)) *
        (-0.0178 * ((local_temp - opt_g_temp) ^ 2.0) + 1.0) * rust_gr
end
