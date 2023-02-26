# from https://github.com/MakieOrg/Makie.jl/blob/master/src/basic_recipes/raincloud.jl

####
#### Helper functions to make the cloud plot!
####
function cloud_plot_check_args(category_labels, data_array)
    length(category_labels) == length(data_array) || DimensionMismatch("Length of category_labels must match with length of data_array")
    return nothing
end

# Allow to globally set jitter RNG for testing
# A bit of a lazy solution, but it doesn't seem to be desirably to
# pass the RNG through the plotting command
# const RAINCLOUD_RNG = Ref{Random.AbstractRNG}(Random.GLOBAL_RNG)

# quick custom function for jitter
rand_localized(min, max) = rand_localized(Random.GLOBAL_RNG, min, max)
rand_localized(RNG::Random.AbstractRNG, min, max) = rand(RNG) * (max - min) .+ min

@recipe(LessScatterRainClouds, category_labels, data_array) do scene
    return Attributes(
        side = :left,
        orientation = :vertical,
        center_boxplot = true,
        # Cloud plot
        cloud_width = 0.75,
        violin_limits = (-Inf, Inf),
        # Box Plot Settings
        boxplot_width = 0.1,
        whiskerwidth =  0.5,
        strokewidth = 1.0,
        show_median = true,
        boxplot_nudge = 0.075,

        gap = 0.2,
        markersize = 2.0,
        dodge = Makie.automatic,
        n_dodge = Makie.automatic,
        dodge_gap = 0.01,
        n_dots = 100,

        plot_boxplots = true,
        show_boxplot_outliers = false,
        clouds = violin,
        hist_bins = 30,

        color = theme(scene, :patchcolor),
        cycle = [:color => :patchcolor],
    )
end

# create_jitter_array(length_data_array; jitter_width = 0.1, clamped_portion = 0.1)
# Returns a array containing random values with a mean of 0, and a values from `-jitter_width/2.0` to `+jitter_width/2.0`, where a portion of a values are clamped right at the edges.
function create_jitter_array(length_data_array; jitter_width = 0.1, clamped_portion = 0.1)
    jitter_width < 0 && ArgumentError("`jitter_width` should be positive.")
    !(0 <= clamped_portion <= 1) || ArgumentError("`clamped_portion` should be between 0.0 to 1.0")

    # Make base jitter, note base jitter minimum-to-maximum span is 1.0
    base_min, base_max = (-0.5, 0.5)
    jitter = [rand_localized(base_min, base_max) for _ in 1:length_data_array]

    # created clamp_min, and clamp_max to clamp a portion of the data
    @assert (base_max - base_min) == 1.0
    @assert (base_max + base_min) / 2.0 == 0
    clamp_min = base_min + (clamped_portion / 2.0)
    clamp_max = base_max - (clamped_portion / 2.0)

    # clamp if need be
    clamp!(jitter, clamp_min, clamp_max)

    # Based on assumptions of clamp_min and clamp_max above
    jitter = jitter * (0.5jitter_width / clamp_max)

    return jitter
end

####
#### Functions that make the cloud plot
####
function Makie.plot!(
        ax::Makie.Axis, P::Type{<: LessScatterRainClouds},
        allattrs::Attributes, category_labels, data_array)

    plot = plot!(ax.scene, P, allattrs, category_labels, data_array)

    if any(x -> x isa AbstractString, category_labels)
        ulabels = unique(category_labels)
        if !haskey(allattrs, :orientation) || allattrs.orientation[] === :vertical
            ax.xticks = (1:length(ulabels), ulabels)
        else
            ax.yticks = (1:length(ulabels), ulabels)
        end
    end
    if haskey(allattrs, :title)
        ax.title = allattrs.title[]
    end
    if haskey(allattrs, :xlabel)
        ax.xlabel = allattrs.xlabel[]
    end
    if haskey(allattrs, :ylabel)
        ax.ylabel = allattrs.ylabel[]
    end
    reset_limits!(ax)
    return plot
end

function group_labels(category_labels, data_array)
    grouped = Dict{eltype(category_labels), Vector{Int}}()
    for (label, data_ix) in zip(category_labels, axes(data_array,1))
        push!(get!(grouped, label, eltype(data_array)[]), data_ix)
    end

    return pairs(grouped)
end

function ungroup_labels(category_labels, data_array)
    if eltype(data_array) <: AbstractVector
        @warn "Using a nested array for raincloud is deprected. Read raincloud's documentation and update your usage accordingly."
        data_array_ = reduce(vcat, data_array)
        category_labels_ = similar(category_labels, length(data_array_))
        ix = 0
        for (i, da) in enumerate(data_array)
            category_labels_[axes(da, 1) .+ ix] .= category_labels[i]
            ix += size(da, 1)
        end
        return category_labels_, data_array_
    end
    return category_labels, data_array
end

function convert_arguments(::Type{<: LessScatterRainClouds}, category_labels, data_array)
    cloud_plot_check_args(category_labels, data_array)
    return (category_labels, data_array)
end

function Makie.plot!(plot::LessScatterRainClouds)
    category_labels = plot.category_labels[]
    data_array = plot.data_array[]
    category_labels, data_array = ungroup_labels(category_labels, data_array)
    if any(ismissing, data_array)
        error("missing values in data not supported. Please filter out any missing values before plotting")
    end

    # Checking kwargs, and assigning defaults if they are not in kwargs
    # General Settings
    # Define where categories should lie
    x_positions = if any(x -> x isa AbstractString, category_labels)
        labels = unique(category_labels)
        pos = Dict(label => i for (i, label) in enumerate(labels))
        [pos[label] for label in category_labels]
    else
        category_labels
    end

    side = plot.side[]
    center_boxplot_bool = plot.center_boxplot[]
    # Cloud plot
    cloud_width =  plot.cloud_width[]
    cloud_width[] < 0 && ArgumentError("`cloud_width` should be positive.")

    # Box Plot Settings
    boxplot_width = plot.boxplot_width[]
    whiskerwidth = plot.whiskerwidth[]
    strokewidth = plot.strokewidth[]
    show_median = plot.show_median[]
    boxplot_nudge = plot.boxplot_nudge[]

    plot_boxplots = plot.plot_boxplots[]
    clouds = plot.clouds[]
    hist_bins = plot.hist_bins[]

    # Scatter Plot defaults dependent on if there is a boxplot
    side_scatter_nudge_default = plot_boxplots ? 0.2 : 0.075
    jitter_width_default = 0.05

    # Scatter Plot Settings
    side_scatter_nudge = to_value(get(plot, :side_nudge, side_scatter_nudge_default))
    side_scatter_nudge < 0 && ArgumentError("`side_nudge` should be positive. Change `side` to :left, :right if you wish.")
    jitter_width = abs(to_value(get(plot, :jitter_width, jitter_width_default)))
    jitter_width < 0 && ArgumentError("`jitter_width` should be positive.")
    markersize = plot.markersize[]


    # Set-up
    if plot.orientation[] === :horizontal
        # flip side to when horizontal
        side = side === :left ? :right : :left
    end
    (side === :left) && (side_nudge_direction = 1.0)
    (side === :right) && (side_nudge_direction = -1.0)
    side_scatter_nudge_with_direction = side_scatter_nudge * side_nudge_direction
    side_boxplot_nudge_with_direction = boxplot_nudge * side_nudge_direction

    recenter_to_boxplot_nudge_value = center_boxplot_bool ? side_boxplot_nudge_with_direction : 0.0
    plot_boxplots || (recenter_to_boxplot_nudge_value = 0.0)
    # Note: these cloud plots are horizontal
    full_width = jitter_width + side_scatter_nudge +
        (plot_boxplots ? boxplot_width : 0) +
        (!isnothing(clouds) ? 1 + abs(recenter_to_boxplot_nudge_value) : 0)

    final_x_positions, width = Makie.compute_x_and_width(x_positions .+ recenter_to_boxplot_nudge_value/2, full_width,
                                                    plot.gap[], plot.dodge[],
                                                    plot.n_dodge[], plot.dodge_gap[])
    width_ratio = width / full_width

    ## Edited here
    # groupeddata = group_labels(category_labels, data_array)
    thelabels = unique(category_labels)
    npars = length(first(values(group_labels(category_labels, data_array))))
    randidx = rand(1:npars, plot.n_dots[])
    longidx = Int[]
    for i in eachindex(thelabels)
        append!(longidx, randidx .+ (npars * (i - 1)))
    end
    # randidx = rand(1:length(data_array), plot.n_dots[])
    # longidx = randidx
    jitterdata = data_array[longidx]
    jitter = create_jitter_array(length(jitterdata);
                                    jitter_width = jitter_width*width_ratio)

    if !isnothing(clouds)
        if clouds === violin
            violin!(plot, final_x_positions .- recenter_to_boxplot_nudge_value.*width_ratio, data_array;
                    show_median=show_median, side=side, width=width_ratio*cloud_width, plot.cycle,
                    datalimits=plot.violin_limits, plot.color, gap=0, orientation=plot.orientation[])
        elseif clouds === hist
            edges = pick_hist_edges(data_array, hist_bins)
            # dodge belongs below: it ensure that the histogram groups labels by both dodge
            # and category (so there is a separate histogram for each dodge group)
            groupings = if plot.dodge[] isa MakieCore.Automatic
                category_labels
            else
                zip(category_labels, plot.dodge[])
            end
            for (_, ixs) in group_labels(groupings, data_array)
                isempty(ixs) && continue
                xoffset = final_x_positions[ixs[1]] - recenter_to_boxplot_nudge_value
                hist!(plot, view(data_array, ixs); offset=xoffset,
                        scale_to=(side === :left ? -1 : 1)*cloud_width*width_ratio, bins=edges,
                        # yes, we really do want :x when orientation is :vertical
                        # an :x directed histogram has a vertical orientation
                        direction=plot.orientation[] === :vertical ? :x : :y,
                        color=getuniquevalue(plot.color[], ixs))
            end
        else
            error("cloud attribute accepts (violin, hist, nothing), but not: $(clouds)")
        end
    end

    # And here
    c_name = plot.color[][1]
    c_alpha = plot.color[][2] - 0.3
    scatter_x = final_x_positions[longidx] .+ side_scatter_nudge_with_direction.*width_ratio .+
                jitter .- recenter_to_boxplot_nudge_value.*width_ratio
    if plot.orientation[] === :vertical
        scatter!(plot, scatter_x, jitterdata; markersize=markersize, color = (c_name, c_alpha), plot.cycle)
    else
        scatter!(plot, jitterdata, scatter_x; markersize=markersize, color = (c_name, c_alpha), plot.cycle)
    end

    if plot_boxplots
        boxplot!(plot, final_x_positions .+ side_boxplot_nudge_with_direction.*width_ratio .-
                 recenter_to_boxplot_nudge_value.*width_ratio,
                 data_array;
                 plot.orientation,
                 strokewidth=strokewidth,
                 whiskerwidth=whiskerwidth*width_ratio,
                 width=boxplot_width*width_ratio,
                 markersize=markersize,
                 show_outliers=plot.show_boxplot_outliers[],
                 color=plot.color,
                 cycle=plot.cycle)
    end

    return plot
end