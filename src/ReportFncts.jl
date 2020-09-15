function ind_area(agent)
    area = 0.0
    if typeof(agent) === Rust
        area = agent.area
    end
    return area
end

function ind_lesions(agent)
    area = 0.0
    if typeof(agent) === Rust
        area = agent.n_lesions
    end
    return area
end

function rust_incid(model)
    return length(model.rust_ids) / length(model.coffee_ids)
end

function mean_rust_sev(model)
    area_sum = 0.0
    for id in model.rust_ids
        area_sum += model[id].area * model[id].n_lesions / 25.0
    end
    sev = length(model.rust_ids) > 0 ? area_sum / length(model.rust_ids) : 0.0

    return sev
end

function mean_rust_sev_tot(model)
    area_sum = 0.0
    for id in model.rust_ids
        area_sum += model[id].area * model[id].n_lesions / 25.0
    end
    sev = area_sum / length(model.coffee_ids)

    return sev
end

function get_production(model)::Array{Float64}
    prods = zeros(length(model.coffee_ids))
    for i = 1:length(model.coffee_ids)
        id = model.coffee_ids[i]
        prods[i] = model[id].production
    end
    return prods
end

function mean_production(model)
    # tot = 0.0
    # for id in model.coffee_ids
    #     tot += model[id].production
    # end
    # return tot / length(model.coffee_ids)
    return mean(get_production(model)::Array{Float64})
end

function std_production(model)
    std(get_production(model)::Array{Float64})
end

function count_rusts(model)
    return length(model.rust_ids)
end


function get_rust_sevs(model)
    as = zeros(length(model.rust_ids))
    for i = 1:length(model.rust_ids)
        id = model.rust_ids[i]
        as[i] = model[id].area * model[id].n_lesions
    end
    return as
end

function mean_sev(model)
    # mean(get_rust_sevs(model))
    if length(getproperty.(model[model.rust_ids],:area)) == 0
        return 0.0
    else
    return mean(getproperty.(model[model.rust_ids],:area) .* getproperty.(model[model.rust_ids],:n_lesions))
    end
end

function std_sev(model)
    # std(get_rust_sevs(model))
    if length(getproperty.(model[model.rust_ids],:area)) == 0
        return 0.0
    else
        return std(getproperty.(model[model.rust_ids],:area) .* getproperty.(model[model.rust_ids],:n_lesions))
    end
end

function mean_r_area(model)
    if length(getproperty.(model[model.rust_ids],:area)) == 0
        return 0.0
    else
        return mean(getproperty.(model[model.rust_ids],:area))
    end
end

function mean_r_lesions(model)
    if length(getproperty.(model[model.rust_ids],:n_lesions)) == 0
        return 0.0
    else
        return mean(getproperty.(model[model.rust_ids],:n_lesions))
    end
end

function mean_r_prog(model)
    if length(getproperty.(model[model.rust_ids],:n_lesions)) == 0
        return 0.0
    else
        return mean(1 ./ (1 .+ (0.25 ./ getproperty.(model[model.rust_ids],:area) .+ (getproperty.(model[model.rust_ids],:n_lesions) ./ 25.0)).^4))
    end
end

function mean_sev_tot(model)
    if length(getproperty.(model[model.rust_ids],:area)) == 0
        return 0.0
    else
        sum(getproperty.(model[model.rust_ids],:area) .* getproperty.(model[model.rust_ids],:n_lesions)) / length(model.coffee_ids)
    end
end

function std_sev_tot(model)
    if length(getproperty.(model[model.rust_ids],:area)) == 0
        return 0.0
    else
        sevs = getproperty.(model[model.rust_ids],:area) .* getproperty.(model[model.rust_ids],:n_lesions)
        sqrt(sum((sevs .- sum(sevs) / length(model.coffee_ids)).^2) / (length(model.coffee_ids) - 1))
    end
end

function mean_cof_area(model)
    mean(getproperty.(model[model.coffee_ids],:area))
end

function count_germts(model)
    if length(getproperty.(model[model.rust_ids],:area)) == 0
        return 0.0
    else
        sum(getproperty.(model[model.rust_ids],:germinated))
    end
end

function mean_ctdn(model)
    mean(getproperty.(model[model.coffee_ids],:exh_countdown))
end

function mean_sunlight(model)
    mean(getproperty.(model[model.coffee_ids],:sunlight))
end

function std_sunlight(model)
    mean(getproperty.(model[model.coffee_ids],:sunlight))
end
