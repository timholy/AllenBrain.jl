module AllenBrain

using Statistics
using JSON, LightGraphs, IndirectArrays, AxisArrays, OffsetArrays
using StaticArrays, CoordinateTransformations
using ImageMagick, ImageTransformations, ImageCore, Interpolations
using ColorVectorSpace
using IntervalSets, ProgressMeter, FileIO
using Unitful: μm
using Requires
import HTTP

export #
    # basic types
    BoundingBox,
    buffer,
    # ontology
    ontology,
    findvertices,
    structureids,
    boundingbox,
    # image loading, query, and download
    annotation,
    download_annotation,
    download_projection,
    query_reference2image,
    query_image2reference,
    sectionimage,
    download_insitu_images,
    splice_sectionimages,
    # genes
    query_insitu,
    # visualization
    colorize,
    colorize!,
    visualize_volume

const mousedir = joinpath(dirname(@__DIR__), "data", "mouse")

function dataset(species, category)
    if category == "ontology"
        species == "mouse" && return joinpath(mousedir, "structure_graph.json")
    elseif startswith(category, "annotation") && species == "mouse"
        if !endswith(category, ".nrrd")
            if !ismatch(r"[0-9]$", category)
                category = category*"_25"
            end
            category = category*".nrrd"
        end
        return joinpath(mousedir, category)
    end
    error(category, " for species ", species, " not found")
end

@inline mapfilter(f, t, ::Type{Axis{name}}, axs) where name =
    _mapfilter(f, t, Axis{name}, axs...)
@inline _mapfilter(f, t, ::Type{Axis{name}}, ::Axis{name}, axs...) where name =
    (f(t[1]), _mapfilter(f, Base.tail(t), Axis{name}, axs...)...)
@inline _mapfilter(f, t, ::Type{Axis{name}}, ::Axis, axs...) where name =
    (t[1], _mapfilter(f, Base.tail(t), Axis{name}, axs...)...)
_mapfilter(f, ::Tuple{}, ::Type{Axis{name}}) where name = ()

inmicrons(x::Real) = x
inmicrons(x) = x/(1μm)

include("types.jl")
include("ontology.jl")
include("images.jl")
include("projections.jl")
include("genes.jl")
include("visualize.jl")

function __init__()
    # NOTE: this was written against GLVisualize which is deprecated for
    # Makie. The code below likely needs updating.
    @require Makie="ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a" begin
        function visualize_volume(volumedata)
            window = Makie.glscreen()
            volume = Makie.visualize(volumedata, :absorption)
            Makie._view(volume, window)
            @schedule Makie.renderloop(window)
        end
    end
end

end # module
