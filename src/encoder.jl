const SEC = AbstractSixelEncoder

# TODO: support `src::IO`

sixel_encode(img::AbstractArray, enc::SEC=default_encoder(img); kwargs...) = sixel_encode(stdout, img, enc; kwargs...)
sixel_encode(io::IO, img::AbstractVector, enc::SEC; kwargs...) = sixel_encode(io, reshape(img, :, 1), enc; kwargs...)

# This is expected to be the only caller of `enc(io, bytes)`; all other methods should eventually
# call this one.
function sixel_encode(
        io::IO,
        img::AbstractMatrix,
        enc::SEC;
        transpose=true,
        kwargs...)
    T = canonical_sixel_eltype(enc, eltype(img))
    AT = Array{T, ndims(img)}
    bytes = transpose ? convert(AT, PermutedDimsArray(img, (2, 1))) : convert(AT, img)
    enc(io, bytes)
end
