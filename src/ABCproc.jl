function last_row() #returns last row of parameter file that was evaluated
    files = readdir("/scratch/mvanega1/ABCraw/")
    lastrow = maximum(files)
    println("last row: ", lastrow)
    return lastrow
end
