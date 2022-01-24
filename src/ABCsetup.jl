function simulate_fullsun(p_row::DataFrameRow,
        rain_data::Vector{Bool},
        temp_data::Vector{Float64},
        when_collect::Vector{Int},
        out_path::String,
        wind_prob::Float64)
    pars = Parameters(
        steps = 456,
        map_dims = 100,
        start_at = 132
        n_rusts = 100,
        opt_g_temp = p_row[:opt_g_temp],
        spore_pct = p_row[:spore_pct],
        fruit_load = p_row[:fruit_load],
        uv_inact = p_row[:uv_inact],
        rain_washoff = p_row[:rain_washoff],
        rain_distance = p_row[:rain_distance],
        wind_distance = p_row[:wind_distance])

    weather = Weather(rain_data, rand(Float64, steps) .< wind_prob, temp_data)

    model = init_spatialrust(pars, create_fullsun_farm_map(), weather)

    "weather [1:n]"



end

## selecting sampled locations for each cycle

function custom_sampling!(model::ABM, percent::Float64, half::Int)
    n_persample = floor(Int, length(model.current.coffee_ids) * percent)
    # central_coffees = filter(id -> all(5 .< model[id].pos .<= 95), model.current.coffee_ids)
    first_ids = sample(model.rng, filter(id -> all(5 .< model[id].pos .<= 95), model.current.coffee_ids), n_persample, replace = false)
    sampled_coffees = hcat(first_ids, zeros(Int, n_persample, (3 * half))) # 1 half requires 3 neighs, 2 half reqs 6
    for (i, id) in enumerate(first_ids)
        model[id].sample_cycle = 1
        c = 2
        for neigh in select_s_neighbors(model, sampled_coffees, id)
            push!(model[neigh].sample_cycle, c)
            sampled_coffees[i, c] = neigh
            c += 1
            c > (3 * half) + 1 && break
        end
        if c < (3 * half) + 1
            for add_neigh in complete_s_neighbors(model, sampled_coffees, id, i, c) #relax requirements
                push!(model[add_neigh].sample_cycle, c)
                sampled_coffees[i, c] = add_neigh
                c += 1
                c > (3 * half) + 1 && break
            end
        end
    end
end

function select_s_neighbors(model::ABM, sampled_coffees::Array{Int,2}, c_id::Int)::Vector{Int}
    return sampled_neighs = shuffle(model.rng, collect(Iterators.filter(x -> model[x] isa Coffee && x ∉ sampled_coffees,
        nearby_ids(model[c_id], model, 2))))
end

function complete_s_neighbors(model::ABM, sampled_coffees::Array{Int,2}, c_id::Int, i::Int, c::Int)
    return shuffle(model.rng, collect(Iterators.filter(x -> model[x] isa Coffee &&
        x ∉ sampled_coffees[i,:] && x ∉ sampled_coffees[:,c], nearby_ids(model[c_id], model, 2))))
end
