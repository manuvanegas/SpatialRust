usings_time = @elapsed begin
    @everywhere using DrWatson
    @everywhere @quickactivate "SpatialRust"
    @everywhere begin
        using DataFrames
        using Arrow
        using Distributed: pmap
        include(projectdir("SpatialRust.jl"))
    end
    @everywhere begin
        using .SpatialRust
    end
end

# ARGS: params file, slurm job array id, # cores, # sims per core

load_time = @elapsed begin
    n_rows = parse(Int, ARGS[3]) * parse(Int, ARGS[4])
    startat = (parse(Int, ARGS[2]) - 1) * n_rows + 1

    when_rust = Vector(Arrow.Table("data/exp_pro/inputs/sun_whentocollect_rust.arrow")[1])
    when_plant = Vector(Arrow.Table("data/exp_pro/inputs/sun_whentocollect_plant.arrow")[1])

    # read climate data
    rain_data = Vector(Arrow.Table("data/exp_pro/inputs/sun_weather.arrow")[1])
    temp_data = Vector(Arrow.Table("data/exp_pro/inputs/sun_weather.arrow")[2])
    # rain_data = Vector{Bool}(weather[!, :Rainy])
    # temp_data = Vector{Float64}(weather[!, :MeanTa])

    parameters = DataFrame(Arrow.Table(string("data/ABC/", ARGS[1], ".arrow")))[startat : (startat + n_rows - 1),:]

    mkpath("/scratch/mvanega1/ABC/sims/ages")
    mkpath("/scratch/mvanega1/ABC/sims/cycles")
    mkpath("/scratch/mvanega1/ABC/sims/prod")
end

dummy_time = @elapsed begin
    #dummy run
    sim_abc(parameters[10,:], rain_data, temp_data, when_rust, when_plant, 0.5)
    println("Dummy run completed")
end

run_time = @elapsed begin
    outputs = pmap(p -> sim_abc(p, rain_data, temp_data, when_rust, when_plant, 0.5),
                    eachrow(parameters); retry_delays = fill(0.1, 3))
    println("total: ", length(outputs))
end

cat_time = @elapsed begin
    cat_outs = reduce(struct_cat, outputs)
    filenum = ifelse(ARGS[2] < 10,
    string("00", ARGS[2]),
    ifelse(ARGS[2] < 100,
        string("0", ARGS[2]),
        ARGS[2]
        )
    )
    Arrow.write(string("/scratch/mvanega1/ABC/sims/ages/m_", filenum, ".arrow"), cat_outs.per_age)
    Arrow.write(string("/scratch/mvanega1/ABC/sims/cycles/m_", filenum, ".arrow"), cat_outs.per_cycle)
    Arrow.write(string("/scratch/mvanega1/ABC/sims/prod/m_", filenum, ".arrow"), cat_outs.prod_df)
end

timings = """
Init: $usings_time
Loads: $load_time
Compile: $dummy_time
Run: $run_time
Write: $cat_time
"""

println(string("array #: ", ARGS[2],"\n", timings))
