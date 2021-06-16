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

function load_to_select(file_path::String)
    outpath = mkpath("/scratch/mvanega1/ABCmiddle")
    println(outpath)
    files = readdir(file_path, join = true, sort = false)[1:50]
    howmany = length(files)
    chunksize = 2

    rowNs = collect(1:10^6)
    processedRows = Int64[]
    sizehint!(processedRows, 10^6)


    for startat in 1:chunksize:howmany
        stopat = startat + chunksize - 1 < howmany ? startat + chunksize - 1 : howmany
        out_file = DataFrame()

        for current in startat:stopat
            current_f = CSV.read(files[current], DataFrame)
            append!(out_file, plant_sampler(current_f))

            push!(processedRows, parse(Int, split(files[current], ['_', '.'])[2]))
        end

        CSV.write(string(outpath, "/mid_", startat, ".csv"), out_file)
        CSV.write(datadir("ABC", "interim_processed_rows.csv"), DataFrame(processed = processedRows))
    end

    CSV.write(datadir("ABC", "missed_rows.csv"), DataFrame(missed = setdiff(rowNs, processedRows)))
end

function filter_params(file_path::String)
    files = readdir(file_path)

    processed_rows = parse.(Int, split.(files, ['_', '.'])[:, 2])

    remaining = setdiff(collect(1:10^6), processed_rows)

    parameters = CSV.read(datadir("ABC", "parameters.csv"), DataFrame)

    missed_parameters = parameters[ parameters.RowN .∈ Ref(remaining) , :]

    CSV.write(datadir("ABC", "missed_parameters.csv"), missed_parameters)
end
