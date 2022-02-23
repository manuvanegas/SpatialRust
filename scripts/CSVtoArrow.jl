Pkg.activate(".")
using Arrow, DataFrames
using CSV: read as crd

# read data
when_rust = crd("data/exp_pro/inputs/sun_whentocollect_rust.csv", DataFrame, select = [false, true])[!, 1]
when_plant = crd("data/exp_pro/inputs/sun_whentocollect_plant.csv", DataFrame, select = [false, true])[!, 1]

weather = crd("data/exp_pro/inputs/sun_weather.csv", DataFrame)
rain_data = Vector{Bool}(weather[!, :Rainy])
temp_data = Vector{Float64}(weather[!, :MeanTa])

parameters = crd("data/ABC/parameters.csv", DataFrame, header = 1)

# write arrow files
Arrow.write("data/exp_pro/inputs/sun_whentocollect_rust.arrow", DataFrame(when = when_rust))
Arrow.write("data/exp_pro/inputs/sun_whentocollect_plant.arrow", DataFrame(when = when_plant))
Arrow.write("data/exp_pro/inputs/sun_weather.arrow", DataFrame(rainy = rain_data, meanT = temp_data))
Arrow.write("data/ABC/parameters.arrow", parameters)

# test read
a_rust = Arrow.Table("data/exp_pro/inputs/sun_whentocollect_rust.arrow")[1]
a_rain = Arrow.Table("data/exp_pro/inputs/sun_weather.arrow")[1]
@time a_pars = DataFrame(Arrow.Table("data/ABC/parameters.arrow"))
@time a_chunk = copy(a_pars[1:8000,:])
@time a2_chunk = @view a_pars[1:8000,:]
@time a3_chunk = DataFrame(Arrow.Table("data/ABC/parameters.arrow"))[1:8000, :]
@time c_chunk = crd("data/ABC/parameters.csv", DataFrame, header = 1, skipto = 2, limit = 8000, threaded = false)
# csv is 5 times slower
