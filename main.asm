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
    call ZeroFn

    ; Zero out OAM
    ld hl, 0xFE00
    ld de, OAM_SIZE
    call ZeroFn

    ; Set palletes
    ld a, 0b11_10_01_00
    ld [rOBP0], a
    ld [rOBP1], a

    ; Turn on LCD
    ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON
    ld [rLCDC], a

    WaitVBlank2:
    ld a, [rLY] ; A <- LY
    cp a, LY_VBLANK ; A < 144?
    jr c, WaitVBlank2 ; loop if yes

    ; display object
    ld hl, 0xFE00
    ld a, 100
    ld [hl+], a
    ld a, 150
    ld [hl+], a
    xor a, a
    ld [hl+], a
    ld [hl+], a

    ; print(Text, 0x98E5)
    ld bc, Text
    ld hl, 0x98E5
    call PrintFn

MainLoop:
    ; Read inputs
    ; Calculate position change
    ; Wait for VBlank
    ; Update ball coordinates
    jr MainLoop

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

; HL is dst_addr
; DE is count
; A is overwritten
; BC is preserved
ZeroFn:
.loop:
    xor a, a
    ld [hl+], a
    dec de
    ld a, d
    or a, e ; a = d | e
    jr nz, .loop

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
