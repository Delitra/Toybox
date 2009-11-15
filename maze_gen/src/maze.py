#!/usr/bin/env python
#
# Gmod Maze Generator
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

import random
import sys
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

width = 15
height = 15

maze = DFSMaze(width, height)
print ""
for y in range(0, height):
    for x in range(0, width):
        sys.stdout.write("+%s" % (" " if maze.is_open(x, y, ABOVE) else "-"))
    sys.stdout.write("+")
    sys.stdout.write("\n")
    for x in range(0, width):
        sys.stdout.write("%s " % (" " if maze.is_open(x, y, LEFT) else "|"))
    sys.stdout.write("|")
    sys.stdout.write("\n")
for x in range(0, width):
    sys.stdout.write("+-")

entities = {}
wall_index = 1

def gen_wall(x, y, horiz):
    return \
    {'Angle': Angle(90.0, 90.0004, 180.0),
          'Class': 'prop_physics',
          'LocalAngle': Angle(90.0, 90 if horiz else 0, 180.0),
          'LocalPos': Vector(x * 95, y * 95, 95 / 2),
          'Model': 'models/hunter/plates/plate2x2.mdl',
          'PhysicsObjects': {0: {'Angle': Angle(90.0, 90.0004, 180.0),
                                 'Frozen': True,
                                 'LocalAngle': Angle(90.0, 90 if horiz else 0, 180.0),
                                 'LocalPos': Vector(x * 95, y * 95, 95 / 2),
                                 'Pos': Vector(x * 95, y * 95, 95 / 2)}},
          'Pos': Vector(x * 95, y * 95, 95 / 2),
          'Skin': 0}

for y in range(0, height):
    for x in range(0, width):
        if not maze.is_open(x, y, ABOVE):
            entities[wall_index] = gen_wall(x, y - 0.5, True)
            wall_index = wall_index + 1
        if not maze.is_open(x, y, LEFT):
            entities[wall_index] = gen_wall(x - 0.5, y, False)
            wall_index = wall_index + 1
        if y == height - 1:
            if not maze.is_open(x, y, BELOW):
                entities[wall_index] = gen_wall(x, y + 0.5, True)
                wall_index = wall_index + 1
        if x == width - 1:
            if not maze.is_open(x, y, RIGHT):
                entities[wall_index] = gen_wall(x + 0.5, y, False)
                wall_index = wall_index + 1

doc = advdupe.AdvDupeDocument()
doc.entities = entities
doc.dump("maze.txt")
