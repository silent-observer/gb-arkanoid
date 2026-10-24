main.gb: main.raw.gb
	rgbfix -v -p 0xFF -o $@ $^

main.raw.gb: main.o
	rgblink -o $@ $^

%.o: %.asm
	rgbasm -o $@ $<

%.2bpp: %.png
	rgbgfx -o $@ $<

main.asm: ball.2bpp font.2bpp block.2bpp paddle.2bpp bg.2bpp hardware.inc
