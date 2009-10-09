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
import cStringIO as StringIO

class E2VectorWriter:
    def __init__(self, max_num_notes):
        self.notes = []
        self.max_num_notes = max_num_notes
    
    def note(self, n):
        self.notes.append(n)
    
    def get(self):
        def sort(a, b):
            if a.start == b.start:
                return 0
            elif a.start < b.start:
                return -1
            else:
                return 1
        self.notes.sort(sort)
        buffer = StringIO.StringIO()
        index = 0
        for n in self.notes:
            if self.max_num_notes != 0 and index == self.max_num_notes:
                break
            buffer.write("S[%d,vector]=vec(%d,%d,%d)\r\n" % (index, n.note, n.start, n.end))
            index = index + 1
        return buffer.getvalue()

class NoteState:
    def __init__(self, channel, note, start):
        self.channel = channel
        self.note = note
        self.start = start
        self.end = None

class NoteStream(MidiOutStream):
    def __init__(self, channels, writer, force_tempo=120):
        MidiOutStream.__init__(self)
        self.notes = []
        self.channels = channels
        self.writer = writer
        self.force_tempo = force_tempo
    
    def header(self, format=0, nTracks=1, division=96):
        self.ppqn = division
    
    def note_on(self, channel=0, note=0x40, velocity=0x40):
        if channel in self.channels:
            self.notes.append(NoteState(channel, note, self.convert_time(self.abs_time())))
    
    def note_off(self, channel=0, note=0x40, velocity=0x40):
        if channel in self.channels:
            for n in self.notes:
                if n.channel == channel and n.note == note:
                    n.end = self.convert_time(self.abs_time())
                    self.notes.remove(n)
                    self.writer.note(n)
                    return
            raise Exception("Found orphan off-note on channel %d, note %d" % (channel, note))     
    
    def convert_time(self, time):
        return time / float(self.ppqn) * 60. / self.force_tempo * 1000 # TODO: Timing may be off
    
    #def tempo(self, value):
    #    print value
    #    self.current_tempo = value
    
    def device_name(self, data):
        pass
    
    def sysex_event(self, data):
        pass

def main():
    parser = OptionParser("%prog MIDIFILE")
    parser.add_option("-t", "--track", dest="track", action="append",
                      help="use this track, multiple tracks allowed", metavar="TRACK")
    parser.add_option("-l", "--limit", dest="limit",
                      help="maximum number of notes", metavar="NUM")
    parser.add_option("-b", "--tempo", dest="tempo",
                      help="override BPM", metavar="BPM")
    (options, args) = parser.parse_args()
    
    # Parse arguments
    if len(args) == 0:
        parser.error("Missing required argument: MIDIFILE")
    elif len(args) > 1:
        parser.error("Too many arguments")
    midi_file = args[0]

    # Get options
    tracks = map(int, options.track) if options.track != None else [0]
    note_limit = int(options.limit) if options.limit != None else 0
    bpm = int(options.tempo) if options.tempo != None else 120
    
    # Parse the MIDI file
    try:
        writer = E2VectorWriter(note_limit)
        event_handler = NoteStream(tracks, writer, force_tempo=bpm)
        midi_in = MidiInFile(event_handler, midi_file)
        midi_in.read()
    except IOError, e:
        print >>sys.stderr, "error: Failed to read MIDI file: %s" % e
        sys.exit(1)
    
    # Generate the E2 script in full
    try:
        f = open("e2base.txt", "rb")
        template = f.read()
        f.close()
        print template.replace("%DATA%", writer.get())
    except IOError, e:
        print >>sys.stderr, "error: Failed to read E2 template file: %s" % e
        sys.exit(2)

if __name__ == "__main__":
    main()