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
This module writes WireMIDI files.
"""

__all__ = ('PMPLTRACKWriter')

import struct
import cStringIO as StringIO
from m2e2.writers import Writer

class PMPLTRACKWriter(Writer):
    def __init__(self, data, f, title, author):
        Writer.__init__(self, data, f)
        self.title = title
        self.author = author
    
    def sort_time(self, notes):
        def sort(a, b):
            if a.start == b.start: return 0
            elif a.start < b.start: return -1
            else: return 1
        notes.sort(sort)
        
    def write_byte(self, v):
        self.f.write(struct.pack(">B", v))
    
    def write_cstring(self, v):
        self.f.write(v + "\x00")
    
    def write(self):
        track_notes = self.data.by_track()
        
        self.f.write("PMPLTRACK") # Magic number
        
        # Header
        self.write_cstring(self.title)
        self.write_cstring(self.author)
        self.write_byte(len(track_notes))
        self.write_byte(self.data.tempo)
        
        # Channels
        for tr in track_notes:
            self.sort_time(track_notes[tr])
            self.write_cstring("Track %d".format(tr))
            self.write_byte(1) # Track master volume
            self.write_byte(0) # Track master pitch, no spec yet
            self.write_byte(len(chn)) # Number of notes in track
            self.write_cstring("synth/sine.wav")
            
            for n in track_notes[tr]:
                self.write_byte(n.note)
