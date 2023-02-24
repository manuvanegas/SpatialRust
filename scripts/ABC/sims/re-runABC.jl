usings_time = @elapsed begin
    # @everywhere using DrWatson
    @everywhere begin
        using Pkg
        Pkg.activate(".")
    end
    @everywhere begin
        using Arrow, DataFrames, Dates
        using SpatialRust
    end
end

# ARGS: params file, slurm job array id, # cores, # sims per core, quants dirname, hours
println(ARGS)
println("Init: $usings_time")
flush(stdout)

# figuring out which ones are missing
quantspath = string("/scratch/mvanega1/ABC/sims/", ARGS[5])
recently = datetime2unix(now() - Hour(parse(Int, ARGS[6])))
recentfiles = filter(f -> mtime(f) > recently, readdir(quantspath, join = true))
pathlength = length(quantspath)
recentnums = parse.(Int, f[(pathlength + 4):(pathlength + 6)] for f in recentfiles)
# missingnums = filter(n -> n ∉ recentnums, 1:100)
arraynum = parse(Int, ARGS[2])

if arraynum in recentnums
    println("This array job was succesfully run in the last hour.")
else
    load_time = @elapsed begin

        const n_rows = parse(Int, ARGS[3]) * parse(Int, ARGS[4])
        const startat = (arraynum - 1) * n_rows + 1

        when_rust = Vector(Arrow.Table("data/exp_pro/input/whentocollect.arrow")[1])
        const when_2017 = filter(d -> d < 200, when_rust)
        const when_2018 = filter(d -> d > 200, when_rust)
        # const when_plant = Vector(Arrow.Table("data/exp_pro/inputs/sun_whentocollect_plant.arrow")[1])

        # const when_rust = sort!(union(when_plant, when_rust))

        # read climate data
        w_table = Arrow.Table("data/exp_pro/input/weather.arrow")
        const temp_data = Tuple(w_table[2])
        const rain_data = Tuple(w_table[3])
        const wind_data = Tuple(w_table[4])

        const parameters = DataFrame(Arrow.Table(string("data/ABC/", ARGS[1], ".arrow")))[startat : (startat + n_rows - 1),:]

        mkpath("/scratch/mvanega1/ABC/sims/requants")
        mkpath("/scratch/mvanega1/ABC/sims/requals")
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
        outputs = pmap(p -> sim_abc(p, temp_data, rain_data, wind_data, when_2017, when_2018),
                        eachrow(parameters); retry_delays = fill(0.1, 3))
        # outputs = pmap(p -> sim_abc(p),
        #                 eachrow(parameters); retry_delays = fill(0.1, 3), batch_size = 20)
        println("total: ", length(outputs))
    end

    println("Run: $run_time")
    flush(stdout)

    cat_time = @elapsed begin
        quant_df, qual_df = reduce(cat_dfs, outputs)
        # num = parse(Int, ARGS[2])
        add0s = ifelse(arraynum < 10, "00",
            ifelse(arraynum < 100, "0", "")
        )
        filenum = string(add0s, arraynum)
        Arrow.write(string("/scratch/mvanega1/ABC/sims/requants/m_", filenum, ".arrow"), quant_df)
        Arrow.write(string("/scratch/mvanega1/ABC/sims/requals/m_", filenum, ".arrow"), qual_df)
    end

    # println("Write: $cat_time")

    timings = """
    Init: $usings_time
    Loads: $load_time
    Run: $run_time
    Write: $cat_time
    """

    println(string("re-job #: ", ARGS[2],"\n", "array #: ", arraynum,"\n", timings))
end
