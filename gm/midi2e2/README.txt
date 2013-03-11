midi2e2
Copyright (c) 2009 sk89q <http://sk89q.therisenrealm.com>
Licensed under the GNU Lesser General Public License v3

Introduction
------------

This Python script converts MIDI files to Expression 2 scripts.
Currently it only supports single track monophonic MIDI files, though
it will read any general MIDI file.

It may need to be calibrated a bit.

Requirements
------------

- Python >= 2.5
- MIDI module:
  <http://www.mxm.dk/products/public/pythonmidi>

Usage
-----

./midi2e2.py --track 2 midifile.mid