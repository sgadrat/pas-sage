; Subroutine called when the state change to this state
game_states_init:
VECTOR(ingame_init)

; Subroutine called each frame
game_states_tick:
VECTOR(ingame_tick)

#include "game/game_states/ingame.asm"
