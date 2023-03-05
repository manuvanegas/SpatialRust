export totprod, maxA, incidence, n_coffees, justcofs, justrusts

totprod(model::ABM) = model.current.prod

# maxA(model::ABM) = model.current.max_rust

incidence(model::ABM) = length(model.rusts) / nagents(model)
# incidence(model::ABM) = count(r.n_lesions > 0 for r in allagents(model)) / nagents(model)

n_rusts(model::ABM) = length(model.rusts)
# n_rusts(model::ABM) = count(r.n_lesions > 0 for r in allagents(model))

n_coffees(model::ABM) = nagents(model)

## Not exported

tot_area(rust::Coffee) = sum(rust.areas)

medsum(x) = (median(sum.(x)))

medsum_s(x) = (median(sum.(x[3,:])))

## Filters

rusted(a) = a.n_lesions > 0

emedian(arr) = isempty(arr) ? 0.0 : median(arr)
