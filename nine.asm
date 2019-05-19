; Building the project
;  tools/generate_events.py assets/events.json > game/game_states/events.asm
;  tools/generate_animations.py tiles assets/animations.json > game/chr_rom_sprites.asm
;  tools/generate_animations.py anims assets/animations.json > game/animations/animations.asm
;  tools/generate_bg_data.py tilemap assets/gameover_tiles.json assets/dummy_bg.gif > game/game_states/bg_data.asm
;  tools/generate_bg_data.py tiles assets/gameover_tiles.json assets/dummy_bg.gif > game/chr_rom_bg.asm
;  tools/generate_bg_data.py palettes assets/gameover_tiles.json assets/dummy_bg.gif > game/game_states/bg_palettes.asm
;  xa nine.asm -C -o game\(E\).nes

; iNES header

#include "nine/ines_header.asm"

; No-data declarations

#include "nine/constants.asm"
#include "nine/macros.asm"
#include "nine/nes_labels.asm"
#include "nine/mem_labels.asm"

; PRG-ROM

#include "nine/prg_rom/prg_rom.asm"
#include "game/game_states.asm"
#include "game/music/music.asm"
#include "game/animations/animations.asm"
#include "nine/prg_rom/prg_rom_filler.asm"

; CHR-ROM
#include "game/chr_rom.asm"
