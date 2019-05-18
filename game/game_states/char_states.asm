main_char_states_anims_lsb:
	.byt <anim_baby_idle
	.byt <anim_baby_walk
	.byt <anim_baby_idle
	.byt <anim_baby_walk
	.byt <anim_child_idle
	.byt <anim_child_walk
	.byt <anim_child_idle
	.byt <anim_child_walk

main_char_states_anims_msb:
	.byt >anim_baby_idle
	.byt >anim_baby_walk
	.byt >anim_baby_idle
	.byt >anim_baby_walk
	.byt >anim_child_idle
	.byt >anim_child_walk
	.byt >anim_child_idle
	.byt >anim_child_walk

main_char_state_anims_direction:
	.byt 0
	.byt 0
	.byt 1
	.byt 1
	.byt 0
	.byt 0
	.byt 1
	.byt 1

; Change character's state
;  X - new state number
change_char_state:
.(
	txa
	clc
	adc char_state_anim_modifier
	tax

	lda #<main_char_anim_state
	sta tmpfield11
	lda #>main_char_anim_state
	sta tmpfield12
	lda main_char_states_anims_lsb, x
	sta tmpfield13
	lda main_char_states_anims_msb, x
	sta tmpfield14
	jsr animation_change_animation

	lda main_char_state_anims_direction, x
	sta main_char_anim_state+ANIMATION_STATE_OFFSET_DIRECTION

	rts
.)
