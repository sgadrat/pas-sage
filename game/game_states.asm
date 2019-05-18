; Subroutine called when the state change to this state
game_states_init:
VECTOR(ingame_init)
VECTOR(gameover_init)

; Subroutine called each frame
game_states_tick:
VECTOR(ingame_tick)
VECTOR(gameover_tick)

; Game states named constants
GAMESTATE_INGAME = $00
GAMESTATE_GAMEOVER = $01

#include "game/game_states/ingame.asm"
#include "game/game_states/gameover.asm"
