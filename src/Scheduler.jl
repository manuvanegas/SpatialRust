function custom_scheduler(model::ABM)
    return vcat(model.current.shade_ids, model.current.coffee_ids, shuffle(model.rng, model.current.rust_ids))
end

function step_model!(model::ABM)
    pre_step!(model)

    for shade_i in model.current.shade_ids
        shade_step!(model.agents[shade_i], model)
    end

    for cof_i in model.current.coffee_ids
        coffee_step!(model.agents[cof_i], model)
    end

    for rust_i in shuffle(model.rng, model.current.rust_ids)
        rust_step!(model.agents[rust_i], model)
    end

    # for agent in custom_scheduler(model)
    #     agent_step!(model.agents[agent], model)
    # end

    model_step!(model)
end

function Agents.multi_agent_types!(
    types::Vector{Vector{T} where T},
    utypes::Tuple,
    model::ABM,
    properties::AbstractArray,
)
    types[3] = Symbol[]

    for (i, k) in enumerate(properties)
        current_types = DataType[]
        for atype in utypes
            allatype = Iterators.filter(a -> a isa atype, allagents(model))
            if !isempty(allatype)
                a = first(allatype)
            else
                a = atype(1, (1,1), 0.2, 1.0, 1, 1)
            end
            if k isa Symbol
                current_type =
                    hasproperty(a, k) ? typeof(Agents.get_data(a, k, identity)) : Missing
            else
                current_type = try
                        typeof(get_data(a, k, identity))
                catch
                    Missing
                end
            end

            isconcretetype(current_type) || warn(
                "Type is not concrete when using $(k) " *
                "on $(atype) agents. Consider narrowing the type signature of $(k).",
            )
            push!(current_types, current_type)
        end
        unique!(current_types)
        if length(current_types) == 1
            current_types[1] <: Missing &&
                error("$(k) does not yield a valid agent property.")
            types[i+3] = current_types[1][]
        else
            types[i+3] = Union{current_types...}[]
        end
    end
end
