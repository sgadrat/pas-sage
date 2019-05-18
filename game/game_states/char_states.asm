main_char_states_anims_lsb:
	.byt <anim_baby_idle
	.byt <anim_baby_walk

main_char_states_anims_msb:
	.byt >anim_baby_idle
	.byt >anim_baby_walk

; Change character's state
;  X - new state number
change_char_state:
.(
	lda #<main_char_anim_state
	sta tmpfield11
	lda #>main_char_anim_state
	sta tmpfield12
	lda main_char_states_anims_lsb, x
	sta tmpfield13
	lda main_char_states_anims_msb, x
	sta tmpfield14
	jsr animation_change_animation

	rts
.)
