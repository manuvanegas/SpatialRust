
tfile_tree = FileTree("data/exp_pro/")

tall_files = FileTrees.load(tfile_tree[glob"compare/*"], lazy = true) do file
    DataFrame(CSV.File(path(file)))
end

tall_files = tall_files[glob"*.csv"]

function tfmap(df)
    return df[1:10, 1:2]
end

tshortened = mapvalues(tfmap, tall_files)

tvcatted = reducevalues(vcat, tshortened)

tallout = exec(tshortened)
