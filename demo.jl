using Sixel, ImageCore, TestImages, ImageInTerminal
img = testimage("cameraman")

enc = Sixel.SixelEncoder(stdout, img)
enc(img)
