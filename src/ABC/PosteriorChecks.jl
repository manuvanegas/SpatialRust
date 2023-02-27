## Handy read and writes
read(path::String) = occursin(".csv", path) ? CSV.read(path, DataFrame) : DataFrame(Arrow.Table(path))
read(paths::Vararg{String}) = map(read, paths)

macro name(var)
    string(var)
end

function awrite(path::String, tail::String, dfs::Vararg{DataFrame})
    for df in dfs
        name = @name df
        Arrow.write(string(path, name, tail), df)
    end
end

