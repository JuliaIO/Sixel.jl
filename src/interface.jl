# Provide the interface as a module so that different sub-modules can reuse the symbols for dispatching
module SixelInterface

export AbstractSixelDecoder,
       AbstractSixelEncoder,
       sixel_encode,
       sixel_decode,
       canonical_sixel_eltype

abstract type AbstractSixelEncoder end
(enc::AbstractSixelEncoder)(io, src) = error("The encoder functor method for inputs (::$(typeof(io)), ::$(typeof(src)) is not implemented.")

abstract type AbstractSixelDecoder end
(enc::AbstractSixelDecoder)(io, src) = error("The decoder functor method for inputs (::$(typeof(io)), ::$(typeof(src)) is not implemented.")

"""
    sixel_encode(io, src, [encoder]) -> io

Encode colorant sequence `src` as sixel sequence and write it into a writable io-like object `io` as output.

# Arguments

- `io`: the output io-like object, which is expected to be writable.
- `src`: generic container object(e.g., `IO`, `AbstractArray`) that contains the colorant sequence.
- `encoder::AbstractSixelEncoder`: the sixel encoder.

# References

- [1] VT330/VT340 Programmer Reference Manual, Volume 1: Text Programming
- [2] VT330/VT340 Programmer Reference Manual, Volume 2: Graphics Programming
- [3] https://github.com/saitoha/libsixel
"""
function sixel_encode(::Any, ::Any, ::AbstractSixelEncoder) end

"""
    sixel_decode(io, src, [decoder]) -> io

Decode the sixel format sequence provided by `src` and write into a writable io-like object `io` as output.

# Arguments

- `io`: the output io-like object, which is expected to be writable.
- `src`: generic container object(e.g., `IO`, `AbstractArray`, `AbstractString`) that contains the sixel format sequence.
- `decoder::AbstractSixelDecoder`: the sixel decoder.

# References

- [1] VT330/VT340 Programmer Reference Manual, Volume 1: Text Programming
- [2] VT330/VT340 Programmer Reference Manual, Volume 2: Graphics Programming
- [3] https://github.com/saitoha/libsixel
"""
function sixel_decode(::Any, ::Any, ::AbstractSixelDecoder) end

"""
    canonical_sixel_eltype(enc, CT1) -> CT2

Given input type `CT1`, infer the expected colorant type `CT2` for encoder `enc`. This function is
used to early convert the image data into formats that backend encoder (e.g., the C libsixel) understands.
"""
function canonical_sixel_eltype(::AbstractSixelEncoder, ::DataType) end

end # module
