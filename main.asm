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
    ld [rBGP], a
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

    ld l, 0x20 ; hl = 0x9820
    inc a ; a = 0x63
    ld de, 32
    ld b, 17
.left_loop:
    ld [hl], a
    add hl, de
    dec b
    jr nz, .left_loop

    inc a ; a = 0x64
    inc a ; a = 0x65
    ld hl, TILEMAP0 + 32 * 1 + 19 ; addr of (1, 19)
    ld b, 17
.right_loop:
    ld [hl], a
    add hl, de
    dec b
    jr nz, .right_loop

    ; Init global variables
    xor a, a
    ld [vFrameCounter], a
    ld a, 60
    ld [vPaddleX], a

    xor a, a
    ld [vBallX], a
    ld [vBallY], a

    ld a, 80
    ld [vBallX + 1], a
    ld [vBallY + 1], a

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

    ; display paddle
    ld b, 152 ; Y = 152
    ld a, [vPaddleX]
    add a, 8
    ld c, a ; X = vPaddleX + 8
    ld d, 1 ; Tile Index = 1

    ld a, b ; Y
    ld [hl+], a
    ld a, c ; X
    ld [hl+], a
    ld a, d ; Tile Index
    ld [hl+], a
    xor a, a ; Attr
    ld [hl+], a

    inc d ; Tile Index = 2

    ld a, b ; Y = 152
    ld [hl+], a
    ld a, c ; X = vPaddleX + 16
    add a, 8
    ld [hl+], a
    ld a, d ; Tile Index = 2
    ld [hl+], a
    xor a, a ; Attr
    ld [hl+], a

    ld a, b ; Y = 152
    ld [hl+], a
    ld a, c ; X = vPaddleX + 24
    add a, 16
    ld [hl+], a
    ld a, d ; Tile Index = 2
    ld [hl+], a
    xor a, a ; Attr
    ld [hl+], a

    inc d ; Tile Index = 3

    ld a, b ; Y = 152
    ld [hl+], a
    ld a, c ; X = vPaddleX + 32
    add a, 24
    ld [hl+], a
    ld a, d ; Tile Index = 3
    ld [hl+], a
    xor a, a ; Attr
    ld [hl+], a

    ; print(Text, 0x98E5)
    ; ld bc, Text
    ; ld hl, 0x98E5
    ; call PrintFn

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
    ld b, a

    ; Calculate position change

    ld a, [vPaddleX]
    ld c, 2 ; Paddle speed
    
    bit 0, b ; is bit 0 in a set? (right key)
    jr z, .skip_right ; if not, skip
    cp a, 120 ; X < 120?
    jr nc, .skip_right ; skip if no
    add a, c
.skip_right:

    bit 1, b ; is bit 1 in a set? (left key)
    jr z, .skip_left ; if not, skip
    cp a, 9 ; X < 9?
    jr c, .skip_left ; skip if yes
    sub a, c
.skip_left:

    ld [vPaddleX], a

    ; Wait for VBlank
.waitVBlank:
    ld a, [rLY] ; A <- LY
    cp a, LY_VBLANK ; A < 144?
    jr c, .waitVBlank ; loop if yes

    ; Update paddle coordinates
    ld hl, STARTOF(OAM) + 5
    ld bc, 4

    ld a, [vPaddleX]

    add a, 8
    ld [hl], a
    add hl, bc

    add a, 8
    ld [hl], a
    add hl, bc

    add a, 8
    ld [hl], a
    add hl, bc

    add a, 8
    ld [hl], a

    ; Wait for the start of new frame
.waitFrame:
    ld a, [rLY] ; A <- LY
    cp a, LY_VBLANK ; A < 144?
    jr nc, .waitFrame ; loop if no
    jp MainLoop

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


SECTION "Global", HRAM
vFrameCounter: db
vPaddleX: db
vBallX: dw
vBallY: dw
