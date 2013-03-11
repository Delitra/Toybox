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
Base module for midi2e2.
"""

__all__ = ('midi_filter')

def mk_filter(use_tracks=[], lower_freq=0, upper_freq=0, max_time=0):
    def f(n):
        if len(use_tracks) > 0:
            if n.track not in use_tracks: return None
        freq = (440 / 32) * (2 ** ((n.note - 9) / 12))
        if lower_freq != 0 and freq < lower_freq:
            return None
        if upper_freq != 0 and freq > upper_freq:
            return None
        if n.start < 0: return None
        if max_time != 0 and n.end > max_time: return None
        return n
    return f