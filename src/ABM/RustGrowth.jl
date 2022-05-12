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
    r < ((area * (temp + 5.0) / 30.0) * fung) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
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

function kill_rust!(model::ABM, rust::Rust, cof::Coffee)
    cof.hg_id = 0
    rm_id = rust.id
    delete!(model.agents, rust.id)
    @inbounds deleteat!(model.space.s[rust.pos...], 2)
    @inbounds deleteat!(model.current.rust_ids, findfirst(i -> i == rm_id, model.current.rust_ids))
end

# kill_rust!(model::ABM, nothing) = nothing

# kill_rust!(model::ABM, ru::Int) = kill_rust!(model, model[ru])

kill_rust!(model, rust::Rust) = @inbounds kill_rust!(model, rust, model[rust.hg_id])
