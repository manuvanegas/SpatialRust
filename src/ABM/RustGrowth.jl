function grow_each_rust!(state::Vector{Float64}, temp::Float64, sunlight::Float64, production::Float64)
    if state[1] #germinated

    else

    end
end

function area_growth!(state::SubArray{Float64}, local_temp::Float64, growth_r::Float64, spor_conds::Bool)
# 1. germinated
# 2. area
# 3. spores
# 4. age
    if state[4] < 500
        state[4] += 1.0
    end
    if 14.0 < local_temp < 30.0 # grow and sporulate

        #  logistic growth (K=1) * rate due to fruit load * rate due to temperature
        state[2] += state[2] * (1 - state[2]) * growth_r

        if spor_conds
            state[3] = 1.0
        end
    end
end

function sporul_conds(r::Float64, area::Float64, temp::Float64)::Bool
    r < (area * (temp + 5.0) / 30.0) # Merle et al 2020. sporulation prob for higher Tmax(until 30)
end

function germinate!(state::SubArray{Float64})
    # println(typeof(state))
    # println(state)
    state[1] = 1.0
    state[2] = 0.01
    state[4] = 0.0
end



##
#
# using BenchmarkTools
#
# mymat = zeros(3,6)
#
# @views for i in 1:6
#     mymat[:, i] = myupdate(mymat[:,i])
# end
#
# function myupdate!(myvec)
#     # println(myvec)
#     return myvec = [1.0, 2.0, 3.0]
# end
#
# function myupdate(myvec::SubArray)
#     # println(myvec)
#     return myvec = [1.0, 2.0, 3.0]
# end
#
# map(myupdate!, eachcol(mymat))
#
# function withviews()
#     mymmat = zeros(100, 1000)
#     @views for i in 1:1000
#         mymmat[:,i] = theupdate(mymmat[:,i])
#     end
#     return mymmat
# end
#
# function withoutviews()
#     mymmat = zeros(100, 1000)
#     for i in 1:1000
#         mymmat[:,i] = theupdate(mymmat[:,i])
#     end
#     return mymmat
# end
#
# function withmapslices()
#     mymmat = zeros(100, 1000)
#     mapslices(theupdate, mymmat, dims = 1)
# end
#
# mysuba = view(mymat, :, 1)
# mysuba2 = view(mymat, :, 2)
#
#
# function theupdate(myvec)
#     return fill(myvec[2] + 1.0, length(myvec))
# end
