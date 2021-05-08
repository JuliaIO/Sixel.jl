abstract type AbstractEncoder end

struct SixelEncoder{T<:IO} <: AbstractEncoder
    io::T

    # (Experimental) internal fields

    # We need `allocator` to constructor libsixel objects, however, users of this
    # Julia package is not expected to use this field as it really should just live
    # in the C world.
    allocator::SixelAllocator
end

function SixelEncoder(io::IO, img::AbstractArray)
    allocator = SixelAllocator()
    SixelEncoder(io, allocator)
end

function Base.show(io::IO, enc::SixelEncoder{T}) where T
    print(io, "SixelEncoder(::", typeof(io), ")")
end

function sixel_write_callback_function(buffer_ptr::Ptr{Cchar}, sz::Cint, priv::Ref{T})::Cint where {T<:IO}
    unsafe_write(priv[], buffer_ptr, sz)
end

function (enc::SixelEncoder{T})(img::AbstractMatrix; transpose=true) where {T<:IO}
    img = transpose ? PermutedDimsArray(img, (2, 1)) : img
    bytes = enforce_sixel_type(img)
    bytes === img && transpose && (bytes = collect(bytes))

    # colorbits = default_colorbits(bytes)
    pixelformat = default_pixelformat(bytes)
    quality_mode = default_quality_mode(bytes)
    width, height = size(bytes)
    depth = 3 # unused

    dither = SixelDither(bytes, width, height, pixelformat, quality_mode; allocator=enc.allocator)

    fn_write_cb = @cfunction(sixel_write_callback_function, Cint, (Ptr{Cchar}, Cint, Ref{T}))
    output = SixelOutput(fn_write_cb, Ref{T}(enc.io); allocator=enc.allocator)

    status = Sixel.C.sixel_encode(bytes, width, height, depth, dither.ptr, output.ptr)
    check_status(status)

    return nothing
end


"""
    sixel_encode([io=stdout], img)

Encode bytes array `img` as sixel control sequence.
"""
sixel_encode(img::AbstractArray) = sixel_encode(stdout, img)
function sixel_encode(io::IO, img::AbstractArray)
    enc = SixelEncoder(io, img)
    enc(img)
end

# libsixel only supports at most 8bits format
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
    default_colorbits(img)
    default_colorbits(C)

Infer the default number of bits that used to represent a color.
"""
default_colorbits(::AbstractArray{C}) where C<:Colorant = default_colorbits(C)
default_colorbits(::Type{C}) where C<:Union{AlphaColor, ColorAlpha} = default_colorbits(color_type(C))
default_colorbits(::Type{C}) where C<:AbstractRGB = 8
default_colorbits(::Type{C}) where C<:AbstractGray = 8

"""
    default_quality_mode(img)
    default_quality_mode(C)

Infer the default quality mode that used to encode pixel.
"""
default_quality_mode(::AbstractArray{C}) where C<:Colorant = default_quality_mode(C)
default_quality_mode(::Type{CT}) where CT<:AbstractRGB = C.SIXEL_QUALITY_AUTO
# CHECK: highcolor is needed for iTerm2 on macOS, check if this works on other terminal
default_quality_mode(::Type{CT}) where CT<:AbstractGray = C.SIXEL_QUALITY_HIGHCOLOR
