SECTION "Header", ROM0[0x100]
  jp EntryPoint
  ds 0x150 - @, 0 ; Make room for the header

EntryPoint:
    ; Code goes here
WaitVBlank:
    ld a, [0xFF44] ; A <- LY
    cp a, 144 ; A < 144?
    jr c, WaitVBlank ; loop if yes

SECTION "Data", ROM0[0x1000]
tiles:
    INCBIN "font.2bpp"
