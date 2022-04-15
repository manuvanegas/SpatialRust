function best_100(dists::DataFrame, metrics::Vector{Symbol})::Vector{Int}
    d1 = select(dists, :p_row, AsTable(metrics) => ByRow(sum) => :total_dist)
    return sort!(d1, :total_dist)[1:100, :p_row]
end

function best_n(dists::DataFrame, metrics::Vector{Symbol}, n::Int)::Vector{Int}
    d1 = select(dists, :p_row, AsTable(metrics) => ByRow(sum) => :total_dist)
    return sort!(d1, :total_dist)[1:n, :p_row]
end

age_fallen_fruits()::Vector{Symbol} = [:area_age, :spore_age, :fallen, :prod_fruit]

age_fallen_nodes()::Vector{Symbol} = [:area_age, :spore_age, :fallen, :prod_node]

cycle_fallen_fruits()::Vector{Symbol} = [:area_cycle, :spore_cycle, :fallen, :prod_fruit]

cycle_fallen_nodes()::Vector{Symbol} = [:area_cycle, :spore_cycle, :fallen, :prod_node]


######################_____________________________
# testing stuff
# using CSV
# dists = CSV.read("results/ABC/dists.csv", DataFrame)
# describe(dists)
#
# ["p_row", "area_age", "spore_age", "area_cycle", "spore_cycle", "fallen", "prod_fruit", "prod_node"]
#
# ttrows = best_100(dists, age_fallen_fruits())
# ttrows2 = best_100(dists, age_fallen_nodes())
#
# setdiff(ttrows, ttrows2)
# all(ttrows .== ttrows2)
#
# ttcrows = best_100(dists, age_fallen_fruits())
# ttcrows2 = best_100(dists, age_fallen_nodes())
#
# setdiff(ttcrows, ttcrows2)
# all(ttcrows .== ttcrows2)
#
#
# setdiff(ttrows, ttcrows)
#
# ttage = best_100(dists, [:area_age, :spore_age])
# ttcycle = best_100(dists, [:area_cycle, :spore_cycle])
# setdiff(ttage, ttcycle)
