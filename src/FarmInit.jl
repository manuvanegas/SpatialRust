struct Input
    map_dims::Int
    harvest_cycle::Int # 182 or 365
    # farmer's strategy and finances
    p_density::Float64 # 0 to 1
    fungicide_period::Int # in days
    prune_period::Int # in days
    inspect_period::Int # days
    target_shade::Float64 # 0.2 to 0.9
    pruning_effort::Float64 # % shade trees pruned
    coffee_price::Float64 # 1 for now
    prune_cost::Float64 # 1 for now
    # weather and abiotic parameters
    rain_distance::Float64
    wind_distance::Float64
    rain_data::Vector{Bool}
    wind_data::Vector{Bool}
    temp_data::Vector{Float64}
    mean_temp::Float64
    uv_inact::Float64 # extent of effect of UV inactivation (0 to 1)
    rain_washoff::Float64 # " " " rain wash-off (0 to 1)
    temp_cooling::Float64 # temp reduction due to shade
    diff_splash::Float64 # % extra distance due to enhanced kinetic e (shade)
    wind_protec::Float64 # % extra wind distance due to absence of shade
    # biotic parameters
    shade_rate::Float64 # shade growth rate
    max_cof_gr::Float64
    opt_g_temp::Float64 # optimal rust growth temp
    fruit_load::Float64 # extent of fruit load effect on rust growth (severity; 0 to 1)
    spore_pct::Float64 # % of area that sporulates
    # when map as input
    farm_map::BitArray
end

function initialize_sim(;
    steps::Int = 10,
    map_dims::Int = 10,
    shade_percent::Float64 = 0.3,
    fragmentation::Bool = false,
    random::Bool = false,
    harvest_cycle::Int = 182,
    p_density::Float64 = 1.0,
    fungicide_period::Int = 182,
    prune_period::Int = 91,
    inspect_period::Int = 7,
    target_shade::Float64 = 0.3,
    pruning_effort::Float64 = 0.75,
    coffee_price::Float64 = 1.0,
    prune_cost::Float64 = 1.0,
    rain_distance::Float64 = 1.0,
    wind_distance::Float64 = 5.0,
    rain_prob::Float64 = 0.5,
    wind_prob::Float64 = 0.4,
    mean_temp::Float64 = 22.5,
    #emp_data::Bool = false,
    rain_data::Vector{Bool} = [true],
    temp_data::Vector{Float64} = [22.5],
    uv_inact::Float64 = 0.1,
    rain_washoff::Float64 = 0.1,
    temp_cooling::Float64 = 2.0, # van Oijen 2010. Range of 1.5 to 5.4
    diff_splash::Float64 = 2.0, # Avelino et al. 2020 "Kinetic energy was twice as high"
    wind_protec::Float64 = 1.0, #
    shade_rate::Float64 = 0.01, # look up
    max_cof_gr::Float64 = 0.5,
    opt_g_temp::Float64 = 22.5,
    fruit_load::Float64 = 1.0, # might not be needed
    spore_pct::Float64 = 0.6,
    farm_map::BitArray = create_bitmap(map_dims, shade_percent, fragmentation, random))

    if length(rain_data) == 1 # if no weather data is provided, use probs to create own
        rain_data = rand(Bool, steps) .< rain_prob
        temp_data = fill(mean_temp, steps) .+ randn() .* 2
        println("Check data! This has not been validated!")
    elseif length(rain_data) != steps
        println("# steps != length of rain data. Using the latter as # steps")
    end


    wind_data = rand(Bool, steps) .< wind_prob

    input = Input(map_dims,
        harvest_cycle,
        p_density,
        fungicide_period,
        prune_period,
        inspect_period,
        target_shade,
        pruning_effort,
        coffee_price,
        prune_cost,
        rain_distance,
        wind_distance,
        rain_data, # rain data is passed instead of rain_prob
        wind_data,
        temp_data,
        mean_temp,
        uv_inact,
        rain_washoff,
        temp_cooling,
        diff_splash,
        wind_protec,
        shade_rate,
        max_cof_gr,
        opt_g_temp,
        fruit_load,
        spore_pct,
        farm_map)
    # else
    #     rain_prob = fill(rain_prob[1], harvest_cycle)
    #     wind_prob = fill(wind_prob[1], harvest_cycle)
    #     temp_series = fill(mean_temp, harvest_cycle)
    #
    #     input = Input(map_dims,
    #     harvest_cycle,
    #     p_density,
    #     fungicide_period,
    #     prune_period,
    #     inspect_period,
    #     target_shade,
    #     pruning_effort,
    #     coffee_price,
    #     prune_cost,
    #     rain_distance,
    #     wind_distance,
    #     rain_prob,
    #     wind_prob,
    #     temp_series,
    #     mean_temp,
    #     uv_inact,
    #     rain_washoff,
    #     temp_cooling,
    #     diff_splash,
    #     wind_protec,
    #     shade_rate,
    #     max_cof_gr,
    #     opt_g_temp,
    #     fruit_load,
    #     spore_pct,
    #     farm_map)
    # end

    setup_sim(input)
end


function create_bitmap(dims::Int, shade_percent::Float64, fragmentation::Bool, random::Bool = true)
    n_shades = round(Int, shade_percent * dims ^ 2)
    if random == true # random placement of shade trees
        b_map = trues(dims, dims) # all coffees
        b_map[sample(1:(dims^2), n_shades, replace = false)] .= false
    else #input percent to the ratio
        if fragmentation == true # produce structured layout
            if (n_shades) > (dims * 6 - 9) # if shade trees are enough to separate space into 4 microlots
                b_map = falses(dims,dims)
                q_side = dims / 4
                coffees_lot, extra = fldmod(((1 - shade_percent) * dims^2)::Float64, 4.0::Float64)
                microlot_half_side = (floor(sqrt(coffees_lot)) / 2)
                first_q = Int(ceil(q_side))
                second_q = Int(ceil(q_side * 3))

                if microlot_half_side == 0.0 # "radius" of microlot is 0
                    for x in [first_q, second_q]
                        for y in [first_q, second_q]
                            b_map[x, y] = true
                        end
                    end
                elseif microlot_half_side == 1.0
                    for x in [first_q, second_q]
                        for y in [first_q, second_q]
                            b_map[(x - 1) : x, (y - 1) : y] .= true
                        end
                    end

                elseif microlot_half_side % 1 != 0.0 # "radius" is odd
                    microlot_half_side = Int(ceil(microlot_half_side - 1))
                    for x in [first_q, second_q]
                        for y in [first_q, second_q] # get the (approx) center of each quadrant
                            b_map[(x - microlot_half_side) : (x + microlot_half_side), (y - microlot_half_side) : (y + microlot_half_side)] .= true

                            rest = coffees_lot - ((microlot_half_side * 2) + 1)^2
                            extra_x = 0
                            extra_y = 1
                            while rest > 0 #add rest of coffee plants
                                b_map[(x - microlot_half_side + extra_x), (y - microlot_half_side + extra_y)] = true
                                rest = rest - 1
                                extra_x = extra_x + 1
                                if extra_x > q_side
                                    extra_x = 0
                                    extra_y = extra_y + 1
                                end
                            end
                        end
                    end
                else # "radius" is even
                    microlot_half_side = Int(microlot_half_side - 1)
                    for x in [first_q, second_q]
                        for y in [first_q, second_q] # get the (approx) center of each quadrant
                            b_map[(x - microlot_half_side - 1) : (x + microlot_half_side), (y - microlot_half_side - 1) : (y + microlot_half_side)] .= true

                            rest = coffees_lot - ((microlot_half_side * 2) + 1)^2
                            extra_x = 0
                            extra_y = 1
                            while rest > 0 #add rest of coffee plants
                                b_map[(x - microlot_half_side + extra_x), (y - microlot_half_side + extra_y)] = true
                                rest = rest - 1
                                extra_x = extra_x + 1
                                if extra_x > q_side
                                    extra_x = 0
                                    extra_y = extra_y + 1
                                end
                            end
                        end
                    end
                end
            else # if shade trees are not enough, divide quadrants until possible
                b_map = trues(dims, dims)
                half_side = Int(dims / 2)
                line_coord = half_side # gets to max 2
                x_coor = 1 # gets to max half_side
                y_coor = 1
                while n_shades > 0
                    if x_coor <= dims
                        b_map[x_coor, line_coord] = false
                        x_coor = x_coor + 1
                    elseif y_coor <= dims
                        b_map[line_coord, y_coor] = false
                        y_coor = y_coor + 1
                    elseif line_coord == half_side
                        x_coor = 1
                        y_coor = 1
                        line_coord = 1
                        b_map[x_coor, line_coord] = false
                        x_coor = x_coor + 1
                    elseif line_coord == 1
                        x_coor = 1
                        y_coor = 1
                        line_coord = dims
                        b_map[x_coor, line_coord] = false
                        x_coor = x_coor + 1
                    end
                    n_shades = n_shades - 1
                end

            end
        else # random positions of trees, according to shade_percent
            b_map = trues(dims, dims)
            indices = sample(1:dims, (n_shades * 2) , replace = true)
            for i in 1:2:(length(indices))
                b_map[indices[i],indices[i+1]] = false
            end
        end
    end
    return b_map
end
