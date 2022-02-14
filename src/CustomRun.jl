function custom_abc_run!(
    model::ABM,
    agent_step!,
    model_step!,
    n;
    when::Vector{Int},
    when_cycle::Vector{Int},
    stepdata,
    substepdata,
    cycledata,
    sampler::Sampler,
    obtainer = identity,
    agents_first::Bool = true
)::NTuple{3, DataFrame}

    df_step = custom_init_model_dataframe(model, stepdata)
    df_substep = custom_init_model_dataframe(model, substepdata)
    df_cycle = custom_init_model_dataframe(model, cycledata)


    s = 0
    while Agents.until(s, n, model)
        if should_we_collect(s, model, when_cycle)
            if s != 16
                sampler.cycle[1] += 1
            end
            custom_collect_model_data!(df_cycle, model, cycledata, sampler, s; obtainer)
            #println(s)
            #println(sampler.cycle[1])
        end
        if should_we_collect(s, model, when)
            update_r_sampling!(model, sampler)
            custom_collect_model_data!(df_step, model, stepdata, sampler, s; obtainer)
            custom_collect_model_data!(df_substep, model, substepdata, sampler, s; obtainer)
        end
        step!(model, agent_step!, model_step!, 1, agents_first)
        s += 1
    end
    if should_we_collect(s, model, when)
        custom_collect_model_data!(df_step, model, stepdata, sampler, s; obtainer)
        custom_collect_model_data!(df_substep, model, substepdata, sampler, s; obtainer)
    end
    if should_we_collect(s, model, when_cycle)
        custom_collect_model_data!(df_cycle, model, cycledata, sampler, s; obtainer)
    end
    return df_step, df_substep, df_cycle
end


function custom_init_model_dataframe(model::ABM, properties::Vector)
    headers = Vector{String}(undef, 1 + length(properties))
    headers[1] = "step"
    for i in 1:length(properties)
        headers[i+1] = dataname(properties[i])
    end

    types = Vector{Vector}(undef, 1 + length(properties))
    types[1] = Int[]
    for (i, k) in enumerate(properties)
        current_type = typeof(k(model))
        isconcretetype(current_type) || warn(
            "Type is not concrete when using $(k)" *
            "on the model. Considering narrowing the type signature of $(k).",
        )
        types[i+1] = current_type[]
    end
    DataFrame(types, headers)
end

function custom_collect_model_data!(
    df,
    model,
    properties::Vector,
    sampler::Sampler,
    step::Int = 0;
    obtainer = identity,
)
    push!(df[!, :step], step)
    for (col, fn) in enumerate(properties)
        new_data = fn(model, sampler)
        if new_data isa Real
            push!(df[!, dataname(fn)], new_data)
        elseif new_data isa Array
            ags = try
                size(new_data)[2]
            catch
                1
            end
            #println(ags)
            push!(df[!, col + 1], new_data[1, 1])
            push!(df[!, col + 2], new_data[2, 1])
            if ags > 1
                for i in 2:ags
                    push!(df[!, :step], step)
                    push!(df[!, col + 1], new_data[1, i])
                    push!(df[!, col + 2], new_data[2, i])
                end
            end
        end
    end
    return df
end



# function init_custom_agent_dataframe(
#     model::ABM{S,A},
#     properties::Vector{<:Tuple},
# ) where {S,A<:AbstractAgent}
#     nagents(model) < 1 && throw(ArgumentError(
#         "Model must have at least one agent to " * "initialize data collection",
#     ))
#     headers = Vector{String}(undef, 1 + length(properties))
#     types = Vector{Vector}(undef, 1 + length(properties))
#
#     utypes = union_types(A)
#
#     headers[1] = "step"
#     types[1] = Int[]
#
#     if length(utypes) > 1
#         custom_multi_agent_agg_types!(types, utypes, headers, model, properties)
#     else
#         single_agent_agg_types!(types, headers, model, properties)
#     end
#     DataFrame(types, headers)
# end
#
# function init_custom_agent_dataframe(model::ABM, properties::Function)
#     init_custom_agent_dataframe(model, properties(model))
# end
#
# ## Needed to modify it so I could start without Shade agents
#
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
                a = default_agent(atype)
            end
            if k isa Symbol
                current_type =
                    hasproperty(a, k) ? typeof(Agents.get_data(a, k, identity)) : Missing
            else
                current_type = try
                        typeof(Agents.get_data(a, k, identity))
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
#
# function custom_multi_agent_agg_types!(
#     types::Vector{Vector{T} where T},
#     utypes::Tuple,
#     headers::Vector{String},
#     model::ABM,
#     properties::Vector{<:Tuple},
# )
#     for (i, property) in enumerate(properties)
#
#         k, agg = property
#         headers[i+1] = dataname(property[1:2])
#         current_types = DataType[]
#         for atype in utypes
#             allatype = Iterators.filter(a -> a isa atype, allagents(model))
#
#             if !isempty(allatype)
#                 a = first(allatype)
#             else
#                 a = default_agent(atype)
#             end
#
#             if k isa Symbol
#                 current_type =
#                     hasproperty(a, k) ? typeof(agg(Agents.get_data(a, k, identity))) : Missing
#             else
#                 current_type = try
#                     typeof(agg(Agents.get_data(a, k, identity)))
#                 catch
#                     Missing
#                 end
#             end
#             isconcretetype(current_type) || warn(
#                 "Type is not concrete when using function $(agg) " *
#                 "on key $(k) for $(atype) agents. Consider using type annotation, e.g. $(agg)(a)::Float64 = ...",
#             )
#             if current_type == Missing && length(property) == 3
#                 conditional = try
#                     property[3](a)
#                 catch
#                     true
#                 end
#                 if conditional
#                     push!(current_types, current_type)
#                 end
#             else
#                 push!(current_types, current_type)
#             end
#         end
#         unique!(current_types)
#         filter!(t -> !(t <: Missing), current_types) # Ignore missings here
#         if length(current_types) == 1
#             types[i+1] = current_types[1][]
#         elseif length(current_types) > 1
#             error("Multiple types found for aggregate function $(agg) on key $(k).")
#         else
#             error("No possible aggregation for $(k) using $(agg)")
#         end
#     end
# end
#
#
# function collect_agent_data!(df, model::ABM, properties::Function, step::Int = 0; kwargs...,) =
#     Agents.collect_agent_data!(df, model, properties(model), step; kwargs...)
