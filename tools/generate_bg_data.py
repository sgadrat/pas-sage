#!/usr/bin/env python
import json
from PIL import Image
import sys

mode = sys.argv[1]

with open(sys.argv[2], 'r') as reserved_tiles_file:
	reserved_tiles = json.load(reserved_tiles_file)

img = Image.open(sys.argv[3])
#print(img.format, img.size, img.mode)
width = img.size[0]
height = img.size[1]

assert height == 80
assert width % 8 == 0

tiled_width = int(width / 8)
tiled_height = int(height / 8)

assert height % 16 == 0
assert width % 16 == 0

paletted_width = int(width / 16)
paletted_height = int(height / 16)

#for row in range(height):
#	for column in range(width):
#		sys.stdout.write(str(img.getpixel((column, row))))
#	print('')

initial = 0x00
layout = []
palettes = []
chr_tiles = reserved_tiles

for row in range(int(height / 8)):
	for column in range(int(width / 8)):
		if row % 2 == 0 and column % 2 == 0:
			palette_num = int(img.getpixel((column*8, row*8)) / 4)
			palettes.append(palette_num)

		tile = []
		for y in range(8):
			line_str = ''
			for x in range(8):
				line_str = '%s%d' % (line_str, img.getpixel((column*8+x, row*8+y)) % 4)
			tile.append(line_str)

		index = None
		if tile in chr_tiles:
			index = chr_tiles.index(tile)
		else:
			index = len(chr_tiles)
			chr_tiles.append(tile)

		layout.append(index)

# Print chr_data
if mode == 'tiles':
	for lines in chr_tiles:
		print('; TILE ${:02x}'.format(chr_tiles.index(lines) + initial))

		pixels = [int(x) for x in ''.join(lines)]
		sys.stdout.write('.byt ')
		for y in range(8):
			sys.stdout.write('%')
			for x in range(8):
				sys.stdout.write('0') if pixels[y*8+x] % 2 == 0 else sys.stdout.write('1')
			if y < 7:
				sys.stdout.write(', ')
		sys.stdout.write('\n')

		sys.stdout.write('.byt ')
		for y in range(8):
			sys.stdout.write('%')
			for x in range(8):
				sys.stdout.write('0') if pixels[y*8+x] < 2 else sys.stdout.write('1')
			if y < 7:
				sys.stdout.write(', ')
		sys.stdout.write('\n')

	print('')
	print('#if $2000-* < 0')
	print('#echo *** Error: VRAM bank2 data occupies too much space')
	print('#else')
	print('.dsb $2000-*, 0')
	print('#endif')

# Print game data layout
if mode == 'tilemap':
	print('bg_data:')
	for x in range(tiled_width):
		sys.stdout.write('.byt ')
		for y in range(tiled_height):
			sys.stdout.write('${:02x}, '.format(layout[x+y*tiled_width] + initial))
		sys.stdout.write('\n')

if mode == 'palettes':
	print('bg_palettes:')
	for x in range(paletted_width):
		sys.stdout.write('.byt ')
		upper_value = 0
		for y in range(paletted_height):
			current_value = palettes[x+y*paletted_width]
			if y % 2 == 0:
				concat_value = upper_value + current_value * 16
				sys.stdout.write('${:02x}, '.format(concat_value))
			upper_value = current_value
		sys.stdout.write('\n')
