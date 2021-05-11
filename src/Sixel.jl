module Sixel

export sixel_encode, sixel_decode

using ImageCore
import REPL: Terminals

include("interface.jl")
using .SixelInterface
const SEC = AbstractSixelEncoder
const SDC = AbstractSixelDecoder

include("terminaltools.jl")
using .TerminalTools

include("backend/libsixel/LibSixel.jl")
using .LibSixel


# Eventually we will rewrite everything in pure Julia :)
@static if Sys.iswindows()
    default_encoder(::AbstractArray) = error("Windows is not supported yet (#5).")
else
    default_encoder(::AbstractArray) = LibSixel.LibSixelEncoder()
end
# default_decoder(::AbstractArray) = LibSIxel.LibSixelDecoder()


# The high-level API to deal with different Julia input types.
#
# We assume that encoder backends perfectly understands `io::IO` and `img::Array`. Any Julia-specific
# fancy array types (e.g., transpose, view) or lazy generators, if supported, should be handled here
# instead of in the backends.
include("encoder.jl")
# include("decoder.jl)


# Ref: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
"""
    is_sixel_supported(tty=stdout)::Bool

Check if given terminal `tty` supports sixel format.

!!! warning
    (Experiment) The return value is not fully tested on all terminals and all platforms.
"""
function is_sixel_supported(tty::Base.TTY=stdout)
    '4' in TerminalTools.query_terminal("\033[0c", tty)
end
is_sixel_supported(io::IO) = false

end # module
