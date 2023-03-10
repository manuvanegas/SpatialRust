function grow_shades!(current::Books, rate::Float64)
    # for shade_i in model.current.shade_ids
    #     grow_shade!(tree, model.pars.shade_g_rate)
    # end
    current.ind_shade += rate * (1.0 - current.ind_shade * inv(0.8)) * current.ind_shade
end

# function grow_shade!(tree::Shade, rate::Float64)
#     tree.shade += rate * (1.0 - tree.shade / 0.95) * tree.shade
#     tree.age += 1
# end
