# SixelIOBuffer is a workaround solution:
# If we directly pass `IOBuffer` to `SixelEncoder`, the information (e.g., `io.ptr`, `io.size`) is
# not updated during `sixel_write_callback_function`, thus we wrap it as a struct, record it, and
# restore it.
mutable struct SixelIOBuffer <: IO
    io::IOBuffer
    data::Vector{UInt8}
    readable::Bool
    writable::Bool
    seekable::Bool
    append::Bool
    size::Int
    ptr::Int
    maxsize::Int
    mark::Int
    function SixelIOBuffer(io::IOBuffer)
        new(io, io.data, io.readable, io.writable, io.seekable, io.append, io.size, io.ptr, io.maxsize, io.mark)
    end
end

Base.write(io::SixelIOBuffer, A::Array) = write(io.io, A)

Base.convert(::Type{IOBuffer}, io::SixelIOBuffer) = io.io

function Base.show(io::IO, buf::SixelIOBuffer)
    println(io,
        "SixelIOBuffer(data=UInt8[...]",
        ", readable=", buf.readable,
        ", writable=", buf.writable,
        ", seekable=", buf.seekable,
        ", append=",   buf.append,
        ", size=",     buf.size,
        ", maxsize=",  buf.maxsize==typemax(Int) ? "Inf" : buf.maxsize,
        ", ptr=",      buf.ptr,
        ", mark=",     buf.mark,
        ")"
    )
end


maybe_convert(::Type{SixelIOBuffer}, io) = io
maybe_convert(::Type{SixelIOBuffer}, io::IOBuffer) = SixelIOBuffer(io)

"""
    maybe_store!(io)

Copy the field contents of `io.io` to `io`.
"""
maybe_store!(io::IO) = io
function maybe_store!(io::SixelIOBuffer)
    for fn in fieldnames(typeof(io.io))
        setproperty!(io, fn, getproperty(io.io, fn))
    end
    return io
end

maybe_restore!(io::IO) = io
function maybe_restore!(io::SixelIOBuffer)
    for fn in fieldnames(typeof(io.io))
        setproperty!(io.io, fn, getproperty(io, fn))
    end
    return io
end
