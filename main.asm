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
    ld hl, STARTOF(OAM)
    ld de, OAM_SIZE
    call ZeroFn

    ; Set palletes
    ld a, 0b11_10_01_00
    ld [rOBP0], a
    ld [rOBP1], a

    ; Init background
    ld hl, TILEMAP0
    ld a, 0x60
    ld [hl+], a

    inc a ; a = 0x61
    ld b, 18
.top_loop:
    ld [hl+], a
    dec b
    jr nz, .top_loop

    inc a ; a = 0x62
    ld [hl+], a

    ; Turn on LCD
    ld a, LCDC_ON | LCDC_BG_ON | LCDC_OBJ_ON
    ld [rLCDC], a

    WaitVBlank2:
    ld a, [rLY] ; A <- LY
    cp a, LY_VBLANK ; A < 144?
    jr c, WaitVBlank2 ; loop if yes

    ; display object
    ld hl, STARTOF(OAM)
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
    ld a, JOYP_GET_BUTTONS
    ld [rJOYP], a
    call .do_nothing
    ld a, [rJOYP]
    ld a, [rJOYP]
    ld a, [rJOYP]
    and a, 0x0F
    swap a
    ld b, a

    ld a, JOYP_GET_CTRL_PAD
    ld [rJOYP], a
    call .do_nothing
    ld a, [rJOYP]
    ld a, [rJOYP]
    ld a, [rJOYP]
    and a, 0x0F
    or a, b
    xor a, 0xFF

    ; Calculate position change
    ld bc, 0 ; Δy <- 0, Δx <- 0

    bit 0, a ; is bit 0 in a set? (right key)
    jr z, .skip_right ; if not, skip
    inc c
.skip_right:

    bit 1, a ; is bit 1 in a set? (left key)
    jr z, .skip_left ; if not, skip
    dec c
.skip_left:

    bit 2, a ; is bit 2 in a set? (up key)
    jr z, .skip_up ; if not, skip
    dec b
.skip_up:

    bit 3, a ; is bit 3 in a set? (down key)
    jr z, .skip_down ; if not, skip
    inc b
.skip_down:

    ; Wait for VBlank
.waitVBlank:
    ld a, [rLY] ; A <- LY
    cp a, LY_VBLANK ; A < 144?
    jr c, .waitVBlank ; loop if yes

    ; Only execute every 5th frame
    ld a, [vFrameCounter]
    inc a
    cp a, 5
    jr nz, .skip

    ; Update ball coordinates
    ld hl, STARTOF(OAM)
    ld a, [hl]
    add a, b
    ld [hl+], a
    ld a, [hl]
    add a, c
    ld [hl+], a

    xor a, a
.skip:
    ld [vFrameCounter], a
    jr MainLoop

.do_nothing:
    ret

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
    INCBIN "bg.2bpp"
    INCBIN "block.2bpp"
.End:
ObjTiles:
    INCBIN "ball.2bpp"
    INCBIN "paddle.2bpp"
.End:

Text:
    db "Hello world!", 0


SECTION "Global", WRAM0
vFrameCounter: db
