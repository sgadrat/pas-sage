; Building the project
;  tools/generate_bg_data.py tilemap assets/dummy_bg.png > game/game_states/bg_data.asm
;  tools/generate_bg_data.py tiles assets/dummy_bg.png > game/chr_rom_bg.asm
;  tools/generate_bg_data.py palettes assets/dummy_bg.png > game/game_states/bg_palettes.asm
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
