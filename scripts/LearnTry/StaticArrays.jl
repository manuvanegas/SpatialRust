@elapsed using StaticArrays

tu = @SVector zeros(10)

function mod_tu(tu, ids)
    tv = Float64[]
    for i in eachindex(tu)
        if i in ids
            push!(tv, 2.0)
        else
            push!(tv, 1.0)
        end
    end
    return SVector{10}(tv)
end

mod_tu(tu, [1,4])

tv = @SVector ones(10)

tx = tu + tv

tx[2]
