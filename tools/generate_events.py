#!/usr/bin/env python
import json
import sys

events = []
with open(sys.argv[1], 'r') as event_file:
	events = json.load(event_file)

print('events_pos_lsb:')
for event in events:
	print('.byt ${:02x}'.format(event['pos'] & 0xff))
print('.byt $ff')

print('events_pos_msb:')
for event in events:
	print('.byt ${:02x}'.format(int(event['pos'] >> 8)))
print('.byt $ff')

print('events_handler_lsb:')
for event in events:
	print('.byt <event_handler_{}'.format(event['name']))

print('events_handler_msb:')
for event in events:
	print('.byt >event_handler_{}'.format(event['name']))
