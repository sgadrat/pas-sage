#!/bin/bash

set -e

tools/generate_bg_data.py tilemap assets/dummy_bg.png > game/game_states/bg_data.asm
tools/generate_bg_data.py tiles assets/dummy_bg.png > game/chr_rom_bg.asm
tools/generate_bg_data.py palettes assets/dummy_bg.png > game/game_states/bg_palettes.asm
#xa nine.asm -C -o game\(E\).nes
~/workspace/xa-listing/xa/xa nine.asm -C -o game\(E\).nes -P - | python2 ~/workspace/xa-listing/listing2nl.py > game\(E\).nes.0.nl
