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
import os.path
from optparse import OptionParser
import midi
from midi.MidiOutStream import MidiOutStream
from midi.MidiInFile import MidiInFile
import cStringIO as StringIO
import struct

class NoteWriter:
    def __init__(self, max_num_notes, lower_freq, upper_freq):
        self.notes = []
        self.max_num_notes = max_num_notes
        self.lower_freq = lower_freq
        self.upper_freq = upper_freq
    
    def note(self, n):
        self.notes.append(n)
    
    def num_notes(self):
        return min(self.max_num_notes, len(self.notes)) if self.max_num_notes > 0 else len(self.notes)
    
    def write(self, buffer, func):
        def sort(a, b):
            if a.start == b.start:
                return 0
            elif a.start < b.start:
                return -1
            else:
                return 1
        self.notes.sort(sort)
        index = 0
        for n in self.notes:
            if self.max_num_notes != 0 and index > self.max_num_notes:
                break
            freq = (440 / 32) * (2^((n.note - 9) / 12))
            if freq > self.upper_freq or freq < self.lower_freq:
                print >>sys.stderr, "# Note dropped, freq=%.2f" % freq
                continue # Frequency capping
            func(buffer, index, n)
            index = index + 1

class E2VectorWriter(NoteWriter):
    def get(self):
        f = open(os.path.join(sys.path[0], "e2base.txt"), "rb")
        template = f.read()
        f.close()
        
        buffer = StringIO.StringIO()
        def w(buffer, index, n):
            buffer.write("S[%d,vector]=vec(%d,%d,%d)\r\n" % (index, n.note, n.start, n.end))
        self.write(buffer, w)
        return template.replace("%DATA%", buffer.getvalue())

class DataFileWriter(NoteWriter):
    def get(self):
        buffer = StringIO.StringIO()
        buffer.write("LFMIDI") # Magic byte
        buffer.write(struct.pack(">B", 4)) # Header of length 4
        buffer.write(struct.pack(">B", 1)) # Version
        a = int(self.num_notes()) / 255 + 1
        b = int(self.num_notes()) % 255 + 1
        buffer.write(struct.pack(">BB", a, b))
        buffer.write(struct.pack(">B", 1 + 3 + 3)) # Note struct length
        def w(buffer, index, n):
            buffer.write(struct.pack(">B", n.note + 1))
            a = int(n.start) / 255 / 255 + 1
            b = int(n.start) / 255 % 255 + 1
            c = int(n.start) % 255 + 1
            buffer.write(struct.pack(">BBB", a, b, c))
            a = int(n.end) / 255 / 255 + 1
            b = int(n.end) / 255 % 255 + 1
            c = int(n.end) % 255 + 1
            buffer.write(struct.pack(">BBB", a, b, c))
        self.write(buffer, w)
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
    parser = OptionParser("%prog [options] MIDIFILE")
    parser.add_option("-f", "--format", dest="format",
                      help="format", metavar="FMT")
    parser.add_option("-t", "--track", dest="track", action="append",
                      help="use this track, multiple tracks allowed", metavar="TRACK")
    parser.add_option("-l", "--limit", dest="limit",
                      help="maximum number of notes", metavar="NUM")
    parser.add_option("-b", "--tempo", dest="tempo",
                      help="override BPM", metavar="BPM")
    parser.add_option("--lower-freq", dest="lower_freq",
                      help="lower frequency", metavar="FREQ", default=0)
    parser.add_option("--upper-freq", dest="upper_freq",
                      help="upper frequency", metavar="FREQ", default=4972)
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
    if options.format == None or options.format.lower() == "e2":
        fmt_cls = E2VectorWriter
    elif options.format.lower() == "lfmidi":
        fmt_cls = DataFileWriter
    else:
        parser.error("Unknown format - accepted formats: e2, lfmidi")
    
    # Parse the MIDI file
    try:
        writer = fmt_cls(note_limit, int(options.lower_freq), int(options.upper_freq))
        event_handler = NoteStream(tracks, writer, force_tempo=bpm)
        midi_in = MidiInFile(event_handler, midi_file)
        midi_in.read()
    except IOError, e:
        print >>sys.stderr, "error: Failed to read MIDI file: %s" % e
        sys.exit(1)
    
    print writer.get()

if __name__ == "__main__":
    main()