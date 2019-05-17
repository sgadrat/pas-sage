#!/usr/bin/env python
from PIL import Image
import sys

mode = sys.argv[1]

img = Image.open(sys.argv[2])
#print(img.format, img.size, img.mode)
width = img.size[0]
height = img.size[1]

assert height == 80
assert width % 8 == 0

tiled_width = int(width / 8)
tiled_height = int(height / 8)

#for row in range(height):
#	for column in range(width):
#		sys.stdout.write(str(img.getpixel((column, row))))
#	print('')

initial = 0x00
layout = []
chr_tiles = [
	[
		'00000000',
		'00000000',
		'00000000',
		'00000000',
		'00000000',
		'00000000',
		'00000000',
		'00000000',
	],
	[
		'11111111',
		'11111111',
		'11111111',
		'11111111',
		'11111111',
		'11111111',
		'11111111',
		'11111111',
	],
	[
		'22222222',
		'22222222',
		'22222222',
		'22222222',
		'22222222',
		'22222222',
		'22222222',
		'22222222',
	],
	[
		'33333333',
		'33333333',
		'33333333',
		'33333333',
		'33333333',
		'33333333',
		'33333333',
		'33333333',
	],
]

tiles = []
for row in range(int(height / 8)):
	for column in range(int(width / 8)):
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
