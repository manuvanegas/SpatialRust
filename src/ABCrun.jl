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

## Run fnc

function run_for_abc(parameters::DataFrameRow,
    rain_data::Vector{Bool},
    temp_data::Vector{Float64},
    when_collect::Vector{Int})

    b_map = trues(100, 100)
    #emp_data = true
    steps = length(rain_data)

    model = initialize_sim(; steps = steps, map_dims = 100, shade_percent = 0.0,
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

    insertcols!(adata, :par_row => parameters[:RowN])

    outfilepath = string("/scratch/mvanega1/ABCraw/out_", parameters[:RowN],".csv")
    CSV.write(outfilepath, adata)


    # areas only for the rust.area, not multiplied by n_lesions
    # n.lesions only for the infected ones.


    return true
end


##
