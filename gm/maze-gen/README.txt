GModMazeGen
Copyright (c) 2009 sk89q <http://sk89q.therisenrealm.com>
Licensed under the GNU Lesser General Public License v3

Introduction
------------

This Python script generates mazes as Adv. Dupe files.

Known Issues
------------

- The maze algorithm implemented doesn't create very complicated mazes.

Requirements
------------

- Python >= 2.5
- pyAdvDupe module:
  <http://github.com/sk89q/pyadvdupe>

Usage
-----

./maze.py WIDTH HEIGHT [ADVDUPEFILE]

ADVDUPEFILE can also be "-" (without marks) to explicitly specify
STDOUT.