## Handy read and writes
read(path::String) = occursin(".csv", path) ? CSV.read(path, DataFrame) : DataFrame(Arrow.Table(path))
read(paths::Vararg{String}) = map(read, paths)

function awrite(path::String, tail::String, dfs::Vector{DataFrame}, names::Vector{String})
    for (df, name) in zip(dfs, names)
        Arrow.write(string(path, "/", name, tail), df)
    end
end

