function last_row() #returns last row of parameter file that was evaluated
    files = readdir("/scratch/mvanega1/ABCraw/")
    lastrow = maximum(files)
    println("last row: ", lastrow)
    return lastrow
end

function move_files()
    mkpath(projectdir("results/ABCrawfiles"))
    files = readdir("/scratch/mvanega1/ABCraw")
    counter = 0

    for f in files
        mv(string("/scratch/mvanega1/ABCraw/", f), projectdir("results/ABCrawfiles", f))
        counter += 1

        if counter == 500
            cunter = 0
            sleep(0.1)
        end

    end

end

function interim_plant_sampler(df::DataFrame)
    df = df[df.step .> 15, :]
    xy_pos = unique(df[(df.agent_type .== "Coffee") .& (5 .< df.x_pos .<= 95) .& (5 .< df.y_pos .<= 95), [:x_pos, :y_pos, :id]])
    # sample size is 10% of coffees within the 5-row limit (= 810)
    # times 2 because of the new sampling in Jan
    selected_ids = sample(xy_pos.id, 1620, replace = false)
    first_half = selected_ids[1:810]
    second_half = selected_ids[811:end]
    sampled = df[(df.step .<= 230) .& ((df.id .∈ Ref(first_half)) .| (df.host_guest .∈ Ref(first_half))), :]
    append!(sampled, df[(df.step .> 230) .& ((df.id .∈ Ref(second_half)) .| (df.host_guest .∈ Ref(second_half))), :])
    return sampled
end

function sample_save(file::String, chunksize::Int, outpath::String)
    #processedRows = Int64[]
    #sizehint!(processedRows, chunksize)
    #out_file = DataFrame()
    #for current in 1:chunksize
        #current_f = CSV.read(files[current], DataFrame)
        # if files[current] == "placeholder"
        #     break
        # end
    #end
    #out_file_n = Int64(last(processedRows))
    p_row = split(file, ['_', '.'])[2]
    row_n = string("0" ^ (7 - length(p_row)), p_row)

    df = CSV.read(file, DataFrame)

    sums = sum(eachcol(ismissing.(df)))
    if any(sums .> 0)
        CSV.write(string(projectdir("results","faulty"), basename(file)), DataFrame(v = sums))
        pritnln("aha!")
        pritnln(string(basename(file), ": ", sums))
    else
        df = interim_plant_sampler(df)
        CSV.write(string(outpath, "/mid_", row_n, ".csv"), df)
        println(string(basename(file), ": listos"))
    end

    #CSV.write(datadir("ABC", "tracking_processed_rows.csv"), DataFrame(processed = processedRows))
    return parse(Int, p_row)
end

function load_to_select(file_path::String, out_folder::String, chunksize, ini_i = 1, fin_i = 0)
    outpath = mkpath(string("/scratch/mvanega1/", out_folder))
    #mkpath("/scratch/mvanega1/trackRows")
    #println(outpath)
    if fin_i == 0
        files = readdir(file_path, join = true, sort = false)
    else
        files = readdir(file_path, join = true, sort = false)[ini_i:fin_i]
    end

    howmany = length(files)

    # n_out_files = cld(howmany, chunksize)
    # files_v = [String[] for i = 1:n_out_files]
    #
    # for v_pos in 1:n_out_files
    #     stopat = chunksize * v_pos
    #     startat = stopat - chunksize + 1
    #     stopat = min(stopat, howmany)
    #     files_v[v_pos] = [files[i] for i = startat:stopat]
    # end


    println("pre-pmap")
    processsed_rows = pmap(f -> sample_save(f, chunksize, outpath), files; batch_size = chunksize, retry_delays = fill(0.01, 3))

    #processedRows = reduce(vcat, processsed_rows)
    CSV.write(datadir("ABC", "missed_rows.csv"), DataFrame(missed = setdiff(collect(1:10^6), processedRows)))
end

function filter_params(file_path::String)
    files = readdir(file_path)

    processed_rows = parse.(Int, split.(files, ['_', '.'])[:, 2])

    remaining = setdiff(collect(1:10^6), processed_rows)

    parameters = CSV.read(datadir("ABC", "parameters.csv"), DataFrame)

    missed_parameters = parameters[ parameters.RowN .∈ Ref(remaining) , :]

    CSV.write(datadir("ABC", "missed_parameters.csv"), missed_parameters)
end

function find_faulty_files()
    startedat = time()
    println(string("start:", (time() - startedat)))
    outfolder = mkpath(projectdir("results","faulty"))
    files = readdir("/scratch/mvanega1/ABCveryraw/", join = true, sort = false)[(27121 + 36769):end]
    println(string("loadedd file names at:", (time() - startedat)))
    println(string("tot files:", length(files)))

    function find_missings(f, startedat, outfolder)
        missing_vals = ismissing.(CSV.read(f, DataFrame))
        println(basename(f))
        now = time() - startedat
        println(now)
        sums = sum(eachcol(missing_vals))
        if any(sums .> 0)
            CSV.write(string(outfolder, basename(f)), DataFrame(v = sums))
            pritnln("aha!")
            pritnln(sums)
        end
    end

    checked = pmap(f -> find_missings(f, startedat, outfolder), files; on_error=identity)
end
