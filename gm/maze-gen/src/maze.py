#!/usr/bin/env python
#
# GModMazeGen
# Copyright (C) 2008-2009 sk89q <http://sk89q.therisenrealm.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# $Id$

import sys
from optparse import OptionParser
import random
import cStringIO as StringIO
import advdupe
from advdupe.types import LuaTable, Vector, Angle, Player

BELOW = 0
RIGHT = 1
ABOVE = 2
LEFT = 3

class DFSMaze:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.visited = {}
        self.open_walls = {}
        self.open(0, 0, LEFT)
        self.search(0, 0)
    
    def open(self, x, y, dir):
        if dir == BELOW or dir == RIGHT:
            self.open_walls["%d,%d,%d" % (x, y, dir)] = 1
        elif dir == ABOVE:
            self.open_walls["%d,%d,%d" % (x, y - 1, dir - 2)] = 1
        elif dir == LEFT:
            self.open_walls["%d,%d,%d" % (x - 1, y, dir - 2)] = 1
    
    def is_open(self, x, y, dir):
        if dir == BELOW or dir == RIGHT:
            return ("%d,%d,%d" % (x, y, dir)) in self.open_walls
        elif dir == ABOVE:
            return ("%d,%d,%d" % (x, y - 1, dir - 2)) in self.open_walls
        elif dir == LEFT:
            return ("%d,%d,%d" % (x - 1, y, dir - 2)) in self.open_walls

    def get_dir(self, x, y, from_x, from_y):
        if x < from_x:
            return RIGHT
        elif x > from_x:
            return LEFT
        elif y < from_y:
            return BELOW
        elif y > from_y:
            return ABOVE
    
    def search(self, x, y, from_x=None, from_y=None):
        if x < 0 or y < 0 or x >= self.width or y >= self.height: return
        id = "%d,%d" % (x, y)
        if id in self.visited: return
        self.visited[id] = 1
        if from_x != None:
            self.open(x, y, self.get_dir(x, y, from_x, from_y))
        neighbors = [(x, y - 1),
                     (x - 1, y),
                     (x + 1, y),
                     (x, y + 1)]
        random.shuffle(neighbors)
        for args in neighbors:
            self.search(*(args + (x, y)))

class AdvDupeMaze:
    def __init__(self, maze):
        self.maze = maze
        self.multiples = [1, 2, 4, 8, 12, 16]
        self.entities = {}
        self.ent_index = 1
        self.accounted_walls = {}
        #self.populate()
    
    def account(self, x, y, dir):
        if dir == BELOW or dir == RIGHT:
            self.accounted_walls["%d,%d,%d" % (x, y, dir)] = 1
        elif dir == ABOVE:
            self.accounted_walls["%d,%d,%d" % (x, y - 1, dir - 2)] = 1
        elif dir == LEFT:
            self.accounted_walls["%d,%d,%d" % (x - 1, y, dir - 2)] = 1
    
    def is_accounted(self, x, y, dir):
        if dir == BELOW or dir == RIGHT:
            return ("%d,%d,%d" % (x, y, dir)) in self.accounted_walls
        elif dir == ABOVE:
            return ("%d,%d,%d" % (x, y - 1, dir - 2)) in self.accounted_walls
        elif dir == LEFT:
            return ("%d,%d,%d" % (x - 1, y, dir - 2)) in self.accounted_walls
    
    def get_wall_combo(self, size):
        largest = 1
        for multiple in self.multiples:
            if size == multiple:
                return [multiple]
            elif multiple < size:
                if multiple > largest:
                    largest = multiple
        return [largest] + self.get_wall_combo(size - largest)
    
    def add_ent(self, ent):
        self.entities[self.ent_index] = ent
        self.ent_index = self.ent_index + 1

    def add_wall(self, x, y, multiple, horiz):
        self.add_ent({'Angle': Angle(90.0, 90.0004, 180.0),
                      'Class': 'prop_physics',
                      'LocalAngle': Angle(90.0, 90 if horiz else 0, 180.0),
                      'LocalPos': Vector(x * 95, y * 95, 95 / 2),
                      'Model': 'models/hunter/plates/plate2x%d.mdl' % (multiple * 2),
                      'PhysicsObjects': {0: {'Angle': Angle(90.0, 90.0004, 180.0),
                                             'Frozen': True,
                                             'LocalAngle': Angle(90.0, 90 if horiz else 0, 180.0),
                                             'LocalPos': Vector(x * 95, y * 95, 95 / 2),
                                             'Pos': Vector(x * 95, y * 95, 95 / 2)}},
                      'Pos': Vector(x * 95, y * 95, 95 / 2),
                      'Skin': 0})

    def add_walls(self, x, y, dir):
        start_x = x
        start_y = y
        end_x = x
        end_y = y
        if self.is_accounted(start_x, start_y, dir):
            return
        if self.maze.is_open(start_x, start_y, dir):
            return
        if dir == ABOVE or dir == BELOW:
            for i in range(1, start_x + 1):
                if not self.maze.is_open(start_x - 1, y, dir) and \
                    not self.is_accounted(start_x - 1, y, dir):
                    start_x = start_x - 1
                    self.account(start_x, start_y, dir)
            for i in range(1, self.maze.width - end_x):
                if not self.maze.is_open(end_x + 1, y, dir) and \
                    not self.is_accounted(end_x + 1, y, dir):
                    end_x = end_x + 1
                    self.account(end_x, end_y, dir)
            combos = self.get_wall_combo(end_x - start_x + 1)
            for multiple in combos:
                self.add_wall((multiple - 1) / 2.0 + start_x, start_y + (-0.5 if dir == ABOVE else 0.5), multiple, True)
                start_x = start_x + multiple
                if start_x > end_x:
                    break
        else:
            for i in range(1, start_y + 1):
                if not self.maze.is_open(x, start_y - 1, dir) and \
                    not self.is_accounted(x, start_y - 1, dir):
                    start_y = start_y - 1
                    self.account(start_x, start_y, dir)
            for i in range(1, self.maze.height - end_y):
                if not self.maze.is_open(x, end_y + 1, dir) and \
                    not self.is_accounted(x, end_y + 1, dir):
                    end_y = end_y + 1
                    self.account(end_x, end_y, dir)
            combos = self.get_wall_combo(end_y - start_y + 1)
            for multiple in combos:
                self.add_wall(start_x + (-0.5 if dir == LEFT else 0.5), start_y + (multiple - 1) / 2.0, multiple, False)
                start_y = start_y + multiple
                if start_y > end_y:
                    break
    
    def populate(self):
        for y in range(0, self.maze.height):
            for x in range(0, self.maze.width):
                self.add_walls(x, y, ABOVE)
                self.add_walls(x, y, LEFT)
                # Bottom-most cell
                if y == self.maze.height - 1:
                    self.add_walls(x, y, BELOW)
                # Right-most cell
                if x == self.maze.width - 1:
                    self.add_walls(x, y, RIGHT)

def ascii_maze(maze):
    out = StringIO.StringIO()
    for y in range(0, maze.height):
        for x in range(0, maze.width):
            out.write("+%s" % (" " if maze.is_open(x, y, ABOVE) else "-"))
        out.write("+")
        out.write("\n")
        for x in range(0, maze.width):
            out.write("%s " % (" " if maze.is_open(x, y, LEFT) else "|"))
        out.write("|")
        out.write("\n")
    for x in range(0, maze.width):
        out.write("+-")
    out.write("+")
    return out.getvalue()

def main():
    print >>sys.stderr, "GModMazeGen"
    print >>sys.stderr, "Copyright (C) 2009 sk89q <http://sk89q.therisenrealm.com>"
    print >>sys.stderr, ""
    
    parser = OptionParser("%prog WIDTH HEIGHT [ADVDUPEFILE]")
    (options, args) = parser.parse_args()
    
    # Parse arguments
    if len(args) == 0: parser.error("Missing required arguments: WIDTH, HEIGHT")
    elif len(args) == 1: parser.error("Missing required argument: HEIGHT")
    elif len(args) == 2: args.append("-")
    elif len(args) > 3: parser.error("Too many arguments")
    width, height, output_file = args
    
    try: width = int(width)
    except ValueError: parser.error("Specified width is not numeric")
    if width < 1: parser.error("Specified width is not small")
    try: height = int(height)
    except ValueError: parser.error("Specified height is not numeric")
    if height < 1: parser.error("Specified height is not small")

    maze = DFSMaze(width, height)
    gmod_maze = AdvDupeMaze(maze)
    gmod_maze.populate()
    
    print >>sys.stderr, "Generated maze:"
    print >>sys.stderr, ascii_maze(maze)
    print >>sys.stderr, "Number of props used: %d" % (len(gmod_maze.entities))
    
    try:
        doc = advdupe.AdvDupeDocument()
        doc.entities = gmod_maze.entities
        if output_file == "-":
            print doc.dumps()
        else:
            doc.dump(output_file)
    except IOError, e:
        print >>sys.stderr, "error: Failed to write adv. dupe file: %s" % e
        sys.exit(3)
 
if __name__ == "__main__":
    main()
