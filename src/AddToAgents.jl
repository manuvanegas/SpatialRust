#=
Custom step! that executes some updating function *before* it iterates over
the agents
=#

function Agents.step!(model::ABM, pre_step!, agent_step!, model_step!, n = 1)
    # println("and here")
    pre_step!(model)
    s = 0
    while Agents.until(s, n, model)
        activation_order = model.scheduler(model)
        for index in activation_order
            haskey(model.agents, index) || continue
            agent_step!(model.agents[index], model)
        end
        model_step!(model)
        s += 1
    end
end

#=
Custom... the rest of functions so pre_step! is taken into account
=#

function Agents.run!(model::ABM, pre_step!, agent_step!, model_step!, n = 1;
    replicates::Int=0, parallel::Bool=false, kwargs...)

    # println("here!")
    r = replicates
    if r > 0
        if parallel
            return Agents.parallel_replicates(model, pre_step!, agent_step!, model_step!, n, r; kwargs...)
        else
            return Agents.series_replicates(model, pre_step!, agent_step!, model_step!, n, r; kwargs...)
        end
    else
        return Agents._run!(model, pre_step!, agent_step!, model_step!, n; kwargs...)
    end
end

function Agents._run!(model, pre_step!, agent_step!, model_step!, n;
               when = true, when_model = when,
               agent_properties=nothing, model_properties=nothing,
               mdata=model_properties, adata=agent_properties, obtainer = identity)

    agent_properties ≠ nothing && @warn "use `adata` instead of `agent_properties`"
    model_properties ≠ nothing && @warn "use `mdata` instead of `model_properties`"
    df_agent = init_agent_dataframe(model, adata)
    df_model = init_model_dataframe(model, mdata)
    if n isa Integer
        if when == true; for c in eachcol(df_agent); sizehint!(c, n); end; end
        if when_model == true; for c in eachcol(df_model); sizehint!(c, n); end; end
    end

    s = 0
    while Agents.until(s, n, model)
        if should_we_collect(s, model, when)
            collect_agent_data!(df_agent, model, adata, s)
        end
        if should_we_collect(s, model, when_model)
            collect_model_data!(df_model, model, mdata, s)
        end
        step!(model, pre_step!, agent_step!, model_step!, 1)
        s += 1
    end
    if should_we_collect(s, model, when)
        collect_agent_data!(df_agent, model, adata, s)
    end
    if should_we_collect(s, model, when_model)
        collect_model_data!(df_model, model, mdata, s)
    end


    # CSV.write(projectdir("results", "track", now(), ".csv"), df_model)
    # CSV.write(string("/scratch/mvanega1/", "track/", now(), ".csv"), df_model)
    return df_agent, df_model
end

function Agents.series_replicates(model, pre_step!, agent_step!, model_step!, n, replicates; kwargs...)

  df_agent, df_model = Agents._run!(deepcopy(model), pre_step!, agent_step!, model_step!, n; kwargs...)
  Agents.replicate_col!(df_agent, 1)
  Agents.replicate_col!(df_model, 1)

  for rep in 2:replicates
    df_agentTemp, df_modelTemp = Agents._run!(deepcopy(model), pre_step!, agent_step!, model_step!, n; kwargs...)
    Agents.replicate_col!(df_agentTemp, rep)
    Agents.replicate_col!(df_modelTemp, rep)

    append!(df_agent, df_agentTemp)
    append!(df_model, df_modelTemp)
  end
  return df_agent, df_model
end

function Agents.parallel_replicates(model::ABM, pre_step!, agent_step!, model_step!, n, replicates; kwargs...)

  all_data = pmap(j -> Agents._run!(deepcopy(model), pre_step!, agent_step!, model_step!, n; kwargs...),
                  1:replicates)

  df_agent = DataFrame()
  df_model = DataFrame()
  for (rep, d) in enumerate(all_data)
    Agents.replicate_col!(d[1], rep)
    Agents.replicate_col!(d[2], rep)
    append!(df_agent, d[1])
    append!(df_model, d[2])
  end

  return df_agent, df_model
end

function Agents.paramscan(parameters::Dict{Symbol,}, initialize;
  n = 1, pre_step! = dummystep, agent_step! = dummystep,  model_step! = dummystep,
  progress::Bool = true, include_constants::Bool = false,
  kwargs...)

  if include_constants
    changing_params = collect(keys(parameters))
  else
    changing_params = [k for (k, v) in parameters if typeof(v)<:Vector]
  end

  combs = dict_list(parameters)
  ncombs = length(combs)
  counter = 0
  d, rest = Iterators.peel(combs)
  model = initialize(; d...)
  df_agent, df_model = run!(model, pre_step!, agent_step!, model_step!, n; kwargs...)
  Agents.addparams!(df_agent, df_model, d, changing_params)
  for d in rest
    model = initialize(; d...)
    df_agentTemp, df_modelTemp = run!(model, pre_step!, agent_step!, model_step!, n; kwargs...)
    Agents.addparams!(df_agentTemp, df_modelTemp, d, changing_params)
    append!(df_agent, df_agentTemp)
    append!(df_model, df_modelTemp)
    if progress
      # show progress
      counter += 1
      print("\u1b[1G")
      percent = round(counter*100/ncombs, digits=2)
      print("Progress: $percent%")
      print("\u1b[K")
    end
  end
  progress && println()
  return df_agent, df_model
end

until(ss, n::Int, model) = ss < n
until(ss, n, model) = !n(model, ss)

function custom_scheduler(model::ABM)
    return vcat(model.shade_ids, model.coffee_ids, shuffle(model.rust_ids))
end

function Agents.getindex(model::ABM, ix::Array{Int64,1})
    broadcast(x -> model[x], ix)
end
