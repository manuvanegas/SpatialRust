usings_time = @elapsed begin
    @everywhere begin
        using Pkg
        Pkg.activate(".")
    end
    @everywhere begin
        using DataFrames
        using Arrow
        using SpatialRust
    end
end

# ARGS: params file #, slurm job array id, # cores, # sims per core
println(ARGS)
println("Init: $usings_time")
flush(stdout)

load_time = @elapsed begin
    quantdirname = string("quants_", ARGS[1])
    qualdirname = string("quals_", ARGS[1])
    mkpath(string("/scratch/mvanega1/ABC/sims/", quantdirname))
    mkpath(string("/scratch/mvanega1/ABC/sims/", qualdirname))
    
    const n_rows = parse(Int, ARGS[3]) * parse(Int, ARGS[4])
    const startat = (parse(Int, ARGS[2]) - 1) * n_rows + 1

    const parameters = DataFrame(Arrow.Table(string("data/ABC/parameters_", ARGS[1], ".arrow")))[startat : (startat + n_rows - 1),:]
end

println("Loads: $load_time")
flush(stdout)

# dummy_time = @elapsed begin
#     #dummy run
#     sim_abc(parameters[10,:], rain_data, temp_data, when_rust, when_plant, 0.5)
#     println("Dummy run completed")
# end

# println("Compile: $dummy_time")
# flush(stdout)

run_time = @elapsed begin
    wp = CachingPool(workers())
    outputs = abc_pmap(Tables.namedtupleiterator(parameters), wp)
    println("total: ", length(outputs))
end

# function map_here(par_iterator)
#     return map(sim_abc, par_iterator)
# end

# run_time = @elapsed begin
#     outputs = map_here(Tables.namedtupleiterator(parameters))
#     println("total: ", length(outputs))
# end

println("Run: $run_time")
flush(stdout)

cat_time = @elapsed begin
    quant_df, qual_df = reduce(cat_dfs, outputs)
    num = parse(Int, ARGS[2])
    add0s = ifelse(num < 10, "00",
        ifelse(num < 100, "0", "")
    )
    filenum = string(add0s, ARGS[2])
    Arrow.write(string("/scratch/mvanega1/ABC/sims/", quantdirname, "/m_", filenum, ".arrow"), quant_df)
    Arrow.write(string("/scratch/mvanega1/ABC/sims/", qualdirname,"/m_", filenum, ".arrow"), qual_df)
end

timings = """
Init: $usings_time
Loads: $load_time
Run: $run_time
Write: $cat_time
"""

println(string("array #: ", ARGS[2],"\n", timings))