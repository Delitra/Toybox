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

"""
This module contains classes to parse MIDI files and return it in a
simplified format.
"""

__all__ = ('ReaderException',
           'MIDIData',
           'Note',
           'read')

import midi
from midi.MidiOutStream import MidiOutStream
from midi.MidiInFile import MidiInFile

class ReaderException(Exception): pass

class MIDIData:
    def __init__(self):
        self.ppqn = 96
        self.tempo = 120
        self.notes = []
    
    def by_track(self):
        tracks = {}
        for n in self.notes:
            if n.track not in tracks:
                tracks[n.track] = []
            self.tracks[n.track].append(n)
        return tracks
    
    def tracks(self):
        tracks = []
        for n in self.notes:
            if n.track not in tracks:
                tracks.append(n.track)
        return tracks

class Note:
    def __init__(self, track, note, start, start_clk, velocity):
        self.track = track
        self.note = note
        self.start = start
        self.start_clk = start_clk
        self.end = None
        self.end_clk = None
        self.velocity = None

class MIDIStream(MidiOutStream):
    def __init__(self, force_tempo=120, filter_func=None):
        MidiOutStream.__init__(self)
        
        self.output = MIDIData()
        self.on_notes = []
        self.force_tempo = force_tempo
        self.filter_func = filter_func
        self.output.tempo = force_tempo
    
    def header(self, format=0, nTracks=1, division=96):
        self.ppqn = division # This is required to calculate times
        self.output.ppqn = division
    
    def note_on(self, track=0, note=0x40, velocity=0x40):
        n = Note(track, note, self.convert_time(self.abs_time()), self.abs_time(), velocity)
        self.on_notes.append(n)
    
    def note_off(self, track=0, note=0x40, velocity=0x40):
        for n in self.on_notes:
            if n.track == track and n.note == note:
                n.end = self.convert_time(self.abs_time())
                n.end_clk = self.abs_time()
                self.on_notes.remove(n)
                if not self.filter_func:
                    self.output.notes.append(n)
                else:
                    n = self.filter_func(n)
                    if n: self.output.notes.append(n)
                return
        raise ReaderException("Found orphan off-note on track %d, note %d" % (track, note))     
    
    def convert_time(self, time):
        return time / float(self.ppqn) * 60.0 / self.force_tempo * 1000 # TODO: Timing may be off
    
    #def tempo(self, value):
    #    print value
    #    self.current_tempo = value
    
    def device_name(self, data):
        pass
    
    def sysex_event(self, data):
        pass

def read(midi_file, force_tempo=120, f=None):
    event_handler = MIDIStream(force_tempo=force_tempo, filter_func=f)
    midi_in = MidiInFile(event_handler, midi_file)
    midi_in.read()
    return event_handler.output