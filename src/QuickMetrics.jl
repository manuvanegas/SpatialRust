export totprod, maxA, incidence, n_coffees, justcofs, justrusts

totprod(model::ABM) = model.current.prod

# maxA(model::ABM) = model.current.max_rust

incidence(model::ABM) = length(model.current.rusts) / nagents(model)

n_rusts(model::ABM) = length(model.current.rusts)

n_coffees(model::ABM) = nagents(model)

## Not exported

tot_area(rust::Coffee) = sum(rust.areas)

medsum(x) = (median(sum.(x)))

medsum_s(x) = (median(sum.(x[3,:])))

## Filters

rusted(a) = a.n_lesions > 0

emedian(arr) = isempty(arr) ? 0.0 : median(arr)
