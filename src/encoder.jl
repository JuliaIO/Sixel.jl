sixel_encode(img::AbstractArray, enc::SEC=default_encoder(img); kwargs...) = sixel_encode(stdout, img, enc; kwargs...)
sixel_encode(io::IO, img::AbstractVector, enc::SEC=default_encoder(img); kwargs...) = sixel_encode(io, reshape(img, :, 1), enc; kwargs...)

function sixel_encode(io::IO, img::AbstractArray, enc::SEC=default_encoder(img); transpose=true, kwargs...)
    # make sure it always tiles along row order
    nrow = transpose ? 1 : prod(size(img)[3:end])
    sixel_encode(io, mosaicview(img; nrow=nrow, rowmajor=true), enc; transpose=transpose, kwargs...)
end

# This is expected to be the only caller of `enc(io, bytes)`; all other methods should eventually
# call this one.
function sixel_encode(
        io::IO,
        img::AbstractMatrix,
        enc::SEC=default_encoder(img);
        transpose=true)
    T = canonical_sixel_eltype(enc, eltype(img))
    AT = Array{T, ndims(img)}
    bytes = transpose ? convert(AT, PermutedDimsArray(img, (2, 1))) : convert(AT, img)
    enc(io, bytes)
    return nothing
end
