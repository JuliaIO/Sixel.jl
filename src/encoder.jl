# TODO: check if we can make it an immutable struct
"""
    Encoder(; kwargs...)

Create a libsixel encoder.
"""
mutable struct Encoder
    ptr::Ptr{Cvoid}
end

const DEFAULT_ENCODER = Encoder(C_NULL)
function encode(file_or_image; kwargs...)
    enc = _check_encoder!(DEFAULT_ENCODER; verbose=true)
    encode(enc, file_or_image; kwargs...)
end

"""
    encode([encoder,] img)
    encode([encoder,] filename)

Encode image `img` or image file `filename` with libsixel encoder `encoder`.

# Example

```julia
using TestImages, Sixel
img = testimage("cameraman")

Sixel.encode(img)
```

See [`Encoder`](@ref) for more information.
"""
function encode end

function encode(enc::Encoder, filename::AbstractString)
   error("Not implemented.") 
end

function encode(enc::Encoder, img::AbstractMatrix; transpose=should_transpose(img))
    # TODO: both permutedims and enforce_sixel_type allocates memory. We can mix these
    #       two operations to reduce memory allocations.
    img = enforce_sixel_type(img)

    # unsupported type C will trigger an error here
    pixelformat = default_pixelformat(img)
    palette = default_palette(img)
    ncolors = default_ncolors(img)
    
    # TODO: is this memory allocation unavoidable?
    #       (1) Maybe, for performance, we should use the low-level API?
    #       (2) is it possible to pass a buffer block to the high-level API?
    bytes = transpose ? permutedims(img, (2, 1)) : img
    width, height = size(bytes) # sixel uses row-major order
    Sixel.C.sixel_encoder_encode_bytes(enc.ptr, bytes, width, height, pixelformat, palette, ncolors)
    
    return nothing
end

# TODO: enhance this with more possibilities
should_transpose(img::AbstractMatrix) = false
should_transpose(img::Matrix) = true

# libsixel only supports 8bits format
enforce_sixel_type(img::AbstractArray{<:Colorant{N0f8}}) = img
enforce_sixel_type(img::AbstractArray{<:Colorant}) = n0f8.(img)
enforce_sixel_type(img::AbstractArray{<:Real}) = Gray{N0f8}.(img)

# TODO: these special types might have native libsixel support, but I haven't
#       figured it out yet.
enforce_sixel_type(img::AbstractArray{<:Gray24}) = Gray{N0f8}.(img)
enforce_sixel_type(img::AbstractArray{<:RGB24}) = RGB{N0f8}.(img)
enforce_sixel_type(img::AbstractArray{<:ARGB32}) = ARGB{N0f8}.(img)
# TODO: For unknown reasons, AGray and GrayA encoded by libsixel is not correctly displayed
#       in iTerm. Thus here we convert it to `ARGB` types.
enforce_sixel_type(img::AbstractArray{<:Union{AGray, GrayA}}) = ARGB{N0f8}.(img)

"""
    default_pixelformat(img)
    default_pixelformat(C)

Infer the default libsixel `pixelformat` for image `img` or colorant type `C`.
"""
default_pixelformat(::AbstractArray{C}) where C<:Colorant = default_pixelformat(C)
default_pixelformat(::Type{RGB{N0f8}})   = Sixel.C.SIXEL_PIXELFORMAT_RGB888
default_pixelformat(::Type{BGR{N0f8}})   = Sixel.C.SIXEL_PIXELFORMAT_BGR888
default_pixelformat(::Type{ARGB{N0f8}})  = Sixel.C.SIXEL_PIXELFORMAT_ARGB8888
default_pixelformat(::Type{RGBA{N0f8}})  = Sixel.C.SIXEL_PIXELFORMAT_RGBA8888
default_pixelformat(::Type{ABGR{N0f8}})  = Sixel.C.SIXEL_PIXELFORMAT_ABGR8888
default_pixelformat(::Type{BGRA{N0f8}})  = Sixel.C.SIXEL_PIXELFORMAT_BGRA8888
default_pixelformat(::Type{Gray{N0f8}})  = Sixel.C.SIXEL_PIXELFORMAT_G8
# RGB555, RGB565, BGR555, BGR565 are not provided by ColorTypes
# https://github.com/JuliaGraphics/ColorTypes.jl/issues/114
# Gray2, Gray4 are not used in JuliaImages
# TODO: Gray1, i.e., Gray{Bool} is not supported yet.

"""
    default_palette(img)
    default_patette(C)

Infer the default libsixel `palette` for image `img` or colorant type `C`.

See `SIXEL_OPTFLAG_BUILTIN_PALETTE` in `sixel.h` for a complete list.
"""
default_palette(::AbstractArray{C}) where C<:Colorant = default_palette(C)
# TODO: keep the result, evaluate the `map` once.
# TODO: and optionally use `xterm16` when the terminal does not support it.
default_palette(::Type{C}) where C<:Union{AlphaColor, ColorAlpha} = default_palette(color_type(C))
default_palette(::Type{C}) where C<:AbstractRGB = map(UInt8, collect("xterm256"))
default_palette(::Type{C}) where C<:AbstractGray = map(UInt8, collect("gray8"))

"""
    default_ncolors(img)
    default_ncolors(C)

Infer the default libsixel `ncolors` for image `img` or colorant type `C`.
    
`ncolors` is the number of colors used for given palette.
"""
default_ncolors(::AbstractArray{C}) where C<:Colorant = default_ncolors(C)
# CHECK: maybe we can just use `-1` here. The `libsixel` internal implementation seems to interprete
#        this as `SIXEL_PALETTE_MAX`.
#        https://github.com/saitoha/libsixel/blob/6a5be8b72d84037b83a5ea838e17bcf372ab1d5f/src/dither.c#L287-L289
# NOTE: we use default value 256 because we currently only support `xterm256` and `gray8` palette
#       For a complete reference, see:
#       https://github.com/saitoha/libsixel/blob/6a5be8b72d84037b83a5ea838e17bcf372ab1d5f/src/dither.c#L404-L457
default_ncolors(::Type{C}) where C<:Union{AlphaColor, ColorAlpha} = default_ncolors(color_type(C))
default_ncolors(::Type{C}) where C<:AbstractRGB = 256
default_ncolors(::Type{C}) where C<:AbstractGray = 256


function _check_encoder!(enc; verbose=true)
    if enc.ptr === C_NULL
        verbose && @info "Found Invalid encoder. Use default encoder as a fallback."
        enc.ptr = Sixel.C.sixel_encoder_create()
    end
    return enc
end
