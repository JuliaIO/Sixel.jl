@testset "encoder" begin
    @testset "1d vector" begin
        for img in (
            repeat(Gray.(0:0.1:0.9), inner=10),
            repeat(distinguishable_colors(10), inner=(10, ))
        )
            @info "1d vector: eltype(img)"
            @test size(img) == (100, )

            enc = Sixel.default_encoder(img)
            @test enc isa Sixel.LibSixel.LibSixelEncoder
            test_sixel_display() do
                sixel_encode(img, enc)
                println()
            end

            io = IOBuffer()
            sixel_encode(io, img, enc)
            bufferdata = String(take!(io))
            sz = 1, size(img, 1)
            w, h = ceil.(Int, 12 ./ sz) .* sz # small images are repeated to larger size
            @test startswith(bufferdata, "\ePq\"1;1;$w;$h") && endswith(bufferdata, "\e\\")
            test_sixel_display() do
                println(bufferdata)
            end

            tmp_file = tempname()
            open(tmp_file, "w") do io
                sixel_encode(io, img, enc)
            end
            filedata = read(tmp_file, String)
            @test startswith(filedata, "\ePq\"1;1;$w;$h") && endswith(filedata, "\e\\")
            test_sixel_display() do
                println(filedata)
            end

            @info "transpose=false"
            test_sixel_display() do
                sixel_encode(img, enc; transpose=false)
            end
        end
    end

    @testset "2d matrix" begin
        for img in (
            repeat(Gray.(0:0.1:0.9), inner=(10, 50)),
            repeat(distinguishable_colors(10), inner=(10, 50))
        )
            @info "2d vector: $(eltype(img))"
            h, w = size(img)
            @test size(img) == (100, 50)

            enc = Sixel.default_encoder(img)
            @test enc isa Sixel.LibSixel.LibSixelEncoder
            test_sixel_display() do
                sixel_encode(img, enc)
                println()
            end
            io = IOBuffer()
            sixel_encode(io, img, enc)
            bufferdata = String(take!(io))
            @test startswith(bufferdata, "\ePq\"1;1;$w;$h") && endswith(bufferdata, "\e\\")
            test_sixel_display() do
                println(bufferdata)
            end

            tmp_file = tempname()
            open(tmp_file, "w") do io
                sixel_encode(io, img, enc)
            end
            filedata = read(tmp_file, String)
            @test startswith(filedata, "\ePq\"1;1;$w;$h") && endswith(filedata, "\e\\")
            test_sixel_display() do
                println(filedata)
            end

            @info "transpose=false"
            test_sixel_display() do
                sixel_encode(img, enc; transpose=false)
            end
        end
    end

    @testset "3d array" begin
        for img in (
            repeat(Gray.(0:0.1:0.9), inner=(10, 50, 3)),
            repeat(distinguishable_colors(5), inner=(20, 50, 3))
        )
            @info "3d array: $(eltype(img))"
            @test size(img) == (100, 50, 3)

            enc = Sixel.default_encoder(img)
            @test enc isa Sixel.LibSixel.LibSixelEncoder
            test_sixel_display() do
                sixel_encode(img, enc)
                println()
            end
            io = IOBuffer()
            sixel_encode(io, img, enc)
            bufferdata = String(take!(io))
            h, w, c = size(img)
            w = w * c
            @test startswith(bufferdata, "\ePq\"1;1;$w;$h") && endswith(bufferdata, "\e\\")
            test_sixel_display() do
                println(bufferdata)
            end

            tmp_file = tempname()
            open(tmp_file, "w") do io
                sixel_encode(io, img, enc)
            end
            filedata = read(tmp_file, String)
            h, w, c = size(img)
            w = w * c
            @test startswith(filedata, "\ePq\"1;1;$w;$h") && endswith(filedata, "\e\\")
            test_sixel_display() do
                println(filedata)
            end

            @info "transpose=false"
            test_sixel_display() do
                sixel_encode(img, enc; transpose=false)
            end
            io = IOBuffer()
            sixel_encode(io, img, enc; transpose=false)
            bufferdata = String(take!(io))
            h, w, c = size(img)
            h = h * c
            h, w = w, h # transpose
            @test startswith(bufferdata, "\ePq\"1;1;$w;$h") && endswith(bufferdata, "\e\\")
        end
    end

    @testset "various color spaces" begin
        @info "The images below should visually look the same"
        img = repeat(distinguishable_colors(5), inner=(20, 50))
        for T in (
            RGB{N0f8}, RGB{Float32}, RGB24,
            HSV, Lab, ARGB, RGBA, BGR, BGRA
        )
            sixel_encode(T.(img))
        end
    end

    @testset "untypical array types" begin
        # lazy array that does not occupy full memory
        img = Diagonal(repeat(distinguishable_colors(5), inner=20))
        w, h = size(img)
        io = IOBuffer()
        sixel_encode(io, img)
        bufferdata = String(take!(io))
        @test startswith(bufferdata, "\ePq\"1;1;$w;$h") && endswith(bufferdata, "\e\\")
        test_sixel_display() do
            println(bufferdata)
        end

        # array that has un-contiguous memory layout
        ori_img = repeat(distinguishable_colors(5), inner=(20, 50))
        img = PermutedDimsArray(permutedims(ori_img, (2, 1)), (2, 1))
        @test size(img) == (100, 50) == size(ori_img)
        @test stride(img, 1) == 50
        @test stride(ori_img, 1) == 1

        io = IOBuffer()
        sixel_encode(io, ori_img)
        bufferdata = String(take!(io))
        h, w = size(ori_img)
        @test startswith(bufferdata, "\ePq\"1;1;$w;$h") && endswith(bufferdata, "\e\\")
        io = IOBuffer()
        sixel_encode(io, img)
        @test bufferdata == String(take!(io))

        io = IOBuffer()
        sixel_encode(io, ori_img, transpose=false)
        bufferdata = String(take!(io))
        h, w = size(ori_img)
        h, w = w, h # transpose
        @test startswith(bufferdata, "\ePq\"1;1;$w;$h") && endswith(bufferdata, "\e\\")
        io = IOBuffer()
        sixel_encode(io, img, transpose=false)
        @test bufferdata == String(take!(io))
    end
end
