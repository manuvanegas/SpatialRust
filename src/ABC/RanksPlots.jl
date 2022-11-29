function best_100(dists::DataFrame, metrics::Vector{Symbol})::Vector{Int}
    d1 = select(dists, :p_row, AsTable(metrics) => ByRow(sum) => :total_dist)
    return sort!(d1, :total_dist)[1:100, :p_row]
end

function best_n(dists::DataFrame, metrics::Vector{Symbol}, n::Int)::Vector{Int}
    d1 = select(dists, :p_row, AsTable(metrics) => ByRow(sum) => :total_dist)
    return sort!(d1, :total_dist)[1:n, :p_row]
end

function metrics(h::Int)
    if h == 1
        return [:area_age, :spore_age, :fallen, :prod_fruit]
    elseif h == 2
        return [:area_age, :spore_age, :fallen, :prod_node]
    elseif h == 3
        return [:area_cycle, :spore_cycle, :fallen, :prod_fruit]
    else
        return [:area_cycle, :spore_cycle, :fallen, :prod_node]
    end
end

## Plots

function three_violins(pars::NamedTuple, sel::NamedTuple, height = 800, width = 400)
    par1, par2, par3 = pars
    sel1, sel2, sel3 = sel

    fviolins = Figure(resolution = (height, width));
    ax1 = Axis(fviolins[1,1];
        xticks = (2:2:14, names(parameters)[2:8]),
        xticklabelrotation = π/4
    )
    ax2 = Axis(fviolins[1,2];
        xticks = ([1], [names(parameters)[9]]),
        xticklabelrotation = π/4
    )
    ax3 = Axis(fviolins[1,3];
        xticks = ([1], [names(parameters)[10]]),
        xticklabelrotation = π/4
    )

    violin!(ax1, sel1.group, sel1.value, side = :right, color = :teal)
    violin!(ax1, par1.group, par1.value, side = :left, color = :orange)

    violin!(ax2, sel2.group, sel2.value, side = :right, color = :teal)
    violin!(ax2, par2.group, par2.value, side = :left, color = :orange)

    violin!(ax3, sel3.group, sel3.value, side = :right, color = :teal)
    violin!(ax3, par3.group, par3.value, side = :left, color = :orange)

    colsize!(fviolins.layout, 1, Relative(15/18))

    return fviolins
end

function three_boxplots(pars::NamedTuple, sel::NamedTuple, height = 800, width = 400)
    par1, par2, par3 = pars
    sel1, sel2, sel3 = sel

    fbox = Figure(resolution = (height, width));
    ax1 = Axis(fbox[1,1];
        xticks = (2:2:14, names(parameters)[2:8]),
        xticklabelrotation = π/4,
        ylabel = "Value"
    )
    ax2 = Axis(fbox[1,2];
        xticks = ([1], [names(parameters)[9]]),
        xticklabelrotation = π/4
    )
    xlims! = (ax2,-2, 2)
    ax3 = Axis(fbox[1,3];
        xticks = ([1], [names(parameters)[10]]),
        yticks = (0:5:25),
        xticklabelrotation = π/4
    )
    # Label(fbox[2,:], "Parameter name")

    boxplot!(ax1, sel1.group, sel1.value, dodge = 2, dodge_gap = 2.4, color = (:teal, 0.8))
    boxplot!(ax1, par1.group, par1.value, dodge = 1, dodge_gap = 2.4, color = (:orange, 0.8))

    boxplot!(ax2, sel2.group, sel2.value, dodge = 2, dodge_gap = 2.4, color = (:teal, 0.8))
    boxplot!(ax2, par2.group, par2.value, dodge = 1, dodge_gap = 2.4, color = (:orange, 0.8))

    boxplot!(ax3, sel3.group, sel3.value, dodge = 2, dodge_gap = 2.4, color = (:teal, 0.8))
    boxplot!(ax3, par3.group, par3.value, dodge = 1, dodge_gap = 2.4, color = (:orange, 0.8))

    colsize!(fbox.layout, 1, Relative(15/18))
    colgap!(fbox.layout, 5)
    fbox
end

## Arranging data

function long_and_separate(df::DataFrame)::NamedTuple
    df1 = select(df, 1:8)
    df2 = select(df, [1,9])
    df3 = select(df, [1,10])

    ldf1 = stack(df1)
    transform!(ldf1, :variable => ByRow(whichgroup) => :group)
    ldf1[:,:group] .= ldf1[!, :group] .* 2
    ldf2 = stack(df2)
    ldf2[:, :group] .= 1
    ldf3 = stack(df3)
    ldf3[:, :group] .= 1

    return (g1 = ldf1, g2 = ldf2, g3 = ldf3)
end

function whichgroup(var)
    return findfirst(x -> x == var, ("rust_gr", "cof_gr",
    "spore_pct", "fruit_load", "light_inh", "rain_washoff",
    "rain_distance", "wind_distance", "exhaustion"))
end

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
