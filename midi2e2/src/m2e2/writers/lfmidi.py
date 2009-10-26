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
This module writes LFMIDI files.
"""

__all__ = ('LFMIDIWriter')

import struct
from m2e2.writers import Writer

class LFMIDIWriter(Writer):
    def __init__(self, data, f):
        Writer.__init__(self, data, f)
        self.version = 1
    
    def write_byte(self, v):
        self.f.write(struct.pack(">B", v))
    
    def write_short(self, v):
        a = int(v) / 255 + 1
        b = int(v) % 255 + 1
        self.f.write(struct.pack(">BB", a, b))
    
    def write_tbyte(self, v):
        a = int(v) / 255 / 255 + 1
        b = int(v) / 255 % 255 + 1
        c = int(v) % 255 + 1
        self.f.write(struct.pack(">BBB", a, b, c))
    
    def write(self):
        self.f.write("LFMIDI") # Magic number
        
        # Header
        self.write_byte(4) # Header of length 4
        self.write_byte(self.version) # Version
        self.write_short(len(self.data.notes)) # Number of notes
        self.write_byte(1 + 3 + 3) # Note struct size
        
        # We need to sort the notes first
        notes = list(self.data.notes)
        def sort(a, b):
            if a.start == b.start: return 0
            elif a.start < b.start: return -1
            else: return 1
        notes.sort(sort)
        
        # Notes
        for n in notes:
            self.write_byte(n.note + 1)
            self.write_tbyte(n.start)
            self.write_tbyte(n.end)
