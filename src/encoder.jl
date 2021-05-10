const SEC = AbstractSixelEncoder

# TODO: support `src::IO`

sixel_encode(img::AbstractArray, enc::SEC=default_encoder(img); kwargs...) = sixel_encode(stdout, img, enc; kwargs...)
sixel_encode(io::IO, img::AbstractVector, enc::SEC; kwargs...) = sixel_encode(io, reshape(img, :, 1), enc; kwargs...)

function sixel_encode(
        tty::Base.TTY,
        img::AbstractArray{<:Any, 3},
        enc::SEC=default_encoder(img);
        dims=3,
        transpose=true,
        kwargs...)
    # TODO: keep more information by not clearing the terminal
    term = Terminals.TTYTerminal("", stdin, tty, stderr)
    Terminals.clear(term)

    for i in axes(img, dims)
        bytes = selectdim(img, dims, i)
        @assert ndims(bytes) == 2
        sixel_encode(tty, bytes, enc)
        i != last(axes(img, dims)) && write(tty, "\033[H") # set cursor to topleft
    end
    return nothing
end

function sixel_encode(
        io::IO,
        img::AbstractArray{<:Any, 3},
        enc::SEC=default_encoder(img);
        dims=3,
        transpose=true,
        kwargs...)
    height = transpose ? size(img, 2) : size(img, 1)
    for bytes in eachslice(img, dims=dims)
        @assert ndims(bytes) == 2
        sixel_encode(io, bytes, enc)
    end
    return nothing
end


# This is expected to be the only caller of `enc(io, bytes)`; all other methods should eventually
# call this one.
function sixel_encode(
        io::IO,
        img::AbstractMatrix,
        enc::SEC=default_encoder(img);
        transpose=true,
        kwargs...)
    T = canonical_sixel_eltype(enc, eltype(img))
    AT = Array{T, ndims(img)}
    bytes = transpose ? convert(AT, PermutedDimsArray(img, (2, 1))) : convert(AT, img)
    enc(io, bytes)
    return nothing
end
