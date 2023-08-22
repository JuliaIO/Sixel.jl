struct LibSixelEncoder <: AbstractSixelEncoder
    # (Experimental) internal fields

    # We need `allocator` to constructor libsixel objects, however, users of this
    # Julia package is not expected to use this field as it really should just live
    # in the C world.
    allocator::SixelAllocator

    function LibSixelEncoder(allocator=SixelAllocator())
        new(allocator)
    end
end

function sixel_write_callback_function(buffer_ptr::Ptr{Cchar}, sz::Cint, priv::Ref{T})::Cint where {T<:IO}
    unsafe_write(priv[], buffer_ptr, sz)
end

# libsixel backend requires contiguous memeory layout, to avoid unexpected bugs
# we limit ourself to `Matrix` type and let the frontend API `sixel_encode` transforms
# other fancy array types into `Matrix`.
function (enc::LibSixelEncoder)(io::T, bytes::Matrix) where {T<:IO}
    # colorbits = default_colorbits(bytes)
    pixelformat = default_pixelformat(bytes)
    quality_mode = default_quality_mode(bytes)

    height, width = size(bytes)
    depth = 3 # unused

    dither = SixelDither(bytes, height, width, pixelformat, quality_mode; allocator=enc.allocator)
    C.sixel_dither_set_transparent(dither.ptr, eltype(bytes) <: TransparentColor ? 0 : -1)

    fn_write_cb = @cfunction(sixel_write_callback_function, Cint, (Ptr{Cchar}, Cint, Ref{T}))
    output = SixelOutput(fn_write_cb, Ref{T}(io); allocator=enc.allocator)

    status = C.sixel_encode(bytes, height, width, depth, dither.ptr, output.ptr)
    check_status(status)

    return nothing
end


"""
    default_pixelformat(img)
    default_pixelformat(CT)

Infer the default libsixel `pixelformat` for image `img` or colorant type `CT`.
"""
default_pixelformat(::AbstractArray{CT}) where CT<:Union{Colorant, Real} = default_pixelformat(CT)
default_pixelformat(::Type{RGB{N0f8}})   = C.SIXEL_PIXELFORMAT_RGB888
default_pixelformat(::Type{BGR{N0f8}})   = C.SIXEL_PIXELFORMAT_BGR888
default_pixelformat(::Type{ARGB{N0f8}})  = C.SIXEL_PIXELFORMAT_ARGB8888
default_pixelformat(::Type{RGBA{N0f8}})  = C.SIXEL_PIXELFORMAT_RGBA8888
default_pixelformat(::Type{ABGR{N0f8}})  = C.SIXEL_PIXELFORMAT_ABGR8888
default_pixelformat(::Type{BGRA{N0f8}})  = C.SIXEL_PIXELFORMAT_BGRA8888
default_pixelformat(::Type{Gray{N0f8}})  = C.SIXEL_PIXELFORMAT_G8
default_pixelformat(::Type{T}) where T<:Union{N0f8, UInt8}  = C.SIXEL_PIXELFORMAT_G8
# RGB555, RGB565, BGR555, BGR565 are not provided by ColorTypes
# https://github.com/JuliaGraphics/ColorTypes.jl/issues/114
# Gray2, Gray4 are not used in JuliaImages
# TODO: Gray1, i.e., Gray{Bool} is not supported yet.

"""
    default_quality_mode(img)
    default_quality_mode(CT)

Infer the default quality mode that is used to encode pixel.
"""
default_quality_mode(::AbstractArray{CT}) where CT<:Union{Colorant, Real} = default_quality_mode(CT)
default_quality_mode(::Type{CT}) where CT<:TransparentRGB = C.SIXEL_QUALITY_AUTO
default_quality_mode(::Type{CT}) where CT<:AbstractRGB = C.SIXEL_QUALITY_AUTO
# CHECK: highcolor is needed for iTerm2 on macOS, check if this works on other terminal
default_quality_mode(::Type{CT}) where CT<:AbstractGray = C.SIXEL_QUALITY_HIGHCOLOR
default_quality_mode(::Type{T}) where T<:Union{N0f8, UInt8} = C.SIXEL_QUALITY_HIGHCOLOR


canonical_sixel_eltype(::LibSixelEncoder, ::Type{CT}) where CT<:Colorant = n0f8(CT)
canonical_sixel_eltype(::LibSixelEncoder, ::Type{CT}) where CT<:Color3 = RGB{N0f8}
canonical_sixel_eltype(::LibSixelEncoder, ::Type{CT}) where CT<:Transparent3 = RGBA{N0f8}
canonical_sixel_eltype(::LibSixelEncoder, ::Type{T}) where T<:Real = N0f8
canonical_sixel_eltype(::LibSixelEncoder, ::Type{T}) where T<:Integer = UInt8
