export totprod, maxA, incidence, justcofs, justrusts

totprod(model::ABM) = model.current.prod

maxA(model::ABM) = model.current.max_rust

incidence(model::ABM) = length(model.current.rust_ids) / length(model.current.coffee_ids)

## Not exported

rusted_area(rust::Rust) = sum(rust.state[2,:])

medsum(x) = (median(sum.(x)))

medsum_s(x) = (median(sum.(x[3,:])))

## Filters

justcofs(a) = a isa Coffee
justrusts(a) = a isa Rust
