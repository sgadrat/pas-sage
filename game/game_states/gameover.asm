gameover_palettes_data:
; Background
.byt $0d,$10,$10,$10, $0d,$0d,$0d,$0d, $0d,$0d,$0d,$0d, $0d,$0d,$0d,$0d
; Sprites
.byt $0d,$06,$25,$22, $0d,$0d,$0d,$0d, $0d,$0d,$0d,$0d, $0d,$0d,$0d,$0d

gameover_nametable_data:
.byt ZIPNT_ZEROS(32*7)
.byt ZIPNT_ZEROS(32*7)
.byt ZIPNT_ZEROS(32+10)
.byt                                                     $01, $02,  $03, $04, $05, $06,  $07, $08, $09, $0a,  $0b
.byt ZIPNT_ZEROS(11+18)
;    -------------------  -------------------  -------------------  -------------------  -------------------  -------------------  -------------------  -------------------
.byt                                                                                               $0c
.byt ZIPNT_ZEROS(13+32*7)
.byt ZIPNT_ZEROS(32*6)
gameover_nametable_attributes:
.byt ZIPNT_ZEROS(8*8)
.byt ZIPNT_END

gameover_init:
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
	lda gameover_palettes_data, x
	sta PPUDATA
	inx
	cpx #$20
	bne copy_palette

	; Copy background from PRG-rom to PPU nametable
	lda #<gameover_nametable_data
	sta tmpfield1
	lda #>gameover_nametable_data
	sta tmpfield2
	jsr draw_zipped_nametable

	rts
.)

gameover_tick:
.(
	; Press start to restart the game
	lda controller_a_btns
	bne end
		lda controller_a_last_frame_btns
		cmp #CONTROLLER_BTN_START
		bne end
			lda #GAMESTATE_INGAME
			jsr change_global_game_state

	end:
	rts
.)
