using CSV, DataFrames, Agents
using CairoMakie


filename = "byaroccexhinc"
# filename = "byarexhincid"
ests = CSV.read(string("results/ABC/params/sents/novar/", filename, "_pointestimate.csv"), DataFrame)
ests
meanofmeans(agents, prop) = emean(mean(getproperty(a, prop)) for a in agents)

steps = 455

model = init_spatialrust(
    steps = steps, 
    start_days_at = 115,
    common_map = :fullsun,
    rain_data = rain_data,
    wind_data = wind_data,
    temp_data = temp_data,
    ini_rusts = 0.01,
    prune_sch = [15,166,-1],
    inspect_period = steps,
    fungicide_sch = Int[],
    target_shade = 0.15,
    shade_g_rate = 0.008;
    ests[1, :]...
)


meanofmeans(a) = emean(mean.(a))

adf, mdf = run!(
    model, dummystep, step_model!, steps;
    adata = [(:production, emean, active), (:areas, meanofmeans, active)]
)

rename!(adf, [:step, :prod_mn, :area_mn])

plot(adf.step, adf.prod_mn)
plot(adf.step, adf.area_mn)

