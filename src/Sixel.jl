module Sixel

export sixel_encode, sixel_decode

using ImageCore
import REPL: Terminals

include("interface.jl")
using .SixelInterface

include("backend/libsixel/LibSixel.jl")
using .LibSixel


# Eventually we will rewrite everything in pure Julia :)
default_encoder(::AbstractArray) = LibSixel.LibSixelEncoder()
# default_decoder(::AbstractArray) = LibSIxel.LibSixelDecoder()


# The high-level API to deal with different Julia input types.
#
# We assume that encoder backends perfectly understands `io::IO` and `img::Array`. Any Julia-specific
# fancy array types (e.g., transpose, view) or lazy generators, if supported, should be handled here
# instead of in the backends.
include("encoder.jl")
# include("decoder.jl)

end # module
