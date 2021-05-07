abstract type AbstractEncoder end

struct SixelEncoder{I<:IO} <: AbstractEncoder
    io::I
    colorbits::Int
    pixelformat::Int

    # (Experimental) internal fields

    # We need `allocator` to constructor libsixel objects, however, users of this
    # Julia package is not expected to use this field as it really should just live
    # in the C world.
    allocator::SixelAllocator
end

function SixelEncoder(io::IO, img::AbstractArray)
    allocator = SixelAllocator()

    colorbits = default_colorbits(img)
    pixelformat = default_pixelformat(img)
    SixelEncoder(io, colorbits, pixelformat, allocator)
end

function sixel_write_callback_function(buffer_ptr::Ptr{Cchar}, sz::Cint, priv::Ref{T})::Cint where {T<:IO}
    io = unsafe_load(Base.unsafe_convert(Ptr{T}, priv))
    buffer = unsafe_wrap(Array{Cchar}, buffer_ptr, (sz, ))
    write(io, buffer)
end

function (enc::SixelEncoder{T})(img::AbstractMatrix; transpose=true) where {T<:IO}
    img = transpose ? PermutedDimsArray(img, (2, 1)) : img
    bytes = enforce_sixel_type(img)
    bytes === img && transpose && (bytes = collect(bytes))

    width, height = size(bytes)
    depth = 3 # unused

    dither = SixelDither(bytes, width, height, enc.pixelformat; allocator=enc.allocator)

    # This runtime function only lives in local scope so we have to define it here
    # If we predefine it and `output` in the `SixelEncoder` constructor, it throws
    # runtime unknown function segmentation fault.
    # Well.. This is all I can get with my limited understanding of C and C-Julia interop.
    # function fn_write_local(buffer_ptr, sz, priv)
    #     buffer = unsafe_wrap(Array{Cchar}, buffer_ptr, (sz, ); own=false)
    #     # io = unsafe_load(priv)
    #     Cint(write(enc.io, buffer))
    # end
    fn_write_cb = @cfunction(sixel_write_callback_function, Cint, (Ptr{Cchar}, Cint, Ref{T}))
    output = SixelOutput(fn_write_cb, Ref{T}(enc.io); allocator=enc.allocator)

    status = Sixel.C.sixel_encode(bytes, width, height, depth, dither.ptr, output.ptr)
    check_status(status)
    return nothing
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
