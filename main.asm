SECTION "Header", ROM0[0x100]
  jp EntryPoint
  ds 0x150 - @, 0 ; Make room for the header

EntryPoint:
    ; Code goes here
WaitVBlank:
    ld a, [0xFF44] ; A <- LY
    cp a, 144 ; A < 144?
    jr c, WaitVBlank ; loop if yes

    ; Turn off LCD
    xor a, a
    ld [0xFF40], a

    ; Copy tile data
    ld bc, 0x1000
    ld hl, 0x9000
    ld de, 1536
CopyTilesLoop:
    ld a, [bc]
    ld [hl+], a
    inc bc
    dec de
    ld a, d
    or a, e ; a = d | e
    jr nz, CopyTilesLoop

Done:
    jr Done

SECTION "Data", ROM0[0x1000]
tiles:
    INCBIN "font.2bpp"
