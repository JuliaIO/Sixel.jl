const SEC = AbstractSixelEncoder

# TODO: support `src::IO`

sixel_encode(img::AbstractArray, enc::SEC=default_encoder(img)) = sixel_encode(stdout, img, enc)
function sixel_encode(io::IO, img::AbstractArray, enc::SEC)
    enc(io, img)
end
