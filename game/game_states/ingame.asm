#include "game/game_states/bg_data.asm"
#include "game/game_states/bg_palettes.asm"

palettes_data:
; Background
.byt $0d,$01,$11,$21, $0d,$05,$15,$25, $0d,$01,$07,$10, $0d,$0c,$1c,$2c
; Sprites
.byt $0d,$0d,$37,$20, $0d,$0d,$0d,$0d, $0d,$0d,$0d,$0d, $0d,$0d,$0d,$0d

nametable_data:
.byt ZIPNT_ZEROS(32*7)
.byt ZIPNT_ZEROS(32*7+12)
.byt                                                                $01, $01, $01, $01,  $01
.byt ZIPNT_ZEROS(15+12)
.byt                                                                $01, $01, $01, $01,  $01
.byt ZIPNT_ZEROS(15+12)
;    -------------------  -------------------  -------------------  -------------------  -------------------  -------------------  -------------------  -------------------
.byt                                                                $01, $01, $01, $01,  $01
.byt ZIPNT_ZEROS(15+32*7)
.byt ZIPNT_ZEROS(32*6)
nametable_attributes:
.byt ZIPNT_ZEROS(8*8)
.byt ZIPNT_END

camera_x_lsb = $03
camera_x_msb = $04

next_bg_column = $05
next_bg_column_msb = $06

next_bg_palette = $07
next_bg_palette_msb = $08
bg_palettes_mirror = $0400 ; to $0417 - 24 bytes

main_char_anim_state = $0418 ; to $0423 - 12 bytes

; Initialization routine for ingame state
ingame_init:
.(
	; Point PPU to Background palette 0 (see http://wiki.nesdev.com/w/index.php/PPU_palettes)
	lda PPUSTATUS
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR

	; Write palette_data in actual ppu palettes
	ldx #$00
	copy_palette:
	lda palettes_data, x
	sta PPUDATA
	inx
	cpx #$20
	bne copy_palette

	; Copy background from PRG-rom to PPU nametable
	lda #<nametable_data
	sta tmpfield1
	lda #>nametable_data
	sta tmpfield2
	jsr draw_zipped_nametable

	; Init camera's position
	lda #$00
	sta camera_x_lsb
	sta camera_x_msb

	; Set next_bg_column to to the 1st column
	lda #<bg_data
	sta next_bg_column
	lda #>bg_data
	sta next_bg_column_msb

	; Set next_bg_palette to the 1st column
	lda #<bg_palettes
	sta next_bg_palette
	lda #>bg_palettes
	sta next_bg_palette_msb

	; Draw first tile and palette collum as we are on pixel 0
	jsr new_tile_column
	jsr new_palette

	; Initialize main character animation
	lda #<main_char_anim_state
	sta tmpfield11
	lda #>main_char_anim_state
	sta tmpfield12
	lda #<anim_baby_walk
	sta tmpfield13
	lda #>anim_baby_walk
	sta tmpfield14
	jsr animation_init_state

	lda #$80
	sta main_char_anim_state+ANIMATION_STATE_OFFSET_X_LSB
	sta main_char_anim_state+ANIMATION_STATE_OFFSET_Y_LSB

	rts
.)

; Tick routine for ingame state
ingame_tick:
.(
	; Reset processed nt buffers
	jsr reset_nt_buffers

	; Check up button
	.(
		lda controller_a_btns
		and #CONTROLLER_BTN_UP
		beq ok

			;TODO

		ok:
	.)

	; Check left button
	.(
		lda controller_a_btns
		and #CONTROLLER_BTN_LEFT
		beq ok

			;TODO

		ok:
	.)

	; Check right button
	.(
		lda controller_a_btns
		and #CONTROLLER_BTN_RIGHT
		beq ok

			; Move camera
			inc camera_x_lsb
			bne end_inc_camera
				inc camera_x_msb
			end_inc_camera:

			; If camera is on a multiple of height, draw the next column
			lda camera_x_lsb
			and #%00000111
			bne end_redraw
				jsr new_tile_column
			end_redraw:

			; If camera is on a multiple of 16, set the next column's palette
			lda camera_x_lsb
			and #%00001111
			bne end_palette
				jsr new_palette
			end_palette:

			; Update PPU scroll
			lda camera_x_lsb
			sta scroll_x

		ok:
	.)

	; Check down button
	.(
		lda controller_a_btns
		and #CONTROLLER_BTN_DOWN
		beq ok

			;TODO

		ok:
	.)

	;
	; Draw the character
	;

	lda #<main_char_anim_state ;
	sta tmpfield11             ; The animation state to draw
	lda #>main_char_anim_state ;
	sta tmpfield12             ;
	lda #0         ;
	sta tmpfield13 ;
	sta tmpfield14 ; Camera position (let it as 0/0, character is actually placed)
	sta tmpfield15 ;
	sta tmpfield16 ;
	jsr animation_draw

	; Advance animation one tick
	jsr animation_tick

	rts
.)

new_tile_column:
.(
		; NT buffer header
		jsr last_nt_buffer
		lda ppuctrl_val ; Continuation byte
		ora #%00000100
		sta nametable_buffers, x
		inx
		lda #$21 ; PPU address
		sta nametable_buffers, x
		inx
		lda camera_x_lsb ; PPU address = $40 + camera_x / 8
		lsr
		lsr
		lsr
		clc
		adc #$40
		sta nametable_buffers, x
		inx
		lda #10 ; Number of tiles
		sta nametable_buffers, x
		inx

		; Data from bg_data
		ldy #0
		copy_one_bg_byte
			lda (next_bg_column), y
			iny
			sta nametable_buffers, x
			inx

			cpy #10
			bne copy_one_bg_byte

		; Unset next continuation byte
		lda #0
		sta nametable_buffers, x

		; Update bg column vector
		lda #10
		clc
		adc next_bg_column
		sta next_bg_column
		lda #0
		adc next_bg_column_msb
		sta next_bg_column_msb

		rts
.)

new_palette:
.(
	is_left_palette = tmpfield1
	palette_side_mask = tmpfield2

	;
	; Update palettes mirror
	;

	; X = palette column byte = camera x / 32
	; is_left_palete is set if we are setting the left palettes of the byte
	; palette_side_mask contains 1s on bits to overwrite in palette column byte
	lda camera_x_lsb
	lsr
	lsr
	lsr
	lsr
	lsr
	tax
	bcc left_palette
		lda #%00110011
		sta palette_side_mask
		lda #0
		jmp set_palette_side
	left_palette:
		lda #%11001100
		sta palette_side_mask
		lda #1
	set_palette_side:
		sta is_left_palette

	;y = 0
	;for i = 0; i < 3; ++i
	;	bg_palettes_mirror, x & palette_side_mask
	;	a = (next_bg_palette), y
	;	iny
	;	if !is_left_palette
	;		a = a << 2
	;	bg_palettes_mirror, x = bg_palettes_mirror, x | a
	;	x += 8
	ldy #0
	handle_one_byte:
		
		; Erase bits relative to rewriten palette indexes from attributes mirror
		lda palette_side_mask
		and bg_palettes_mirror, x
		sta bg_palettes_mirror, x

		; Read the new palette index byte, and adapt it to its side
		.(
			lda is_left_palette
			beq left
				lda (next_bg_palette), y
				jmp ok
			left:
				lda (next_bg_palette), y
				asl
				asl
			ok:
		.)
		iny

		; Patch attribute mirror with palette byte
		ora bg_palettes_mirror, x
		sta bg_palettes_mirror, x

		; Next byte to patch is one row bellow
		txa
		clc
		adc #8
		tax

		; Loop on three data bytes
		cpy #3
		bne handle_one_byte

	; Advance bg palette by one column
	lda #3
	clc
	adc next_bg_palette
	sta next_bg_palette
	lda #0
	adc next_bg_palette_msb
	sta next_bg_palette_msb

	;
	; Copy palettes mirror in a NT buffer
	;

	jsr last_nt_buffer
	lda ppuctrl_val ; Continuation byte (horizontal)
	and #%11111011
	sta nametable_buffers, x
	inx
	lda #$23 ; PPU address
	sta nametable_buffers, x
	inx
	lda #$D0 ; PPU address
	sta nametable_buffers, x
	inx
	lda #24 ; Number of tiles
	sta nametable_buffers, x
	inx

	.(
		ldy #0
		copy_one_byte:
			lda bg_palettes_mirror, y
			iny
			sta nametable_buffers, x
			inx

			cpy #24
			bne copy_one_byte
	.)

	lda #0
	sta nametable_buffers, x

	rts
.)
