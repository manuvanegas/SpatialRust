# Report functions

function agent_type(agent)
    return typeof(agent)
end

function rust_lesions(agent)
    return agent isa Rust ? agent.n_lesions : -1
end

function rust_area(agent)
    return agent isa Rust ? agent.area : -1.0
end

function a_age(agent)
    return agent.age
end

function coffee_prod(agent)
    return agent isa Coffee ? agent.production : -1.0
end

function host_guest(agent)
    return agent.hg_id
end

function x_pos(agent)
    return agent.pos[1]
end

function y_pos(agent)
    return agent.pos[2]
end

## plant selection function

function plant_sampler(df::DataFrame)
    xy_pos = unique(df[(df.agent_type .== "Coffee") .& (5 .< df.x_pos .<= 95) .& (5 .< df.y_pos .<= 95), [:x_pos, :y_pos, :id]])
    # sample size is 10% of coffees within the 5-row limit (= 810)
    # times 2 because of the new sampling in Jan
    selected_ids = sample(xy_pos.id, 1620, replace = false)
    first_half = selected_ids[1:810]
    second_half = selected_ids[811:end]
    sampled = df[(df.step .<= 230) .& ((df.id .∈ Ref(first_half)) .| (df.host_guest .∈ Ref(first_half))), :]
    append!(sampled, df[(df.step .> 230) .& ((df.id .∈ Ref(second_half)) .| (df.host_guest .∈ Ref(second_half))), :])
    return sampled
end

## ABC distance functions
# 1. nlesions, area, prod, both plant sets

# 2. nlesions, area, prod, second plant set only (2018)

# 3. nlesions * area, prod, both sets

# 4. nlesions * area, prod, second set

# 5. same but without prod

function calc_ABC_distances(args)
    body
end



## Run fnc

function run_for_abc(parameters::DataFrameRow,
    rain_data::Vector{Bool},
    temp_data::Vector{Float64},
    when_collect::Vector{Int},
    out_path::String)

    b_map = trues(100, 100)
    #emp_data = true
    steps = length(rain_data)

    model = initialize_sim(; steps = steps, map_dims = 100, shade_percent = 0.0,
    harvest_cycle = 365, start_at = 132, n_rusts = 100,
    farm_map = b_map, rain_data = rain_data, temp_data = temp_data,
    #emp_data = emp_data,
    opt_g_temp = parameters[:opt_g_temp],
    spore_pct = parameters[:spore_pct],
    fruit_load = parameters[:fruit_load],
    uv_inact = parameters[:uv_inact],
    rain_washoff = parameters[:rain_washoff],
    rain_distance = parameters[:rain_distance],
    wind_distance = parameters[:wind_distance])

    areport = [agent_type, a_age, rust_area, rust_lesions, coffee_prod, x_pos, y_pos, host_guest]

    adata, _ = run!(model, pre_step!, agent_step!, model_step!, steps;
                    when = when_collect, adata = areport)
                    #cat ABC-9488559.o | wc -l

    distance_metrics = calc_ABC_distances(adata)

    insertcols!(adata, :par_row => parameters[:RowN])

    outfilepath = string(out_path, "/out_", parameters[:RowN],".csv")
    CSV.write(outfilepath, adata)


    # areas only for the rust.area, not multiplied by n_lesions
    # n.lesions only for the infected ones.


    return true
end
