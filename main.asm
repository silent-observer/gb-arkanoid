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
    call CopyFn

    ; Copy object tile data
    ld bc, ObjTiles ; source
    ld hl, TILEBLOCK0 ; destination
    ld de, ObjTiles.End - ObjTiles ; counter
    call CopyFn

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

    ; Turn on LCD
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a

    WaitVBlank2:
    ld a, [rLY] ; A <- LY
    cp a, LY_VBLANK ; A < 144?
    jr c, WaitVBlank2 ; loop if yes

    ; print(Text, 0x98E5)
    ld bc, Text
    ld hl, 0x98E5
    call PrintFn

Done:
    jr Done

; BC is src_addr
; HL is dst_addr
; DE is count
; A is overwritten
CopyFn:
.loop:
    ld a, [bc]
    ld [hl+], a
    inc bc
    dec de
    ld a, d
    or a, e ; a = d | e
    jr nz, .loop
    ret

; BC is string_addr
; HL is tilemap_addr
; A is overwritten
; DE is not affected
PrintFn:
.loop:
    ld a, [bc] ; a <- [string_addr]
    or a, a ; set flags according to a
    ret z ; if a == 0: return
    sub a, 0x20 ; a -= 0x20
    ld [hl+], a ; [tilemap_addr] <- a
    inc bc
    jr .loop ; loop back

SECTION "Data", ROM0[0x1000]
Tiles:
    INCBIN "font.2bpp"
.End:
ObjTiles:
    INCBIN "ball.2bpp"
.End:

Text:
    db "Hello world!", 0
