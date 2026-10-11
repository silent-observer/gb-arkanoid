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
    ld bc, Tiles ; source
    ld hl, 0x9000 ; destination
    ld de, Tiles.End - Tiles ; counter
CopyTilesLoop:
    ld a, [bc]
    ld [hl+], a
    inc bc
    dec de
    ld a, d
    or a, e ; a = d | e
    jr nz, CopyTilesLoop

    ; Zero out the tile map
    ld hl, 0x9800
    ld de, 1024
ZeroTileMapLoop:
    xor a, a
    ld [hl+], a
    dec de
    ld a, d
    or a, e ; a = d | e
    jr nz, ZeroTileMapLoop

    ; Turn on LCD
    ld a, 0x88
    ld [0xFF40], a

Done:
    jr Done

SECTION "Data", ROM0[0x1000]
Tiles:
    INCBIN "font.2bpp"
.End:
