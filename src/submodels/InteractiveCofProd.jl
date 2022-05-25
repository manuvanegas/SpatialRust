function runall(b::Float64, c::Float64, sun::Float64)
    # sun =
    a = 0.3
    # b =
    # c =
    µV = 0.01
    µB = b

    function deltas(vec::Vector{Float64}, day::Int) # , a, b, c, µV, µB, sun
        calday = day % 365
        V = vec[1]
        R = vec[2]
        B = vec[3]

        dR_B = 0.0
        dR_V = 0.0
        dR_R = 0.0
        if calday == 0
            dR_B = - B
        elseif calday > 122
            dR_B = b * B
        # elseif calday == 122
        #     dR_B = sun * R * c
        end
        if R > 0.0
            dR_V = a
            # dR(V, B) = (sun * V) - (b * B) - a
        else
            # dR(V, B) = (sun * V) - ((b * B) / (1 - R))
            if calday > 122
                dR_B = ((b * B) / (1 - R))
            end
        end

        ∆V = dR_V - (µV * V)
        ∆R = (sun * V) - dR_V - dR_B - dR_R 
        if calday == 122
            ∆B = sun * R * c
        else
            ∆B = dR_B - (µB * B)
        end

        return [min(V + ∆V, 10.0), R + ∆R, B + ∆B]
    end

    days = 600
    growth = hcat([10.0, 0.0, 0.0], zeros(3, days - 1))

    for day in 2:days
        growth[:, day] = deltas(growth[:, day - 1], day)
    end

    return [growth[1,:], growth[2,:], growth[3,:]]

end
function interactiveplot()
    figCP = Figure();
    axCP_V = Axis(figCP[1, 1])
    axCP_R = Axis(figCP[2, 1])
    axCP_B = Axis(figCP[3, 1])

    lsgrid = labelslidergrid!(
        figCP,
        ["b", "c", "sun"],
        [range(0.01, 0.5, 8), range(0.1, 3.0, 8), [0.3, 0.6, 1.0]];
        format = [x -> "$(round(x, digits = 2))"])

    # set starting positions
    set_close_to!(lsgrid.sliders[1], 1.0)
    set_close_to!(lsgrid.sliders[2], 1.5)
    set_close_to!(lsgrid.sliders[3], 1.0)

    # layout sliders
    sl_sublayout = figCP[4,1] = GridLayout(height = 120)
    figCP[4, 1] = lsgrid.layout

    # create listeners
    b = lsgrid.sliders[1].value
    c = lsgrid.sliders[2].value
    sun = lsgrid.sliders[3].value

    growths = @lift(runall($b, $c, $sun))

    # sliderobservables = [s.value for s in lsgrid.sliders]
    # growths = lift(sliderobservables...) do slvalues...
    #     runall(slvalues...)
    # end

    lineV = lines!(axCP_V, 1:length(growths.val[1]), @lift($growths[1]))
    lineR = lines!(axCP_R, 1:length(growths.val[1]), @lift($growths[2]))
    lineB = lines!(axCP_B, 1:length(growths.val[1]), @lift($growths[3]))

    ylims!(axCP_V, 0, 12)
    return figCP
end

# figCP = interactiveplot()
