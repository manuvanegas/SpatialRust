using DataFrames, Arrow
using SpatialRust

tdf = DataFrame(
    p_row = [1,2, 3], 
    max_inf = [0.5,0.4, 0.044], 
    host_spo_inh = [5.0, 4.0, 13.11], 
    opt_g_temp = [23.0, 23.0, 21.93], 
    max_g_temp = [31.0, 31.0, 29.74], 
    spore_pct = [0.5, 0.5, 0.875], 
    rust_paras = [0.05, 0.3, 0.691], 
    exh_threshold = [0.01,1.5, 1.211], 
    rain_distance = [5.0, 5.0, 9.282], 
    tree_block = [0.5, 0.5, 0.291], 
    wind_distance = [15.0, 15.0, 11.595], 
    shade_block = [0.5,0.5, 0.316], 
    lesion_survive =[0.5, 0.5, 0.533],
    rust_gr = [0.15, 0.9, 0.179],
    rep_gro = [2.0, 3.0, 1.062],
    shade_g_rate = [0.008, 0.008, 0.008],
    target_shade = [0.15, 0.15, 0.15]
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