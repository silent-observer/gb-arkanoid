INCLUDE "hardware.inc"

SECTION "Header", ROM0[0x100]
  jp EntryPoint
  ds 0x150 - @, 0 ; Make room for the header

EntryPoint:
    ; Code goes here
WaitVBlank:
    ld a, [rLY] ; A <- LY
    cp a, LY_VBLANK ; A < 144?
    jr c, WaitVBlank ; loop if yes

    ; Turn off LCD
    xor a, a
    ld [rLCDC], a

    ; Copy tile data
    ld bc, Tiles ; source
    ld hl, TILEBLOCK2 ; destination
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
    ld hl, TILEMAP0
    ld de, 1024
ZeroTileMapLoop:
    xor a, a
    ld [hl+], a
    dec de
    ld a, d
    or a, e ; a = d | e
    jr nz, ZeroTileMapLoop

    ; Hardcode text
    ld hl, 0x98E5
    ld a, 0x28 ; 'H'
    ld [hl+], a
    ld a, 0x45 ; 'e'
    ld [hl+], a
    ld a, 0x4C ; 'l'
    ld [hl+], a
    ld [hl+], a
    ld a, 0x4F ; 'o'
    ld [hl+], a

    ; Turn on LCD
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a

Done:
    jr Done

SECTION "Data", ROM0[0x1000]
Tiles:
    INCBIN "font.2bpp"
.End:
    