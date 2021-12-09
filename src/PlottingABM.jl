

using Agents, Distributed

@agent Coffee GridAgent{2} begin
    area::Float64
    sunlight::Float64
    production::Float64
    exh_countdown::Int
end

@agent Shade GridAgent{2} begin
    shade::Float64
end

@agent Rust GridAgent{2} begin
    germinated::Bool
    area::Float64
    spores::Float64
    n_lesions::Int


Agents.paramscan()

Distributed.pmap()
