#include "game/game_states/bg_data.asm"

palettes_data:
; Background
.byt $20,$21,$15,$1a, $20,$0d,$0d,$0d, $20,$0d,$0d,$0d, $20,$0d,$0d,$0d
; Sprites
.byt $20,$06,$25,$22, $20,$0d,$0d,$0d, $20,$0d,$0d,$0d, $20,$0d,$0d,$0d

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

				; NT buffer header
				jsr last_nt_buffer
				lda #$01 ; Continuation byte
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

				; Update bg column vector
				lda #10
				clc
				adc next_bg_column
				sta next_bg_column
				lda #0
				adc next_bg_column_msb
				sta next_bg_column_msb

			end_redraw:

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

	;TODO
	;; Call animation_draw with its parameter
	;lda #<heart_animation_state ;
	;sta tmpfield11              ; The animation state to draw
	;lda #>heart_animation_state ;
	;sta tmpfield12              ;
	;lda #0         ;
	;sta tmpfield13 ;
	;sta tmpfield14 ; Camera position (let it as 0/0)
	;sta tmpfield15 ;
	;sta tmpfield16 ;
	;jsr animation_draw

	;; Advance animation one tick
	;jsr animation_tick

	rts
.)
