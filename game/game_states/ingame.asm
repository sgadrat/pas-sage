#include "game/game_states/bg_data.asm"
#include "game/game_states/bg_palettes.asm"
#include "game/game_states/events.asm"

palettes_data:
; Background
.byt $0d,$01,$0a,$1a, $0d,$31,$32,$20, $0d,$01,$07,$10, $0d,$01,$06,$28
; Sprites
.byt $0d,$0d,$37,$20, $0d,$0d,$08,$37, $0d,$0d,$0d,$0d, $0d,$0d,$0d,$0d

camera_x_lsb = $03
camera_x_msb = $04

next_bg_column = $05
next_bg_column_msb = $06

next_bg_palette = $07
next_bg_palette_msb = $08
bg_palettes_mirror = $0400 ; to $0417 - 24 bytes

main_char_state = $09
main_char_anim_state = $0418 ; to $0423 - 12 bytes
main_char_x = main_char_anim_state+ANIMATION_STATE_OFFSET_X_LSB
char_state_anim_modifier = $0a

scroll_lock = $0b
next_event = $0c

CHAR_STATE_IDLE = 0
CHAR_STATE_WALK_RIGHT = 1
CHAR_STATE_IDLE_LEFT = 2
CHAR_STATE_WALK_LEFT = 3

PUSH_SCREEN_LINE = $60
GAMEOVER_LINE = $0104

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

	; Draw the first screen of columns
	jsr draw_first_screen

	; Init camera's position
	lda #$00
	sta camera_x_lsb
	sta camera_x_msb

	; Draw first tile and palette collum as we are on pixel 0
	jsr new_tile_column
	jsr new_palette

	; Initialize main character animation state
	lda #<main_char_anim_state
	sta tmpfield11
	lda #>main_char_anim_state
	sta tmpfield12
	lda #<anim_baby_walk
	sta tmpfield13
	lda #>anim_baby_walk
	sta tmpfield14
	jsr animation_init_state

	lda #PUSH_SCREEN_LINE/3
	sta main_char_anim_state+ANIMATION_STATE_OFFSET_X_LSB
	lda #$98
	sta main_char_anim_state+ANIMATION_STATE_OFFSET_Y_LSB
	lda #10
	sta main_char_anim_state+ANIMATION_STATE_OFFSET_FIRST_SPRITE_NUM
	lda #62
	sta main_char_anim_state+ANIMATION_STATE_OFFSET_LAST_SPRITE_NUM

	; Initialize main character state
	lda #0
	sta char_state_anim_modifier
	ldx #CHAR_STATE_IDLE
	sta main_char_state
	jsr change_char_state

	; No scroll lock at the begining
	lda #0
	sta scroll_lock

	; Initialize events system
	lda #0
	sta next_event

	; Place 10 sprites to hide rightmost screen column
	ldx #0*4
	ldy #79
	place_one_sprite:
		; Set sprite's Y coord to value in register Y and update register Y
		tya
		sta oam_mirror, x
		inx
		clc
		adc #8
		tay

		; Tile number - solid 1
		lda #$01
		sta oam_mirror, x
		inx

		; Attributes
		lda #0
		sta oam_mirror, x
		inx

		; X coord
		lda #$f8
		sta oam_mirror, x
		inx

		; Loop
		cpx #10*4
		bne place_one_sprite

	rts
.)

; Tick routine for ingame state
ingame_tick:
.(
	; Reset processed nt buffers
	jsr reset_nt_buffers

	; Check left button
	.(
		lda controller_a_btns
		and #CONTROLLER_BTN_LEFT
		beq ok

			; Change char state if we just pressed the button
			cmp controller_a_last_frame_btns
			beq end_state_change
				ldx #CHAR_STATE_WALK_LEFT
				stx main_char_state
				jsr change_char_state
			end_state_change:

			; Chose what to do
			lda main_char_x
			cmp #$10
			beq end_action
				dec main_char_x
			end_action:

		ok:
	.)

	; Check right button
	.(
		lda controller_a_btns
		and #CONTROLLER_BTN_RIGHT
		beq ok

			; Change char state if we just pressed the button
			cmp controller_a_last_frame_btns
			beq end_state_change
				ldx #CHAR_STATE_WALK_RIGHT
				stx main_char_state
				jsr change_char_state
			end_state_change:

			; Chose what to do
			lda scroll_lock
			beq no_scroll_lock

				; Scroll lock - the char is permited to leave the screen
				inc main_char_x
				bne end_inc_char_x
					inc main_char_anim_state+ANIMATION_STATE_OFFSET_X_MSB
				end_inc_char_x:

				; When char leaves the screen, go thanks for playing state
				lda main_char_x
				cmp #<GAMEOVER_LINE
				bne no_gamestate_change
				lda main_char_anim_state+ANIMATION_STATE_OFFSET_X_MSB
				cmp #>GAMEOVER_LINE
				bne no_gamestate_change
					lda #GAMESTATE_GAMEOVER
					jsr change_global_game_state
				no_gamestate_change:

				jmp end_action

			no_scroll_lock:

				; No scroll lock - move the char or push the screen
				lda main_char_x
				cmp #PUSH_SCREEN_LINE
				bne move_char
					jsr move_screen
					jmp end_action
				move_char:
					inc main_char_x

			end_action:

		ok:
	.)

	; Check no button
	.(
		lda controller_a_btns
		bne ok

			; Change state if we just gone to this config
			cmp controller_a_last_frame_btns
			beq ok
				lda main_char_state
				cmp #CHAR_STATE_WALK_LEFT
				beq left
				cmp #CHAR_STATE_IDLE_LEFT
				beq left
					ldx #CHAR_STATE_IDLE
					jmp direction_chosen
				left:
					ldx #CHAR_STATE_IDLE_LEFT
				direction_chosen:

				stx main_char_state
				jsr change_char_state

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

	move_screen:
	.(
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

		; Call scroll event
		ldx next_event
		lda events_pos_lsb, x
		cmp camera_x_lsb
		bne end_events
		lda events_pos_msb, x
		cmp camera_x_msb
		bne end_events

			lda events_handler_lsb, x
			sta tmpfield1
			lda events_handler_msb, x
			sta tmpfield2
			inx
			stx next_event
			jsr call_pointed_subroutine

		end_events:

		rts
	.)
.)

draw_first_screen:
.(
	; Draw tile and palette columns for the first screen
	lda #0
	sta camera_x_lsb
	draw_one_column:
		; Draw tile column
		jsr new_tile_column

		; Draw palettes column if on an even column
		lda camera_x_lsb
		and #%00001111
		bne end_palette
			jsr new_palette
		end_palette:

		; Process generated buffers immediatly (we need disabled rendering)
		jsr process_nt_buffers
		jsr reset_nt_buffers

		; Loop
		lda #8
		clc
		adc camera_x_lsb
		sta camera_x_lsb
		bne draw_one_column

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
	ora #%01000000
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

#include "game/game_states/char_states.asm"
#include "game/game_states/event_handlers.asm"
