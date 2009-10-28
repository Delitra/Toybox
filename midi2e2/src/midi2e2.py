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
import cStringIO as StringIO
import re
from m2e2 import mk_filter
from m2e2.reader import read
from m2e2.writers.lfmidi import LFMIDIWriter
from m2e2.writers.e2 import E2Writer

# Hex dump from http://code.activestate.com/recipes/142812/
FILTER=''.join([(len(repr(chr(x)))==3) and chr(x) or '.' for x in range(256)])
def hexdump(src, length=16):
    result=[]
    for i in xrange(0, len(src), length):
       s = src[i:i+length]
       hexa = ' '.join(["%02X"%ord(x) for x in s])
       printable = s.translate(FILTER)
       result.append("%04X   %-*s   %s\n" % (i, length*3, hexa, printable))
    return ''.join(result)

def main():
    print >>sys.stderr, "midi2e2"
    print >>sys.stderr, "Copyright (C) 2008-2009 sk89q <http://sk89q.therisenrealm.com>"
    print >>sys.stderr, ""
    
    parser = OptionParser("%prog [options] MIDIFILE")
    parser.add_option("--hex-dump", dest="hex_dump", help="output a hex dump", action="store_true")
    parser.add_option("-f", "--format", dest="format", help="format", metavar="FMT")
    parser.add_option("-t", "--tracks", dest="tracks", help="use these tracks, starting from 1, delimited by commas or spaces", metavar="TRACKS")
    parser.add_option("-b", "--tempo", dest="tempo", help="override BPM", metavar="BPM")
    parser.add_option("--lower-freq", dest="lower_freq", help="lower frequency", metavar="FREQ", default=0)
    parser.add_option("--upper-freq", dest="upper_freq", help="upper frequency", metavar="FREQ", default=4972)
    parser.add_option("--max-length", dest="max_length", help="maximum time for song in ms", metavar="TIME", default=0)
    (options, args) = parser.parse_args()
    
    # Parse arguments
    if len(args) == 0: parser.error("Missing required argument: MIDIFILE")
    elif len(args) > 1: parser.error("Too many arguments")
    midi_file = args[0]

    # Get tracks
    tracks = []
    if options.tracks != None:
        tracks_input = re.split("\s+|,", options.tracks)
        for tr in tracks_input:
            try:
                tr = int(tr)
                if tr < 1: parser.error("The first track is number 1")
                if tr > 16: parser.error("The last track is number 16")
                if (tr - 1) not in tracks: tracks.append(tr - 1)
            except ValueError:
                parser.error("A non-numeric track was inputted")
    
    # Get other arguments
    try:
        max_length = int(options.max_length) if options.max_length != None else 0
        bpm = int(options.tempo) if options.tempo != None else 120
        lower_freq = int(options.lower_freq) if options.lower_freq != None else 0
        upper_freq = int(options.upper_freq) if options.upper_freq != None else 0
        if options.format == None or options.format.lower() == "e2":
            fmt_cls = E2Writer
        elif options.format.lower() == "lfmidi":
            fmt_cls = LFMIDIWriter
        else:
            parser.error("Unknown format -- accepted formats: e2, lfmidi")
    except ValueError:
        parser.error("A non-numeric argument was given to a numeric argument")
    
    # Parse the MIDI file
    try:
        f = mk_filter(use_tracks=tracks, lower_freq=lower_freq,
                      upper_freq=upper_freq, max_time=max_length)
        data = read(midi_file, force_tempo=bpm, f=f)
        
        if len(data.notes) == 0:
            print >>sys.stderr, "error: MIDI file contained no notes or filter generated no notes"
            sys.exit(10)

        buffer = StringIO.StringIO()
        writer = fmt_cls(data, buffer)
        writer.write()
        
        if options.hex_dump:
            print(hexdump(buffer.getvalue()))
        else:
            print(buffer.getvalue())
    except IOError, e:
        print >>sys.stderr, "error: Failed to read MIDI file: %s" % e
        sys.exit(3)

if __name__ == "__main__":
    main()