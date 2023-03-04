using DataFrames, Arrow
using SpatialRust

tdf = DataFrame(
    p_row = [1,2], 
    max_inf = [0.5,0.6], 
    host_spo_inh = [0.5,1.5], 
    opt_g_temp = [22.0, 23.0], 
    max_g_temp = [28.0, 31.0], 
    spore_pct = [0.5, 0.8], 
    rust_paras = [0.1, 0.01], 
    exh_threshold = [0.5,0.1], 
    rain_distance = [1.0, 2.0], 
    tree_block = [0.6, 0.9], 
    wind_distance = [2.0, 5.0], 
    shade_block = [0.3,0.5], 
    lesion_survive =[0.2, 0.5]
)

when_rust = Vector(Arrow.Table("data/exp_pro/input/whentocollect.arrow")[1])
when_2017 = filter(d -> d < 200, when_rust)
when_2018 = filter(d -> d > 200, when_rust)
w_table = Arrow.Table("data/exp_pro/input/weather.arrow")
temp_data = Tuple(w_table[2])
rain_data = Tuple(w_table[3])
wind_data = Tuple(w_table[4]);

touts = map(p -> sim_abc(p, temp_data, rain_data, wind_data, when_2017, when_2018), eachrow(tdf))
tquant, tqual = reduce(cat_dfs, touts)