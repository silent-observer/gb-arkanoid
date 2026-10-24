main.gb: main.raw.gb
	rgbfix -v -p 0xFF -o $@ $^

main.raw.gb: main.o
	rgblink -o $@ $^

%.o: %.asm
	rgbasm -o $@ $<

%.2bpp: %.png
	rgbgfx -o $@ $<
