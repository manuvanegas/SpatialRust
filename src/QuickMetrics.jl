export totprod, maxA, incidence, n_coffees, justcofs, justrusts

totprod(model::ABM) = model.current.prod

maxA(model::ABM) = model.current.max_rust

incidence(model::ABM) = length(model.current.rusts) / length(model.current.coffees)

n_coffees(model::ABM) = length(model.current.coffees)

## Not exported

rusted_area(rust::Rust) = sum(rust.state[2,:])

medsum(x) = (median(sum.(x)))

medsum_s(x) = (median(sum.(x[3,:])))

## Filters

justcofs(a) = a isa Coffee
justrusts(a) = a isa Rust

emedian(arr) = isempty(arr) ? 0.0 : median(arr)
