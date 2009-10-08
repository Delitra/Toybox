#!/usr/bin/env python
#
# midi2e2
# Copyright (C) 2008-2009 sk89q <http://sk89q.therisenrealm.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id$

import sys
from optparse import OptionParser
import midi
from midi.MidiOutStream import MidiOutStream
from midi.MidiInFile import MidiInFile

# Create a table of notes, although we could just calculate on the fly
midi_freqs = []
for i in range(0, 127):
   midi_freqs.append((440 / 32.) * (2 ** ((i - 9) / 12.)));

class E2Writer(MidiOutStream):
    def __init__(self, channels=[0], max_notes=0):
        MidiOutStream.__init__(self)
        self.active = []
        for i in range(0, 16):
            self.active.append(None)
        self.max_notes = max_notes
        self.note_count = 0
        self.channels = {}
        for i in range(0, len(channels)):
            self.channels[channels[i]] = i
    
    def note_on(self, channel=0, note=0x40, velocity=0x40):
        if channel in self.channels:
            if self.active[channel] != None:
                #print "# 2nd_note = %d" % note
                pass
            else:
                #print "# 1st_note = %d" % note
                self.active[channel] = {
                    'note': note,
                    'time': self.rel_time(),
                }
    
    def note_off(self, channel=0, note=0x40, velocity=0x40):
        if self.max_notes > 0 and self.note_count > self.max_notes:
            raise PrematureEnd(self.abs_time())
        if channel in self.channels:
            chan_index = self.channels[channel]
            if not self.active[channel]:
                #print "# MISSING NOTE"
                pass
            else:
                self.note_count = self.note_count + 1
                current = self.active[channel]
                if current['note'] == note:
                    if current['time'] > 0: # Silence
                        print "SongCh%d:pushVector2(vec2(0, %d)) # Silence" % (chan_index, current['time']*2)
                    freq = midi_freqs[note]
                    print "SongCh%d:pushVector2(vec2(%.1f, %d))" % (chan_index, freq, self.rel_time()*2)
                    self.active[channel] = None
                else:
                    #print "# 2nd_note RES = %d" % note
                    pass
    
    def device_name(self, data):
        pass

parser = OptionParser("%prog MIDIFILE")
parser.add_option("-t", "--track", dest="track", action="append",
                  help="use this track", metavar="TRACK")
(options, args) = parser.parse_args()

if len(args) == 0:
    parser.error("Missing required argument: MIDIFILE")
elif len(args) > 1:
    parser.error("Too many arguments")

# Get tracks to read
if options.track != None:
    tracks = map(int, options.track)
else:
    tracks = [1]

event_handler = E2Writer(tracks)
in_file = args[0]
try:
    midi_in = MidiInFile(event_handler, in_file)
    print """@inputs On
@persist Index0 SongCh0:array

if (first()) {"""
    midi_in.read()
    print """}

if (On) {
    if (first() | ~On | clk("play0")) {
        # Channel 0
        Freq = SongCh0[Index0, vector2]:x()
        Length = SongCh0[Index0, vector2]:y()
        if (Freq > 0) {
            Pitch = Freq * 5 / 22
            soundPlay(0, Length / 1000, "synth/sine.wav")
            soundPitch(0, Pitch)
        } else {
            soundStop(0)
        }
        Index0++
        if (Index0 >= SongCh0:count()) { Index0 = 0 }
        timer("play0", Length)
    }
} else {
    soundStop(0)
    stoptimer("play0")
}"""
except IOError, e:
    print >>sys.stderr, "error: Failed to read MIDI file: %s" % e
    sys.exit(1)