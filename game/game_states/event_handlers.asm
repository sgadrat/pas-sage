event_handler_end_scroll:
.(
	lda #1
	sta scroll_lock
	rts
.)

event_handler_become_child:
.(
	lda #4
	sta char_state_anim_modifier
	ldx main_char_state
	jsr change_char_state
	rts
.)

event_handler_become_adult:
.(
	lda #8
	sta char_state_anim_modifier
	ldx main_char_state
	jsr change_char_state
	rts
.)
