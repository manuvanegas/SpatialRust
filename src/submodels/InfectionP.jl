function tcalc_wetness_p(local_temp)
    w = (-0.5/16.0) * local_temp + (0.5*30.0/16.0)
end

plot(12.0:30.0, tcalc_wetness_p.(12.0:30.0))
