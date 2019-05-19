#!/usr/bin/env python
import json
import os
from PIL import Image
from stblib.animations import Animation, Frame, Sprite
import sys

mode = sys.argv[1]

animations_index = []
with open(sys.argv[2], 'r') as index_file:
	animations_index = json.load(index_file)

asset_path = os.path.abspath(os.path.dirname(sys.argv[2]))

fully_transparent_tile = [
	'00000000',
	'00000000',
	'00000000',
	'00000000',
	'00000000',
	'00000000',
	'00000000',
	'00000000',
]

initial = 0x00
anims = []
chr_tiles = [
	fully_transparent_tile,
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

for anim_index in animations_index:
	anim = Animation(name=anim_index['name'])
	anchor = anim_index['anchor']
	palette = anim_index['palette']

	for frame_index in anim_index['frames']:
		frame = Frame(duration=frame_index['duration'])

		img = Image.open('{}/{}'.format(asset_path, frame_index['file']))
		#print(img.format, img.size, img.mode)
		width = img.size[0]
		height = img.size[1]

		assert height % 8 == 0
		assert width % 8 == 0

		tiled_width = int(width / 8)
		tiled_height = int(height / 8)

		for row in range(tiled_height):
			for column in range(tiled_width):
				tile = []
				for y in range(8):
					line_str = ''
					for x in range(8):
						line_str = '%s%d' % (line_str, img.getpixel((column*8+x, row*8+y)) % 4)
					tile.append(line_str)

				if tile != fully_transparent_tile:
					index = None
					if tile in chr_tiles:
						index = chr_tiles.index(tile)
					else:
						index = len(chr_tiles)
						chr_tiles.append(tile)

					frame.sprites.append(Sprite(y=row*8-anchor['y'], tile='${:02x}'.format(index), attr=palette, x=column*8-anchor['x'], foreground=False))

		anim.frames.append(frame)

	anims.append(anim)

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
	print('#if $1000-* < 0')
	print('#echo *** Error: VRAM bank2 data occupies too much space')
	print('#else')
	print('.dsb $1000-*, 0')
	print('#endif')

if mode == 'anims':
	for anim in anims:
		print(anim.serialize())
