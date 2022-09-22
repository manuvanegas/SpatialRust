function grow_shades!(model::ABM)
    # for shade_i in model.current.shade_ids
    #     grow_shade!(tree, model.pars.shade_g_rate)
    # end
    model.current.ind_shade += model.pars.shade_g_rate *
        (1.0 - model.current.ind_shade * inv(0.95)) * model.current.ind_shade
end

# function grow_shade!(tree::Shade, rate::Float64)
#     tree.shade += rate * (1.0 - tree.shade / 0.95) * tree.shade
#     tree.age += 1
# end
